import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:diu_cgpa_tracker/core/storage/hive_service.dart';
import 'package:diu_cgpa_tracker/features/auth/data/models/user_model.dart';
import 'package:diu_cgpa_tracker/features/auth/data/repositories/auth_repository.dart';
import 'package:diu_cgpa_tracker/features/auth/providers/registration_provider.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    HiveService.box = await Hive.openBox('diu_cgpa_tracker');
  });

  group('UserModel Tests', () {
    test('UserModel.create initializes fields correctly', () {
      final user = UserModel.create(
        name: 'John Doe',
        email: 'john@example.com',
      );

      expect(user.uid, isNotEmpty);
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.studentId, isEmpty);
      expect(user.department, isEmpty);
      expect(user.profileCompleted, isFalse);
      expect(user.createdAt, isNotNull);
    });

    test('UserModel serialization (toMap and fromMap) works correctly', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'user-123',
        name: 'John Doe',
        email: 'john@example.com',
        studentId: '201-15-12345',
        department: 'Computer Science & Engineering',
        profileCompleted: true,
        createdAt: now,
      );

      final map = user.toMap();
      final deserialized = UserModel.fromMap(map);

      expect(deserialized.uid, 'user-123');
      expect(deserialized.name, 'John Doe');
      expect(deserialized.email, 'john@example.com');
      expect(deserialized.studentId, '201-15-12345');
      expect(deserialized.department, 'Computer Science & Engineering');
      expect(deserialized.profileCompleted, isTrue);
      expect(deserialized.createdAt.year, now.year);
      expect(deserialized.createdAt.month, now.month);
      expect(deserialized.createdAt.day, now.day);
    });

    test('UserModel fromMap supports legacy "id" fallback', () {
      final legacyMap = {
        'id': 'legacy-uid-456',
        'name': 'Legacy Student',
        'email': 'legacy@example.com',
      };

      final deserialized = UserModel.fromMap(legacyMap);

      expect(deserialized.uid, 'legacy-uid-456');
      expect(deserialized.name, 'Legacy Student');
      expect(deserialized.email, 'legacy@example.com');
      expect(deserialized.studentId, isEmpty);
      expect(deserialized.department, isEmpty);
      expect(deserialized.profileCompleted, isFalse);
    });

    test('UserModel copyWith creates correct modified instance', () {
      final user = UserModel.create(
        name: 'Jane Doe',
        email: 'jane@example.com',
      );

      final updated = user.copyWith(
        studentId: '201-15-54321',
        department: 'CSE',
        profileCompleted: true,
      );

      expect(updated.uid, user.uid);
      expect(updated.name, user.name);
      expect(updated.email, user.email);
      expect(updated.studentId, '201-15-54321');
      expect(updated.department, 'CSE');
      expect(updated.profileCompleted, isTrue);
    });
  });

  group('LocalAuthRepository Tests', () {
    test('LocalAuthRepository supports studentId on signUp', () async {
      final repo = LocalAuthRepository();
      
      // Clear data to make test isolated
      await repo.deleteAccount();

      final user = await repo.signUp(
        name: 'Test Student',
        email: 'test@student.diu.edu.bd',
        password: 'password123',
        studentId: '201-15-99999',
      );

      expect(user.name, 'Test Student');
      expect(user.email, 'test@student.diu.edu.bd');
      expect(user.studentId, '201-15-99999');
      expect(user.profileCompleted, isFalse);
      
      // Cleanup
      await repo.deleteAccount();
    });
  });

  group('RegistrationState & Notifier Tests', () {
    test('RegistrationState copyWith updates studentId correctly', () {
      final state = RegistrationState();
      final updated = state.copyWith(studentId: '201-15-99999');
      expect(updated.studentId, '201-15-99999');
    });

    test('RegistrationNotifier setStudentId updates state correctly', () {
      final notifier = RegistrationNotifier();
      notifier.setStudentId('201-15-88888');
      expect(notifier.state.studentId, '201-15-88888');
    });
  });
}
