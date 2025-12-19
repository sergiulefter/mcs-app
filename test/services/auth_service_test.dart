import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs_app/services/auth_service.dart';

void main() {
  group('AuthService.getUserData', () {
    late FakeFirebaseFirestore firestore;
    late AuthService authService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      authService = AuthService(firestore: firestore);
    });

    test('returns doctor user for doctors collection with Timestamp dates', () async {
      final createdAt = Timestamp.fromDate(DateTime(2024, 1, 1, 10, 0));

      await firestore.collection('doctors').doc('doc123').set({
        'email': 'doc@example.com',
        'fullName': 'Dr. Timestamp',
        'photoUrl': 'https://example.com/photo.jpg',
        'createdAt': createdAt,
      });

      final user = await authService.getUserData('doc123');

      expect(user, isNotNull);
      expect(user!.isDoctor, true);
      expect(user.email, 'doc@example.com');
      expect(user.displayName, 'Dr. Timestamp');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.createdAt.year, 2024);
    });

    test('returns patient user for users collection with Timestamp dates', () async {
      final createdAt = Timestamp.fromDate(DateTime(2023, 12, 31));
      final dateOfBirth = Timestamp.fromDate(DateTime(1990, 5, 20));

      await firestore.collection('users').doc('user123').set({
        'email': 'patient@example.com',
        'displayName': 'Patient One',
        'createdAt': createdAt,
        'dateOfBirth': dateOfBirth,
        'preferredLanguage': 'ro',
      });

      final user = await authService.getUserData('user123');

      expect(user, isNotNull);
      expect(user!.isDoctor, false);
      expect(user.email, 'patient@example.com');
      expect(user.displayName, 'Patient One');
      expect(user.createdAt.year, 2023);
      expect(user.dateOfBirth?.year, 1990);
      expect(user.preferredLanguage, 'ro');
    });
  });
}
