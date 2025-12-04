import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';
import '../models/medical_specialty.dart';
import '../services/doctor_service.dart';

/// Seeder script for bulk doctors + consultations (dev/testing only).
/// This will WIPE existing doctors/consultations collections before inserting new data.

class DevDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DoctorService _doctorService = DoctorService();
  final _rand = Random();

  Future<void> run({
    required int doctorCount,
    required int consultationsPerUser,
    required String patientId,
  }) async {
    debugPrint('Dev seeder will DELETE doctors & consultations collections...');
    await _clearCollection('doctors');
    await _clearCollection('consultations');

    final doctors = await _seedDoctors(doctorCount);
    await _seedConsultations(
      patientId: patientId,
      doctors: doctors,
      count: consultationsPerUser,
    );

    debugPrint('Seeding complete: ${doctors.length} doctors, $consultationsPerUser consultations for patient $patientId');
  }

  Future<void> _clearCollection(String collection) async {
    const batchSize = 300;
    while (true) {
      final snap = await _firestore.collection(collection).limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < batchSize) break;
    }
  }

  Future<List<DoctorModel>> _seedDoctors(int count) async {
    final doctors = <DoctorModel>[];
    for (int i = 0; i < count; i++) {
      final fullName = _randomFullName();
      final specialty = _randomSpecialty();
      final isAvailable = _rand.nextBool();
      final vacationPeriods = isAvailable ? <DateRange>[] : _randomVacationPeriods();
      final doctor = DoctorModel(
        uid: 'doctor_${i + 1}_${_rand.nextInt(999999)}',
        email: _emailFromName(fullName, i),
        fullName: fullName,
        photoUrl: null,
        specialty: specialty,
        subspecialties: _subspecialtiesForSpecialty(specialty),
        experienceYears: _rand.nextInt(25) + 5,
        bio: _bioForSpecialty(specialty),
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină București',
            degree: 'Doctor of Medicine',
            year: 2000 + _rand.nextInt(20),
          ),
          EducationEntry(
            institution: 'European Fellowship',
            degree: 'Fellowship in ${specialty.name}',
            year: 2010 + _rand.nextInt(10),
          ),
        ],
        consultationPrice: 250 + _rand.nextInt(200).toDouble(),
        languages: _randomLanguages(),
        isAvailable: isAvailable,
        vacationPeriods: vacationPeriods,
        createdAt: DateTime.now(),
        lastActive: DateTime.now().subtract(Duration(days: _rand.nextInt(10))),
      );
      doctors.add(doctor);
      await _doctorService.createDoctorProfile(doctor);
    }
    return doctors;
  }

  Future<void> _seedConsultations({
    required String patientId,
    required List<DoctorModel> doctors,
    required int count,
  }) async {
    final statuses = ['pending', 'in_review', 'completed', 'cancelled'];
    final urgencies = ['normal', 'priority'];
    final titles = [
      'Follow-up on chest pain',
      'Review MRI results',
      'Second opinion on diagnosis',
      'Clarify treatment plan',
      'Medication side effects',
      'Post-surgery recovery advice',
      'Chronic symptoms evaluation',
      'Lab results interpretation',
      'Specialist recommendation',
    ];
    final descriptions = [
      'Detailed overview of recent symptoms and concerns for specialist review.',
      'Requesting a clear explanation of imaging findings and next steps.',
      'Looking for confirmation of the proposed treatment plan and alternatives.',
      'Need guidance on medication adjustments and monitoring.',
      'Seeking advice on long-term management and lifestyle changes.',
    ];

    for (int i = 0; i < count; i++) {
      final doctor = doctors[_rand.nextInt(doctors.length)];
      final status = statuses[_rand.nextInt(statuses.length)];
      final urgency = urgencies[_rand.nextInt(urgencies.length)];
      final createdAt = DateTime(2025, 11, 1).subtract(Duration(days: _rand.nextInt(30)));
      final updatedAt = createdAt.add(Duration(days: _rand.nextInt(15)));
      final completedAt = status == 'completed'
          ? updatedAt.add(Duration(days: _rand.nextInt(5)))
          : null;

      final doctorResponse = status == 'completed'
          ? DoctorResponseModel(
              text: 'Doctor response with recommendations and follow-up steps.',
              respondedAt: completedAt ?? updatedAt,
              followUpNeeded: _rand.nextBool(),
            )
          : null;

      final consultation = ConsultationModel(
        id: 'consult_${i + 1}_${_rand.nextInt(999999)}',
        patientId: patientId,
        doctorId: doctor.uid,
        status: status,
        urgency: urgency,
        title: titles[_rand.nextInt(titles.length)],
        description: descriptions[_rand.nextInt(descriptions.length)],
        attachments: const [],
        doctorResponse: doctorResponse,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: completedAt,
        termsAcceptedAt: createdAt.subtract(const Duration(minutes: 5)),
        doctorName: doctor.fullName,
        doctorSpecialty: doctor.specialty.name,
      );

      await _firestore
          .collection('consultations')
          .doc(consultation.id)
          .set(consultation.toFirestore());
    }
  }

  String _randomFullName() {
    final first = _firstNames[_rand.nextInt(_firstNames.length)];
    final last = _lastNames[_rand.nextInt(_lastNames.length)];
    return '$first $last';
  }

  MedicalSpecialty _randomSpecialty() {
    final values = MedicalSpecialty.values;
    return values[_rand.nextInt(values.length)];
  }

  String _emailFromName(String fullName, int index) {
    final slug = fullName.toLowerCase().replaceAll(' ', '.');
    return '$slug.$index@medicalmcs.ro';
  }

  List<String> _subspecialtiesForSpecialty(MedicalSpecialty specialty) {
    return _subspecialtyPool[specialty] ??
        [
          'General practice',
          'Second opinions',
        ];
  }

  String _bioForSpecialty(MedicalSpecialty specialty) {
    return _bioPool[specialty] ??
        'Experienced specialist providing evidence-based second opinions.';
  }

  List<String> _randomLanguages() {
    final langs = List<String>.of(_languagePool);
    langs.shuffle(_rand);
    return langs.take(2 + _rand.nextInt(2)).toList();
  }

  List<DateRange> _randomVacationPeriods() {
    final today = DateTime.now();
    final startOffset = _rand.nextInt(7); // within a week from now
    final length = 3 + _rand.nextInt(5); // 3-7 days
    final start = DateTime(today.year, today.month, today.day)
        .add(Duration(days: startOffset));
    final end =
        DateTime(today.year, today.month, today.day).add(Duration(days: startOffset + length));
    return [
      DateRange(
        startDate: start,
        endDate: end,
        reason: 'Not available (auto-seeded)',
      ),
    ];
  }
}

