import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mcs_app/models/consultation_model.dart';

void main() {
  group('ConsultationModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('fromFirestore', () {
      test('creates ConsultationModel from Firestore document', () async {
        final now = DateTime.now();
        await fakeFirestore.collection('consultations').doc('cons123').set({
          'patientId': 'patient123',
          'doctorId': 'doctor456',
          'status': 'pending',
          'urgency': 'normal',
          'title': 'Test Consultation',
          'description': 'This is a test description',
          'attachments': [],
          'infoRequests': [],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'termsAcceptedAt': Timestamp.fromDate(now),
        });

        final doc =
            await fakeFirestore.collection('consultations').doc('cons123').get();
        final consultation = ConsultationModel.fromFirestore(doc);

        expect(consultation.id, 'cons123');
        expect(consultation.patientId, 'patient123');
        expect(consultation.doctorId, 'doctor456');
        expect(consultation.status, 'pending');
        expect(consultation.urgency, 'normal');
        expect(consultation.title, 'Test Consultation');
        expect(consultation.description, 'This is a test description');
        expect(consultation.attachments, isEmpty);
        expect(consultation.infoRequests, isEmpty);
      });

      test('uses default values for missing fields', () async {
        await fakeFirestore.collection('consultations').doc('cons123').set({
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'termsAcceptedAt': Timestamp.now(),
        });

        final doc =
            await fakeFirestore.collection('consultations').doc('cons123').get();
        final consultation = ConsultationModel.fromFirestore(doc);

        expect(consultation.patientId, '');
        expect(consultation.doctorId, isNull);
        expect(consultation.status, 'pending');
        expect(consultation.urgency, 'normal');
        expect(consultation.title, '');
        expect(consultation.description, '');
      });

      test('parses attachments correctly', () async {
        final now = DateTime.now();
        await fakeFirestore.collection('consultations').doc('cons123').set({
          'patientId': 'patient123',
          'status': 'pending',
          'urgency': 'normal',
          'title': 'Test',
          'description': 'Test description',
          'attachments': [
            {
              'name': 'test.pdf',
              'url': 'https://example.com/test.pdf',
              'type': 'pdf',
              'uploadedAt': Timestamp.fromDate(now),
            },
            {
              'name': 'image.jpg',
              'url': 'https://example.com/image.jpg',
              'type': 'image',
              'uploadedAt': Timestamp.fromDate(now),
            },
          ],
          'infoRequests': [],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'termsAcceptedAt': Timestamp.fromDate(now),
        });

        final doc =
            await fakeFirestore.collection('consultations').doc('cons123').get();
        final consultation = ConsultationModel.fromFirestore(doc);

        expect(consultation.attachments.length, 2);
        expect(consultation.attachments[0].name, 'test.pdf');
        expect(consultation.attachments[0].type, 'pdf');
        expect(consultation.attachments[1].name, 'image.jpg');
        expect(consultation.attachments[1].type, 'image');
      });

      test('parses doctor response correctly', () async {
        final now = DateTime.now();
        await fakeFirestore.collection('consultations').doc('cons123').set({
          'patientId': 'patient123',
          'status': 'completed',
          'urgency': 'normal',
          'title': 'Test',
          'description': 'Test description',
          'attachments': [],
          'doctorResponse': {
            'text': 'This is the medical opinion',
            'recommendations': 'Follow up in 2 weeks',
            'respondedAt': Timestamp.fromDate(now),
            'followUpNeeded': true,
            'responseAttachments': [],
          },
          'infoRequests': [],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'termsAcceptedAt': Timestamp.fromDate(now),
        });

        final doc =
            await fakeFirestore.collection('consultations').doc('cons123').get();
        final consultation = ConsultationModel.fromFirestore(doc);

        expect(consultation.doctorResponse, isNotNull);
        expect(consultation.doctorResponse!.text, 'This is the medical opinion');
        expect(
            consultation.doctorResponse!.recommendations, 'Follow up in 2 weeks');
        expect(consultation.doctorResponse!.followUpNeeded, true);
      });

      test('parses info requests correctly', () async {
        final now = DateTime.now();
        await fakeFirestore.collection('consultations').doc('cons123').set({
          'patientId': 'patient123',
          'status': 'info_requested',
          'urgency': 'normal',
          'title': 'Test',
          'description': 'Test description',
          'attachments': [],
          'infoRequests': [
            {
              'id': 'info1',
              'message': 'Please provide more details',
              'questions': ['What medications are you taking?', 'Any allergies?'],
              'doctorId': 'doctor456',
              'requestedAt': Timestamp.fromDate(now),
              'answers': ['Aspirin', 'None'],
              'respondedAt': Timestamp.fromDate(now),
            },
          ],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'termsAcceptedAt': Timestamp.fromDate(now),
        });

        final doc =
            await fakeFirestore.collection('consultations').doc('cons123').get();
        final consultation = ConsultationModel.fromFirestore(doc);

        expect(consultation.infoRequests.length, 1);
        expect(consultation.infoRequests[0].id, 'info1');
        expect(consultation.infoRequests[0].message, 'Please provide more details');
        expect(consultation.infoRequests[0].questions.length, 2);
        expect(consultation.infoRequests[0].answers, ['Aspirin', 'None']);
        expect(consultation.infoRequests[0].isAnswered, true);
      });
    });

    group('toFirestore', () {
      test('converts ConsultationModel to Firestore map', () {
        final now = DateTime.now();
        final consultation = ConsultationModel(
          id: 'cons123',
          patientId: 'patient123',
          doctorId: 'doctor456',
          status: 'pending',
          urgency: 'priority',
          title: 'Test Consultation',
          description: 'This is a test',
          attachments: [],
          infoRequests: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final map = consultation.toFirestore();

        expect(map['patientId'], 'patient123');
        expect(map['doctorId'], 'doctor456');
        expect(map['status'], 'pending');
        expect(map['urgency'], 'priority');
        expect(map['title'], 'Test Consultation');
        expect(map['description'], 'This is a test');
        expect(map['attachments'], isEmpty);
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['updatedAt'], isA<Timestamp>());
      });

      test('includes doctor response when present', () {
        final now = DateTime.now();
        final consultation = ConsultationModel(
          id: 'cons123',
          patientId: 'patient123',
          status: 'completed',
          urgency: 'normal',
          title: 'Test',
          description: 'Test',
          attachments: [],
          doctorResponse: DoctorResponseModel(
            text: 'Medical opinion text',
            respondedAt: now,
            followUpNeeded: false,
          ),
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final map = consultation.toFirestore();

        expect(map['doctorResponse'], isNotNull);
        expect(map['doctorResponse']['text'], 'Medical opinion text');
        expect(map['doctorResponse']['followUpNeeded'], false);
      });

      test('serializes info requests correctly', () {
        final now = DateTime.now();
        final consultation = ConsultationModel(
          id: 'cons123',
          patientId: 'patient123',
          status: 'info_requested',
          urgency: 'normal',
          title: 'Test',
          description: 'Test',
          attachments: [],
          infoRequests: [
            InfoRequestModel(
              id: 'info1',
              message: 'Need more info',
              questions: ['Question 1', 'Question 2'],
              doctorId: 'doctor456',
              requestedAt: now,
            ),
          ],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final map = consultation.toFirestore();
        final infoRequests = map['infoRequests'] as List;

        expect(infoRequests.length, 1);
        expect(infoRequests[0]['id'], 'info1');
        expect(infoRequests[0]['questions'], ['Question 1', 'Question 2']);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final now = DateTime.now();
        final original = ConsultationModel(
          id: 'cons123',
          patientId: 'patient123',
          status: 'pending',
          urgency: 'normal',
          title: 'Original Title',
          description: 'Original description',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final copy = original.copyWith(
          status: 'in_review',
          doctorId: 'doctor456',
          title: 'Updated Title',
        );

        expect(copy.id, 'cons123');
        expect(copy.patientId, 'patient123');
        expect(copy.status, 'in_review');
        expect(copy.doctorId, 'doctor456');
        expect(copy.title, 'Updated Title');
        expect(copy.description, 'Original description');
        expect(copy.urgency, 'normal');
      });

      test('can update cached doctor info', () {
        final now = DateTime.now();
        final original = ConsultationModel(
          id: 'cons123',
          patientId: 'patient123',
          status: 'pending',
          urgency: 'normal',
          title: 'Test',
          description: 'Test',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final copy = original.copyWith(
          doctorName: 'Dr. Smith',
          doctorSpecialty: 'Cardiology',
        );

        expect(copy.doctorName, 'Dr. Smith');
        expect(copy.doctorSpecialty, 'Cardiology');
      });
    });

    group('equality', () {
      test('two consultations with same id are equal', () {
        final now = DateTime.now();
        final cons1 = ConsultationModel(
          id: 'cons123',
          patientId: 'patient1',
          status: 'pending',
          urgency: 'normal',
          title: 'Title 1',
          description: 'Description 1',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final cons2 = ConsultationModel(
          id: 'cons123',
          patientId: 'patient2',
          status: 'completed',
          urgency: 'priority',
          title: 'Title 2',
          description: 'Description 2',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        expect(cons1 == cons2, true);
        expect(cons1.hashCode, cons2.hashCode);
      });

      test('two consultations with different id are not equal', () {
        final now = DateTime.now();
        final cons1 = ConsultationModel(
          id: 'cons123',
          patientId: 'patient123',
          status: 'pending',
          urgency: 'normal',
          title: 'Test',
          description: 'Test',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final cons2 = ConsultationModel(
          id: 'cons456',
          patientId: 'patient123',
          status: 'pending',
          urgency: 'normal',
          title: 'Test',
          description: 'Test',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        expect(cons1 == cons2, false);
      });

      test('can be used in Set for deduplication', () {
        final now = DateTime.now();
        final cons1 = ConsultationModel(
          id: 'cons123',
          patientId: 'patient1',
          status: 'pending',
          urgency: 'normal',
          title: 'Title 1',
          description: 'Description 1',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final cons2 = ConsultationModel(
          id: 'cons123',
          patientId: 'patient2',
          status: 'completed',
          urgency: 'priority',
          title: 'Title 2',
          description: 'Description 2',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final cons3 = ConsultationModel(
          id: 'cons456',
          patientId: 'patient123',
          status: 'pending',
          urgency: 'normal',
          title: 'Test',
          description: 'Test',
          attachments: [],
          createdAt: now,
          updatedAt: now,
          termsAcceptedAt: now,
        );

        final set = {cons1, cons2, cons3};
        expect(set.length, 2);
      });
    });
  });

  group('AttachmentModel', () {
    test('fromMap parses correctly', () {
      final now = DateTime.now();
      final map = {
        'name': 'report.pdf',
        'url': 'https://example.com/report.pdf',
        'type': 'pdf',
        'uploadedAt': Timestamp.fromDate(now),
      };

      final attachment = AttachmentModel.fromMap(map);

      expect(attachment.name, 'report.pdf');
      expect(attachment.url, 'https://example.com/report.pdf');
      expect(attachment.type, 'pdf');
    });

    test('uses defaults for missing fields', () {
      final map = <String, dynamic>{};

      final attachment = AttachmentModel.fromMap(map);

      expect(attachment.name, '');
      expect(attachment.url, '');
      expect(attachment.type, 'document');
    });

    test('toMap serializes correctly', () {
      final now = DateTime.now();
      final attachment = AttachmentModel(
        name: 'image.jpg',
        url: 'https://example.com/image.jpg',
        type: 'image',
        uploadedAt: now,
      );

      final map = attachment.toMap();

      expect(map['name'], 'image.jpg');
      expect(map['url'], 'https://example.com/image.jpg');
      expect(map['type'], 'image');
      expect(map['uploadedAt'], isA<Timestamp>());
    });
  });

  group('DoctorResponseModel', () {
    test('fromMap parses correctly', () {
      final now = DateTime.now();
      final map = {
        'text': 'Medical opinion text',
        'recommendations': 'Follow-up recommended',
        'respondedAt': Timestamp.fromDate(now),
        'followUpNeeded': true,
        'responseAttachments': [],
      };

      final response = DoctorResponseModel.fromMap(map);

      expect(response.text, 'Medical opinion text');
      expect(response.recommendations, 'Follow-up recommended');
      expect(response.followUpNeeded, true);
      expect(response.responseAttachments, isEmpty);
    });

    test('parses response attachments', () {
      final now = DateTime.now();
      final map = {
        'text': 'See attached',
        'respondedAt': Timestamp.fromDate(now),
        'followUpNeeded': false,
        'responseAttachments': [
          {
            'name': 'analysis.pdf',
            'url': 'https://example.com/analysis.pdf',
            'type': 'pdf',
            'uploadedAt': Timestamp.fromDate(now),
          },
        ],
      };

      final response = DoctorResponseModel.fromMap(map);

      expect(response.responseAttachments.length, 1);
      expect(response.responseAttachments[0].name, 'analysis.pdf');
    });

    test('toMap serializes correctly', () {
      final now = DateTime.now();
      final response = DoctorResponseModel(
        text: 'Detailed opinion',
        recommendations: 'See specialist',
        respondedAt: now,
        followUpNeeded: true,
      );

      final map = response.toMap();

      expect(map['text'], 'Detailed opinion');
      expect(map['recommendations'], 'See specialist');
      expect(map['followUpNeeded'], true);
      expect(map['respondedAt'], isA<Timestamp>());
    });
  });

  group('InfoRequestModel', () {
    test('fromMap parses correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'info123',
        'message': 'Need more details',
        'questions': ['Question 1', 'Question 2'],
        'doctorId': 'doctor456',
        'requestedAt': Timestamp.fromDate(now),
      };

      final infoRequest = InfoRequestModel.fromMap(map);

      expect(infoRequest.id, 'info123');
      expect(infoRequest.message, 'Need more details');
      expect(infoRequest.questions, ['Question 1', 'Question 2']);
      expect(infoRequest.doctorId, 'doctor456');
      expect(infoRequest.answers, isNull);
      expect(infoRequest.isAnswered, false);
    });

    test('isAnswered returns true when answers exist', () {
      final now = DateTime.now();
      final infoRequest = InfoRequestModel(
        id: 'info123',
        message: 'Question',
        questions: ['Q1'],
        doctorId: 'doc123',
        requestedAt: now,
        answers: ['Answer 1'],
        respondedAt: now,
      );

      expect(infoRequest.isAnswered, true);
    });

    test('isAnswered returns false for empty answers', () {
      final now = DateTime.now();
      final infoRequest = InfoRequestModel(
        id: 'info123',
        message: 'Question',
        questions: ['Q1'],
        doctorId: 'doc123',
        requestedAt: now,
        answers: [],
      );

      expect(infoRequest.isAnswered, false);
    });

    test('copyWith creates copy with updated fields', () {
      final now = DateTime.now();
      final original = InfoRequestModel(
        id: 'info123',
        message: 'Original message',
        questions: ['Q1', 'Q2'],
        doctorId: 'doc123',
        requestedAt: now,
      );

      final answered = original.copyWith(
        answers: ['A1', 'A2'],
        additionalInfo: 'Extra info',
        respondedAt: now,
      );

      expect(answered.id, 'info123');
      expect(answered.message, 'Original message');
      expect(answered.answers, ['A1', 'A2']);
      expect(answered.additionalInfo, 'Extra info');
      expect(answered.respondedAt, isNotNull);
    });

    test('toMap excludes null optional fields', () {
      final now = DateTime.now();
      final infoRequest = InfoRequestModel(
        id: 'info123',
        message: 'Question',
        questions: ['Q1'],
        doctorId: 'doc123',
        requestedAt: now,
      );

      final map = infoRequest.toMap();

      expect(map.containsKey('answers'), false);
      expect(map.containsKey('additionalInfo'), false);
      expect(map.containsKey('respondedAt'), false);
    });

    test('toMap includes optional fields when present', () {
      final now = DateTime.now();
      final infoRequest = InfoRequestModel(
        id: 'info123',
        message: 'Question',
        questions: ['Q1'],
        doctorId: 'doc123',
        requestedAt: now,
        answers: ['A1'],
        additionalInfo: 'Extra',
        respondedAt: now,
      );

      final map = infoRequest.toMap();

      expect(map['answers'], ['A1']);
      expect(map['additionalInfo'], 'Extra');
      expect(map['respondedAt'], isA<Timestamp>());
    });
  });
}
