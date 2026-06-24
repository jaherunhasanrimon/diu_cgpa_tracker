import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/storage/hive_service.dart';
import '../data/models/auth_user_model.dart';

/// Repository for local user authentication.
/// All data lives in the single Hive box under key [_key].
class AuthRepository {
  static const _key = 'auth_user';

  // ── Hashing ──────────────────────────────────────────────────────────────

  /// Returns the SHA-256 hex digest of [raw].
  static String hashPassword(String raw) {
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Saves [user] to Hive, replacing any existing record.
  Future<void> save(AuthUserModel user) async {
    await HiveService.box.put(_key, user.toMap());
  }

  /// Returns the saved user, or `null` if no account exists.
  AuthUserModel? get() {
    final data = HiveService.box.get(_key);
    if (data == null) return null;
    return AuthUserModel.fromMap(data as Map);
  }

  /// Returns `true` if an account has been created.
  bool exists() => HiveService.box.containsKey(_key);

  /// Deletes the stored user record (used on full app reset).
  Future<void> clear() async {
    await HiveService.box.delete(_key);
  }

  // ── Verification ─────────────────────────────────────────────────────────

  /// Returns `true` if [email] and [rawPassword] match the stored credentials.
  bool verifyPassword(String email, String rawPassword) {
    final user = get();
    if (user == null) return false;
    return user.email.toLowerCase() == email.toLowerCase() &&
        user.passwordHash == hashPassword(rawPassword);
  }
}
