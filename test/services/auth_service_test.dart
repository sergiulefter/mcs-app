import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs_app/services/auth_service.dart';

void main() {
  group('AuthService Integration', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AuthService authService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      // We pass null for FirebaseAuth as we are only testing Firestore data retrieval logic
      // which uses the injected firestore instance.
      authService = AuthService(firestore: fakeFirestore);
    });

    group('getUserData', () {
      test(
        'returns correct UserModel when user is in "doctors" collection',
        () async {
          const doctorId = 'doc_123';
          final now = DateTime.now();

          // Create a doctor document
          // Note: We use the EXACT structure that caused the mismatch before
          await fakeFirestore.collection('doctors').doc(doctorId).set({
            'email': 'house@hospital.com',
            'fullName': 'Dr. Gregory House',
            'photoUrl': 'http://images/house.jpg',
            'specialty': 'diagnostic_medicine',
            'experienceYears': 10,
            'bio': 'Genius',
            'education': [], // Empty list
            'consultationPrice': 500,
            'languages': ['EN'],
            'createdAt': Timestamp.fromDate(now),
          });

          // Act
          final userModel = await authService.getUserData(doctorId);

          // Assert
          // Verified: The fix means we use toUserModel(), so isDoctor should be TRUE
          expect(userModel, isNotNull);
          expect(userModel!.uid, doctorId);
          expect(userModel.displayName, 'Dr. Gregory House');
          expect(userModel.isDoctor, true);
          expect(userModel.email, 'house@hospital.com');
        },
      );

      test(
        'returns correct UserModel when user is in "users" collection',
        () async {
          const userId = 'patient_456';
          final now = DateTime.now();

          await fakeFirestore.collection('users').doc(userId).set({
            'email': 'patient@test.com',
            'displayName': 'John Doe',
            'userType': 'patient',
            'createdAt': Timestamp.fromDate(now),
          });

          final userModel = await authService.getUserData(userId);

          expect(userModel, isNotNull);
          expect(userModel!.uid, userId);
          expect(userModel.isDoctor, false);
        },
      );

      test('returns null when user is not found', () async {
        final userModel = await authService.getUserData('unknown_id');
        expect(userModel, isNull);
      });
    });
  });
}