const _firstNames = [
  'Andreea',
  'Victor',
  'Alexandra',
  'Mihai',
  'Iulia',
  'Radu',
  'Maria',
  'Ciprian',
  'Elena',
  'Bogdan',
  'Cristina',
  'Adrian',
  'Bianca',
  'Florin',
  'Raluca',
  'Sorin',
  'Diana',
  'Gabriel',
  'Oana',
  'Daniel',
];

const _lastNames = [
  'Popescu',
  'Ionescu',
  'Marinescu',
  'Dima',
  'Cernat',
  'Andreescu',
  'Petrescu',
  'Stoica',
  'Munteanu',
  'Tudor',
  'Gheorghiu',
  'Stancu',
  'Voicu',
  'Rusu',
  'Badea',
  'Lazar',
  'Enache',
  'Moldovan',
  'Costache',
  'Matei',
];

final Map<MedicalSpecialty, List<String>> _subspecialtyPool = {
  MedicalSpecialty.cardiology: ['interventional', 'heartFailure', 'arrhythmia'],
  MedicalSpecialty.oncology: ['solidTumors', 'hematologicOncology', 'immunotherapy'],
  MedicalSpecialty.neurology: ['epilepsy', 'movementDisorders', 'neuroimmunology'],
  MedicalSpecialty.orthopedics: ['sportsMedicine', 'jointReplacement', 'spinalSurgery'],
  MedicalSpecialty.dermatology: ['medicalDermatology', 'skinCancer', 'mohs'],
  MedicalSpecialty.endocrinology: ['diabetesManagement', 'thyroidDisorders', 'metabolicDisorders'],
  MedicalSpecialty.gastroenterology: ['inflammatoryBowelDisease', 'hepatology', 'endoscopy'],
};

final Map<MedicalSpecialty, String> _bioPool = {
  MedicalSpecialty.cardiology:
      'Cardiologist focused on interventional procedures and heart failure management.',
  MedicalSpecialty.oncology:
      'Medical oncologist with experience in chemotherapy, targeted and immunotherapy.',
  MedicalSpecialty.neurology:
      'Neurologist specializing in movement disorders, epilepsy, and neurodegenerative diseases.',
  MedicalSpecialty.orthopedics:
      'Orthopedic surgeon focused on sports injuries, arthroscopy, and joint replacement.',
  MedicalSpecialty.dermatology:
      'Dermatologist experienced in medical dermatology, skin cancer screening, and surgery.',
  MedicalSpecialty.endocrinology:
      'Endocrinologist focusing on diabetes care, thyroid disorders, and metabolic health.',
  MedicalSpecialty.gastroenterology:
      'Gastroenterologist with expertise in IBD, hepatology, and advanced endoscopy.',
  };

const _languagePool = ['RO', 'EN', 'FR', 'DE', 'ES'];

/// Convenience entry point for in-app/debug seeding.
Future<void> runDevSeeder({
  required String patientId,
  int doctorCount = 300,
  int consultationsPerUser = 25,
}) async {
  final seeder = DevDataSeeder();
  await seeder.run(
    doctorCount: doctorCount,
    consultationsPerUser: consultationsPerUser,
    patientId: patientId,
  );
}
