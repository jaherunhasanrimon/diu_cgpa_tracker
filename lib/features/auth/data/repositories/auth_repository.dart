import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/hive_service.dart';
import '../models/user_model.dart';

// ── Exceptions ────────────────────────────────────────────────────────────────

/// Typed exception thrown by auth operations.
/// [code] is a machine-readable string; [message] is human-readable.
///
/// When migrating to Firebase, map `FirebaseAuthException.code` → [AuthException.code]
/// inside `FirebaseAuthRepository` so the rest of the app stays unchanged.
class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException({required this.message, required this.code});

  @override
  String toString() => 'AuthException($code): $message';
}

// ── Abstract Interface ────────────────────────────────────────────────────────

/// Contract that every auth backend must fulfil.
///
/// **Swap guide:**
/// - Local (now)   → inject [LocalAuthRepository]
/// - Firebase (later) → inject `FirebaseAuthRepository implements IAuthRepository`
///
/// Only [authRepositoryProvider] in `auth_provider.dart` needs to change.
abstract interface class IAuthRepository {
  /// Returns the persisted user session, or `null` if not signed in.
  /// Synchronous because Hive reads are synchronous.
  /// Firebase implementation can read from a cached `FirebaseAuth.instance.currentUser`.
  UserModel? getCurrentUser();

  /// Creates a new account and returns the created [UserModel].
  /// Throws [AuthException] with code `'account-exists'` if one already exists.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String studentId = '',
  });

  /// Verifies credentials and returns the signed-in [UserModel].
  /// Throws [AuthException] with code `'wrong-credentials'` on failure.
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Signs in with Google credentials.
  Future<UserModel> signInWithGoogle();

  /// Sends a password reset link to the given [email].
  Future<void> sendPasswordResetEmail(String email);

  /// Ends the current session. For local auth this is a no-op (Hive data stays).
  /// For Firebase this calls `FirebaseAuth.instance.signOut()`.
  Future<void> signOut();

  /// Permanently deletes all auth data. Called on full app reset.
  Future<void> deleteAccount();

  /// Updates the current user's profile with registration details.
  Future<UserModel> updateProfile({
    required String studentId,
    required String department,
    required bool profileCompleted,
  });
}

// ── Local Implementation ──────────────────────────────────────────────────────

/// Hive-backed implementation of [IAuthRepository].
///
/// Data layout (all in the single `diu_cgpa_tracker` Hive box):
///   - `auth_v2_user`  → [UserModel.toMap()] (id, name, email)
///   - `auth_v2_hash`  → { email, hash } for password verification
///
/// On first access, migrates legacy `auth_user` records (from the previous
/// [AuthUserModel] schema) transparently.
class LocalAuthRepository implements IAuthRepository {
  static const _userKey = 'auth_v2_user';
  static const _hashKey = 'auth_v2_hash';

  // ── Password hashing ───────────────────────────────────────────────────────

  static String _hashPassword(String raw) =>
      sha256.convert(utf8.encode(raw)).toString();

  // ── IAuthRepository ────────────────────────────────────────────────────────

