import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs_app/models/user_model.dart';

void main() {
  group('UserModel', () {
    group('fromMap', () {
      test('creates UserModel with all fields from map', () {
        final map = {
          'email': 'test@example.com',
          'displayName': 'Test User',
          'photoUrl': 'https://example.com/photo.jpg',
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30)),
          'dateOfBirth': Timestamp.fromDate(DateTime(1990, 5, 20)),
          'gender': 'male',
          'phone': '+40712345678',
          'preferredLanguage': 'ro',
          'userType': 'patient',
          'profileCompleted': true,
        };

        final user = UserModel.fromMap(map, 'user123');

        expect(user.uid, 'user123');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
        expect(user.photoUrl, 'https://example.com/photo.jpg');
        expect(user.dateOfBirth?.year, 1990);
        expect(user.dateOfBirth?.month, 5);
        expect(user.dateOfBirth?.day, 20);
        expect(user.gender, 'male');
        expect(user.phone, '+40712345678');
        expect(user.preferredLanguage, 'ro');
        expect(user.userType, 'patient');
        expect(user.profileCompleted, true);
      });

      test('uses default values for missing fields', () {
        final map = <String, dynamic>{};

        final user = UserModel.fromMap(map, 'user123');

        expect(user.uid, 'user123');
        expect(user.email, '');
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
        expect(user.dateOfBirth, isNull);
        expect(user.gender, isNull);
        expect(user.phone, isNull);
        expect(user.preferredLanguage, 'en');
        expect(user.userType, 'patient');
        expect(user.profileCompleted, false);
      });

      test('parses DateTime from ISO string', () {
        final map = {
          'createdAt': '2024-03-15T14:30:00.000Z',
          'dateOfBirth': '1985-12-25T00:00:00.000Z',
        };

        final user = UserModel.fromMap(map, 'user123');

        expect(user.createdAt.year, 2024);
        expect(user.createdAt.month, 3);
        expect(user.createdAt.day, 15);
        expect(user.dateOfBirth?.year, 1985);
        expect(user.dateOfBirth?.month, 12);
        expect(user.dateOfBirth?.day, 25);
      });
    });

    group('toMap', () {
      test('converts UserModel to map correctly', () {
        final user = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          dateOfBirth: DateTime(1990, 5, 20),
          gender: 'female',
          phone: '+40712345678',
          preferredLanguage: 'ro',
          userType: 'doctor',
          profileCompleted: true,
        );

        final map = user.toMap();

        expect(map['email'], 'test@example.com');
        expect(map['displayName'], 'Test User');
        expect(map['photoUrl'], 'https://example.com/photo.jpg');
        expect(map['gender'], 'female');
        expect(map['phone'], '+40712345678');
        expect(map['preferredLanguage'], 'ro');
        expect(map['userType'], 'doctor');
        expect(map['profileCompleted'], true);
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['dateOfBirth'], isA<Timestamp>());
      });

      test('does not include uid in map', () {
        final user = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );

        final map = user.toMap();

        expect(map.containsKey('uid'), false);
      });

      test('handles null optional fields', () {
        final user = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );

        final map = user.toMap();

        expect(map['displayName'], isNull);
        expect(map['photoUrl'], isNull);
        expect(map['dateOfBirth'], isNull);
        expect(map['gender'], isNull);
        expect(map['phone'], isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = UserModel(
          uid: 'user123',
          email: 'original@example.com',
          displayName: 'Original Name',
          createdAt: DateTime(2024, 1, 1),
          preferredLanguage: 'en',
          profileCompleted: false,
        );

        final copy = original.copyWith(
          email: 'updated@example.com',
          displayName: 'Updated Name',
          profileCompleted: true,
        );

        expect(copy.uid, 'user123'); // unchanged
        expect(copy.email, 'updated@example.com');
        expect(copy.displayName, 'Updated Name');
        expect(copy.preferredLanguage, 'en'); // unchanged
        expect(copy.profileCompleted, true);
      });

      test('preserves all fields when no updates provided', () {
        final original = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime(2024, 1, 15),
          dateOfBirth: DateTime(1990, 5, 20),
          gender: 'male',
          phone: '+40712345678',
          preferredLanguage: 'ro',
          userType: 'patient',
          profileCompleted: true,
          isDoctor: true,
        );

        final copy = original.copyWith();

        expect(copy.uid, original.uid);
        expect(copy.email, original.email);
        expect(copy.displayName, original.displayName);
        expect(copy.photoUrl, original.photoUrl);
        expect(copy.createdAt, original.createdAt);
        expect(copy.dateOfBirth, original.dateOfBirth);
        expect(copy.gender, original.gender);
        expect(copy.phone, original.phone);
        expect(copy.preferredLanguage, original.preferredLanguage);
        expect(copy.userType, original.userType);
        expect(copy.profileCompleted, original.profileCompleted);
        expect(copy.isDoctor, original.isDoctor);
      });
    });

    group('equality', () {
      test('two users with same uid are equal', () {
        final user1 = UserModel(
          uid: 'user123',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        );

        final user2 = UserModel(
          uid: 'user123',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
        );

        expect(user1 == user2, true);
        expect(user1.hashCode, user2.hashCode);
      });

      test('two users with different uid are not equal', () {
        final user1 = UserModel(
          uid: 'user123',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );

        final user2 = UserModel(
          uid: 'user456',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );

        expect(user1 == user2, false);
      });

      test('can be used in Set for deduplication', () {
        final user1 = UserModel(
          uid: 'user123',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        );

        final user2 = UserModel(
          uid: 'user123',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
        );

        final user3 = UserModel(
          uid: 'user456',
          email: 'user3@example.com',
          createdAt: DateTime.now(),
        );

        final set = {user1, user2, user3};

        expect(set.length, 2);
      });
    });
  });
}
