import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';

void main() {
  group('ConsultationsController Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ConsultationsController controller;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      controller = ConsultationsController(firestore: fakeFirestore);
    });

    test(
      'fetchUserConsultations fetches data and enriches with doctor info',
      () async {
        // 1. Setup Test Data
        const patientId = 'patient_123';
        const doctorId = 'doctor_456';
        final now = DateTime.now();

        // Create a Doctor
        await fakeFirestore.collection('doctors').doc(doctorId).set({
          'fullName': 'Gregory House',
          'specialty': 'internalMedicine',
          'yearsOfExperience': 15,
          'consultationPrice': 500,
          'rating': 5.0,
          'reviewCount': 100,
          'isAvailable': true,
          'bio': 'Diagnostics expert',
          'education': [],
          'languages': ['EN'],
        });

        // Create a Consultation for this doctor (initially without doctor name)
        await fakeFirestore.collection('consultations').doc('cons_1').set({
          'patientId': patientId,
          'doctorId': doctorId,
          'status': 'pending',
          'urgency': 'normal',
          'title': 'Leg Pain',
          'description': 'My leg hurts',
          'attachments': [],
          'infoRequests': [],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'termsAcceptedAt': Timestamp.fromDate(now),
          // doctorName and doctorSpecialty are intentionally omitted or null here
        });

        // 2. Execute Action
        await controller.fetchUserConsultations(patientId);

        // 3. Verify Results
        expect(controller.isLoading, false);
        expect(controller.consultations.length, 1);

        final consultation = controller.consultations.first;
        expect(consultation.id, 'cons_1');
        expect(consultation.doctorName, 'Gregory House');
        expect(consultation.doctorSpecialty, 'internalMedicine');
      },
    );

    test('fetchUserConsultations handles missing doctor gracefully', () async {
      const patientId = 'patient_123';
      const doctorId = 'doctor_unknown';
      final now = DateTime.now();

      // Create a Consultation pointing to a non-existent doctor
      await fakeFirestore.collection('consultations').doc('cons_2').set({
        'patientId': patientId,
        'doctorId': doctorId,
        'status': 'pending',
        'urgency': 'normal',
        'title': 'Mystery Doc',
        'description': 'Who is it?',
        'attachments': [],
        'infoRequests': [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'termsAcceptedAt': Timestamp.fromDate(now),
      });

      await controller.fetchUserConsultations(patientId);

      expect(controller.consultations.length, 1);
      final consultation = controller.consultations.first;

      // Doctor info should remain null/default
      expect(consultation.doctorName, isNull);
      expect(consultation.doctorSpecialty, isNull);
    });

    test('Set logic correctly handles updates without duplication', () async {
      // This tests that our Set logic in _fetchDoctorInfoForList removes the old item
      // and adds the new one, rather than just adding a duplicate.
      const patientId = 'patient_123';
      const doctorId = 'doctor_456';
      final now = DateTime.now();

      await fakeFirestore.collection('doctors').doc(doctorId).set({
        'fullName': 'Gregory House',
        'specialty': 'internalMedicine',
        'yearsOfExperience': 15,
        'consultationPrice': 500,
        'rating': 5.0,
        'reviewCount': 100,
        'isAvailable': true,
        'bio': 'Diagnostics expert',
        'education': [],
        'languages': ['EN'],
      });

      await fakeFirestore.collection('consultations').doc('cons_1').set({
        'patientId': patientId,
        'doctorId': doctorId,
        'status': 'pending',
        'urgency': 'normal',
        'title': 'Test Dedupe',
        'description': 'Test',
        'attachments': [],
        'infoRequests': [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'termsAcceptedAt': Timestamp.fromDate(now),
      });

      await controller.fetchUserConsultations(patientId);

      // Should still be 1, not 2
      expect(controller.consultations.length, 1);

      // And should be the updated one
      expect(controller.consultations.first.doctorName, 'Gregory House');
    });
  });
}