  @override
  UserModel? getCurrentUser() {
    // Check new schema first.
    final newData = HiveService.box.get(_userKey);
    if (newData != null) return UserModel.fromMap(newData as Map);

    // Migrate legacy auth_user record (AuthUserModel schema).
    final legacyData = HiveService.box.get('auth_user') as Map?;
    if (legacyData == null) return null;

    final user = UserModel.create(
      name: legacyData['name'] as String? ?? '',
      email: legacyData['email'] as String? ?? '',
    );
    HiveService.box.put(_userKey, user.toMap());
    HiveService.box.put(_hashKey, {
      'email': user.email,
      'hash': legacyData['passwordHash'] as String? ?? '',
    });
    return user;
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String studentId = '',
  }) async {
    if (HiveService.box.containsKey(_userKey) ||
        HiveService.box.containsKey('auth_user')) {
      throw const AuthException(
        message: 'An account already exists on this device.',
        code: 'account-exists',
      );
    }

    final user = UserModel(
      uid: const Uuid().v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      studentId: studentId.trim(),
      department: '',
      profileCompleted: false,
      createdAt: DateTime.now(),
    );
    await HiveService.box.put(_userKey, user.toMap());
    await HiveService.box.put(_hashKey, {
      'email': user.email,
      'hash': _hashPassword(password),
    });
    return user;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    throw const AuthException(
      message: 'Google login is not supported in local mock authentication.',
      code: 'unsupported-operation',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // No-op for local mock
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    // Support both old and new hash storage.
    final hashData = (HiveService.box.get(_hashKey) ??
        _legacyHashData()) as Map?;

    if (hashData == null) {
      throw const AuthException(
        message: 'No account found on this device.',
        code: 'no-account',
      );
    }

    final storedEmail = hashData['email'] as String? ?? '';
    final storedHash = hashData['hash'] as String? ?? '';

    if (storedEmail != email.trim().toLowerCase() ||
        storedHash != _hashPassword(password)) {
      throw const AuthException(
        message: 'Incorrect email or password.',
        code: 'wrong-credentials',
      );
    }

    final user = getCurrentUser();
    if (user == null) {
      throw const AuthException(
        message: 'Account data is corrupted. Please reset the app.',
        code: 'corrupted',
      );
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    // Local auth: session lives only in AuthNotifier state.
    // No Hive key to delete on sign-out (user data persists for next sign-in).
  }

  @override
  Future<void> deleteAccount() async {
    await HiveService.box.delete(_userKey);
    await HiveService.box.delete(_hashKey);
    // Also clean up legacy key if present.
    await HiveService.box.delete('auth_user');
  }

  @override
  Future<UserModel> updateProfile({
    required String studentId,
    required String department,
    required bool profileCompleted,
  }) async {
    final user = getCurrentUser();
    if (user == null) {
      throw const AuthException(
        message: 'No user is currently signed in.',
        code: 'no-user',
      );
    }
    final updatedUser = user.copyWith(
      studentId: studentId,
      department: department,
      profileCompleted: profileCompleted,
    );
    await HiveService.box.put(_userKey, updatedUser.toMap());
    return updatedUser;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Reads password hash from the old [AuthUserModel] storage for migration.
  Map? _legacyHashData() {
    final legacy = HiveService.box.get('auth_user') as Map?;
    if (legacy == null) return null;
    return {
      'email': legacy['email'] as String? ?? '',
      'hash': legacy['passwordHash'] as String? ?? '',
    };
  }
}

// ── Firebase Implementation ───────────────────────────────────────────────────

/// Firebase Auth backed implementation of [IAuthRepository].
///
/// Data layout:
///   - Firebase Auth keeps care of core user authentication (UID, display name, email).
///   - Custom student fields ([studentId], [department], [profileCompleted]) are cached
///     locally in the single `diu_cgpa_tracker` Hive box keyed by `auth_v2_user` for instant access.
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _userKey = 'auth_v2_user';

  @override
  UserModel? getCurrentUser() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final cachedData = HiveService.box.get(_userKey);
    if (cachedData != null) {
      final user = UserModel.fromMap(cachedData as Map);
      if (user.uid == firebaseUser.uid) {
        return user;
      }
    }

    return UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      studentId: '',
      department: '',
      profileCompleted: false,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String studentId = '',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(name.trim());

      final user = UserModel(
        uid: firebaseUser.uid,
        name: name.trim(),
        email: firebaseUser.email ?? email.trim().toLowerCase(),
        studentId: studentId.trim(),
        department: '',
        profileCompleted: false,
        createdAt: DateTime.now(),
      );

      await HiveService.box.put(_userKey, user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Registration failed.',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(
        message: 'An unexpected registration error occurred: ${e.toString()}',
        code: 'unknown',
      );
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final firebaseUser = credential.user!;

      final cachedData = HiveService.box.get(_userKey);
      if (cachedData != null) {
        final user = UserModel.fromMap(cachedData as Map);
        if (user.uid == firebaseUser.uid) {
          return user;
        }
      }

      final user = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        studentId: '',
        department: '',
        profileCompleted: false,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
      await HiveService.box.put(_userKey, user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Invalid email or password.',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(
        message: 'An unexpected login error occurred: ${e.toString()}',
        code: 'unknown',
      );
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleAccount = await googleSignIn.signIn();

      if (googleAccount == null) {
        throw const AuthException(
          message: 'Google Sign-In was cancelled by the user.',
          code: 'sign-in-cancelled',
        );
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final cachedData = HiveService.box.get(_userKey);
      if (cachedData != null) {
        final user = UserModel.fromMap(cachedData as Map);
        if (user.uid == firebaseUser.uid) {
          return user;
        }
      }

      final user = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        studentId: '',
        department: '',
        profileCompleted: false,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
      await HiveService.box.put(_userKey, user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Google Sign-In failed.',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(
        message: 'An unexpected Google Sign-In error occurred: ${e.toString()}',
        code: 'unknown',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Password reset request failed.',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(
        message: 'An unexpected error occurred: ${e.toString()}',
        code: 'unknown',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteAccount() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        await firebaseUser.delete();
      } on FirebaseAuthException catch (e) {
        throw AuthException(
          message: e.message ?? 'Account deletion failed.',
          code: e.code,
        );
      }
    }
    await HiveService.box.delete(_userKey);
  }

  @override
  Future<UserModel> updateProfile({
    required String studentId,
    required String department,
    required bool profileCompleted,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const AuthException(
        message: 'No authenticated user found to update.',
        code: 'no-user',
      );
    }

    final user = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      studentId: studentId.trim(),
      department: department.trim(),
      profileCompleted: profileCompleted,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );

    await HiveService.box.put(_userKey, user.toMap());
    return user;
  }
}
