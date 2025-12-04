import 'package:flutter/foundation.dart';

import '../models/doctor_model.dart';
import '../models/medical_specialty.dart';
import '../services/doctor_service.dart';

/// This should be called ONCE to populate the database
/// In production, doctors would be created by admins via admin panel

/// Utility class to seed sample doctors to Firestore for testing
class DoctorSeeder {
  final DoctorService _doctorService = DoctorService();

  /// Create sample doctors in Firestore
  Future<void> seedDoctors() async {
    final sampleDoctors = _getSampleDoctors();

    for (final doctor in sampleDoctors) {
      try {
        await _doctorService.createDoctorProfile(doctor);
        debugPrint('Created doctor: ${doctor.fullName}');
      } catch (e) {
        debugPrint('Error creating doctor ${doctor.fullName}: $e');
      }
    }

    debugPrint('Seeding complete!');
  }

  /// Get list of sample doctors
  List<DoctorModel> _getSampleDoctors() {
    return [
      DoctorModel(
        uid: 'doctor_001',
        email: 'andreea.popescu@medicalmcs.ro',
        fullName: 'Dr. Andreea Popescu',
        photoUrl: null,
        specialty: MedicalSpecialty.cardiology,
        subspecialties: ['interventional', 'heartFailure'],
        experienceYears: 18,
        bio:
            'Cardiologist with extensive experience in interventional procedures and heart failure management. Specialized in complex coronary interventions and structural heart disease.',
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină Cluj-Napoca',
            degree: 'Doctor of Medicine',
            year: 2006,
          ),
          EducationEntry(
            institution: 'Mayo Clinic',
            degree: 'Fellowship in Interventional Cardiology',
            year: 2012,
          ),
        ],
        consultationPrice: 350.0,
        languages: ['RO', 'EN', 'FR'],
        isAvailable: true,
        vacationPeriods: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      DoctorModel(
        uid: 'doctor_002',
        email: 'victor.marinescu@medicalmcs.ro',
        fullName: 'Dr. Victor Marinescu',
        photoUrl: null,
        specialty: MedicalSpecialty.oncology,
        subspecialties: ['solidTumors', 'hematologicOncology'],
        experienceYears: 16,
        bio:
            'Medical oncologist specializing in solid tumors and hematological malignancies. Extensive experience with chemotherapy, targeted therapy, and immunotherapy protocols.',
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină București',
            degree: 'Doctor of Medicine',
            year: 2008,
          ),
          EducationEntry(
            institution: 'MD Anderson Cancer Center',
            degree: 'Fellowship in Medical Oncology',
            year: 2014,
          ),
        ],
        consultationPrice: 400.0,
        languages: ['RO', 'EN'],
        isAvailable: false,
        vacationPeriods: [
          DateRange(
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 7)),
            reason: 'Medical conference',
          ),
        ],
        createdAt: DateTime.now(),
        lastActive: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DoctorModel(
        uid: 'doctor_003',
        email: 'alexandra.dima@medicalmcs.ro',
        fullName: 'Dr. Alexandra Dima',
        photoUrl: null,
        specialty: MedicalSpecialty.neurology,
        subspecialties: ['movementDisorders', 'epilepsy'],
        experienceYears: 12,
        bio:
            'Neurologist with expertise in movement disorders, epilepsy management, and neurodegenerative diseases. Active researcher in Parkinson\'s disease treatment.',
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină București',
            degree: 'Doctor of Medicine',
            year: 2012,
          ),
          EducationEntry(
            institution: 'Charité Berlin',
            degree: 'Fellowship in Movement Disorders',
            year: 2017,
          ),
        ],
        consultationPrice: 320.0,
        languages: ['RO', 'EN', 'DE'],
        isAvailable: true,
        vacationPeriods: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      DoctorModel(
        uid: 'doctor_004',
        email: 'mihai.cernat@medicalmcs.ro',
        fullName: 'Dr. Mihai Cernat',
        photoUrl: null,
        specialty: MedicalSpecialty.orthopedics,
        subspecialties: ['sportsMedicine', 'jointReplacement'],
        experienceYears: 14,
        bio:
            'Orthopedic surgeon specializing in sports injuries, arthroscopic surgery, and joint replacement procedures. Team physician for professional sports teams.',
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină Iași',
            degree: 'Doctor of Medicine',
            year: 2010,
          ),
          EducationEntry(
            institution: 'Hospital for Special Surgery, New York',
            degree: 'Fellowship in Sports Medicine',
            year: 2015,
          ),
        ],
        consultationPrice: 380.0,
        languages: ['RO', 'EN', 'IT'],
        isAvailable: true,
        vacationPeriods: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      DoctorModel(
        uid: 'doctor_005',
        email: 'iulia.andreescu@medicalmcs.ro',
        fullName: 'Dr. Iulia Andreescu',
        photoUrl: null,
        specialty: MedicalSpecialty.endocrinology,
        subspecialties: ['diabetesManagement', 'thyroidDisorders'],
        experienceYears: 11,
        bio:
            'Endocrinologist focusing on diabetes management, thyroid disorders, and metabolic diseases. Expert in insulin pump therapy and continuous glucose monitoring.',
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină Timișoara',
            degree: 'Doctor of Medicine',
            year: 2013,
          ),
          EducationEntry(
            institution: 'Joslin Diabetes Center, Boston',
            degree: 'Fellowship in Endocrinology',
            year: 2018,
          ),
        ],
        consultationPrice: 300.0,
        languages: ['RO', 'EN'],
        isAvailable: true,
        vacationPeriods: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      DoctorModel(
        uid: 'doctor_006',
        email: 'radu.ionescu@medicalmcs.ro',
        fullName: 'Dr. Radu Ionescu',
        photoUrl: null,
        specialty: MedicalSpecialty.gastroenterology,
        subspecialties: ['inflammatoryBowelDisease', 'hepatology'],
        experienceYears: 15,
        bio:
            'Gastroenterologist with expertise in inflammatory bowel disease, liver disorders, and advanced endoscopic procedures. Certified in ERCP and EUS.',
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină București',
            degree: 'Doctor of Medicine',
            year: 2009,
          ),
          EducationEntry(
            institution: 'Cleveland Clinic',
            degree: 'Fellowship in Gastroenterology',
            year: 2014,
          ),
        ],
        consultationPrice: 340.0,
        languages: ['RO', 'EN'],
        isAvailable: true,
        vacationPeriods: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
      DoctorModel(
        uid: 'doctor_007',
        email: 'maria.popa@medicalmcs.ro',
        fullName: 'Dr. Maria Popa',
        photoUrl: null,
        specialty: MedicalSpecialty.dermatology,
        subspecialties: ['medicalDermatology', 'mohs'],
        experienceYears: 13,
        bio:
            'Dermatologist specializing in medical dermatology, skin cancer detection, and dermatologic surgery. Expert in psoriasis and eczema management.',
        education: [
          EducationEntry(
            institution: 'Universitatea de Medicină Cluj-Napoca',
            degree: 'Doctor of Medicine',
            year: 2011,
          ),
          EducationEntry(
            institution: 'University of California, San Francisco',
            degree: 'Fellowship in Dermatology',
            year: 2016,
          ),
        ],
        consultationPrice: 310.0,
        languages: ['RO', 'EN', 'ES'],
        isAvailable: true,
        vacationPeriods: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
    ];
  }
}