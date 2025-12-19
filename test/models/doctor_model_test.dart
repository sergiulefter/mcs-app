import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/models/medical_specialty.dart';

void main() {
  group('DoctorModel', () {
    DoctorModel createTestDoctor({
      String uid = 'doc123',
      String email = 'doctor@example.com',
      String fullName = 'Dr. Test User',
      MedicalSpecialty specialty = MedicalSpecialty.cardiology,
      int experienceYears = 10,
      String bio = 'Experienced cardiologist',
      List<EducationEntry> education = const [],
      double consultationPrice = 200.0,
      List<String> languages = const ['EN', 'RO'],
      bool isAvailable = true,
      List<DateRange> vacationPeriods = const [],
    }) {
      return DoctorModel(
        uid: uid,
        email: email,
        fullName: fullName,
        specialty: specialty,
        experienceYears: experienceYears,
        bio: bio,
        education: education,
        consultationPrice: consultationPrice,
        languages: languages,
        isAvailable: isAvailable,
        vacationPeriods: vacationPeriods,
        createdAt: DateTime(2024, 1, 1),
      );
    }

    group('fromMap', () {
      test('creates DoctorModel with all fields from map', () {
        final map = {
          'email': 'doctor@example.com',
          'fullName': 'Dr. John Smith',
          'photoUrl': 'https://example.com/photo.jpg',
          'specialty': 'cardiology',
          'subspecialties': ['interventional', 'electrophysiology'],
          'experienceYears': 15,
          'bio': 'Board-certified cardiologist',
          'education': [
            {
              'institution': 'Harvard Medical School',
              'degree': 'MD',
              'year': 2005,
            }
          ],
          'consultationPrice': 250.0,
          'languages': ['EN', 'RO', 'DE'],
          'isAvailable': true,
          'vacationPeriods': [],
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30)),
          'lastActive': Timestamp.fromDate(DateTime(2024, 3, 20, 14, 0)),
        };

        final doctor = DoctorModel.fromMap(map, 'doc123');

        expect(doctor.uid, 'doc123');
        expect(doctor.email, 'doctor@example.com');
        expect(doctor.fullName, 'Dr. John Smith');
        expect(doctor.photoUrl, 'https://example.com/photo.jpg');
        expect(doctor.specialty, MedicalSpecialty.cardiology);
        expect(doctor.subspecialties, ['interventional', 'electrophysiology']);
        expect(doctor.experienceYears, 15);
        expect(doctor.bio, 'Board-certified cardiologist');
        expect(doctor.education.length, 1);
        expect(doctor.education.first.institution, 'Harvard Medical School');
        expect(doctor.consultationPrice, 250.0);
        expect(doctor.languages, ['EN', 'RO', 'DE']);
        expect(doctor.isAvailable, true);
      });

      test('uses default values for missing fields', () {
        final map = <String, dynamic>{};

        final doctor = DoctorModel.fromMap(map, 'doc123');

        expect(doctor.uid, 'doc123');
        expect(doctor.email, '');
        expect(doctor.fullName, '');
        expect(doctor.specialty, MedicalSpecialty.familyMedicine);
        expect(doctor.subspecialties, isEmpty);
        expect(doctor.experienceYears, 0);
        expect(doctor.bio, '');
        expect(doctor.education, isEmpty);
        expect(doctor.consultationPrice, 0.0);
        expect(doctor.languages, ['EN']);
        expect(doctor.isAvailable, true);
      });

      test('parses specialty from lowercase string', () {
        final map = {'specialty': 'neurology'};
        final doctor = DoctorModel.fromMap(map, 'doc123');
        expect(doctor.specialty, MedicalSpecialty.neurology);
      });

      test('parses specialty from legacy capitalized format', () {
        final map = {'specialty': 'Cardiology'};
        final doctor = DoctorModel.fromMap(map, 'doc123');
        expect(doctor.specialty, MedicalSpecialty.cardiology);
      });
    });

    group('toMap', () {
      test('converts DoctorModel to map correctly', () {
        final doctor = DoctorModel(
          uid: 'doc123',
          email: 'doctor@example.com',
          fullName: 'Dr. Test User',
          specialty: MedicalSpecialty.oncology,
          experienceYears: 20,
          bio: 'Experienced oncologist',
          education: [
            EducationEntry(
              institution: 'Oxford',
              degree: 'MD',
              year: 2000,
            ),
          ],
          consultationPrice: 300.0,
          languages: ['EN'],
          createdAt: DateTime(2024, 1, 15),
        );

        final map = doctor.toMap();

        expect(map['email'], 'doctor@example.com');
        expect(map['fullName'], 'Dr. Test User');
        expect(map['specialty'], 'oncology');
        expect(map['experienceYears'], 20);
        expect(map['bio'], 'Experienced oncologist');
        expect(map['consultationPrice'], 300.0);
        expect(map['languages'], ['EN']);
        expect(map['education'], isNotEmpty);
        expect(map['createdAt'], isA<Timestamp>());
      });

      test('serializes education entries correctly', () {
        final doctor = DoctorModel(
          uid: 'doc123',
          email: 'doctor@example.com',
          fullName: 'Dr. Test User',
          specialty: MedicalSpecialty.cardiology,
          experienceYears: 10,
          bio: 'Test bio',
          education: [
            EducationEntry(
              institution: 'Harvard',
              degree: 'MD',
              year: 2010,
            ),
            EducationEntry(
              institution: 'Stanford',
              degree: 'PhD',
              year: 2015,
            ),
          ],
          consultationPrice: 200.0,
          languages: ['EN'],
          createdAt: DateTime(2024, 1, 1),
        );

        final map = doctor.toMap();
        final educationList = map['education'] as List;

        expect(educationList.length, 2);
        expect(educationList[0]['institution'], 'Harvard');
        expect(educationList[1]['institution'], 'Stanford');
      });

      test('serializes vacation periods correctly', () {
        final doctor = DoctorModel(
          uid: 'doc123',
          email: 'doctor@example.com',
          fullName: 'Dr. Test User',
          specialty: MedicalSpecialty.cardiology,
          experienceYears: 10,
          bio: 'Test bio',
          consultationPrice: 200.0,
          languages: ['EN'],
          vacationPeriods: [
            DateRange(
              startDate: DateTime(2024, 7, 1),
              endDate: DateTime(2024, 7, 15),
              reason: 'Summer vacation',
            ),
          ],
          createdAt: DateTime(2024, 1, 1),
        );

        final map = doctor.toMap();
        final vacationList = map['vacationPeriods'] as List;

        expect(vacationList.length, 1);
        expect(vacationList[0]['reason'], 'Summer vacation');
      });
    });

    group('computed properties', () {
      group('isCurrentlyAvailable', () {
        test('returns true when available and no vacation', () {
          final doctor = createTestDoctor(isAvailable: true);
          expect(doctor.isCurrentlyAvailable, true);
        });

        test('returns false when isAvailable is false', () {
          final doctor = createTestDoctor(isAvailable: false);
          expect(doctor.isCurrentlyAvailable, false);
        });

        test('returns false during active vacation period', () {
          final now = DateTime.now();
          final doctor = createTestDoctor(
            isAvailable: true,
            vacationPeriods: [
              DateRange(
                startDate: now.subtract(const Duration(days: 1)),
                endDate: now.add(const Duration(days: 5)),
              ),
            ],
          );
          expect(doctor.isCurrentlyAvailable, false);
        });

        test('returns true when vacation is in the past', () {
          final now = DateTime.now();
          final doctor = createTestDoctor(
            isAvailable: true,
            vacationPeriods: [
              DateRange(
                startDate: now.subtract(const Duration(days: 10)),
                endDate: now.subtract(const Duration(days: 5)),
              ),
            ],
          );
          expect(doctor.isCurrentlyAvailable, true);
        });

        test('returns true when vacation is in the future', () {
          final now = DateTime.now();
          final doctor = createTestDoctor(
            isAvailable: true,
            vacationPeriods: [
              DateRange(
                startDate: now.add(const Duration(days: 5)),
                endDate: now.add(const Duration(days: 15)),
              ),
            ],
          );
          expect(doctor.isCurrentlyAvailable, true);
        });
      });

      group('isProfileComplete', () {
        test('returns true when bio and education are present', () {
          final doctor = createTestDoctor(
            bio: 'This is a bio',
            education: [
              EducationEntry(
                institution: 'Test University',
                degree: 'MD',
                year: 2010,
              ),
            ],
          );
          expect(doctor.isProfileComplete, true);
        });

        test('returns false when bio is empty', () {
          final doctor = createTestDoctor(
            bio: '',
            education: [
              EducationEntry(
                institution: 'Test University',
                degree: 'MD',
                year: 2010,
              ),
            ],
          );
          expect(doctor.isProfileComplete, false);
        });

        test('returns false when education is empty', () {
          final doctor = createTestDoctor(
            bio: 'This is a bio',
            education: [],
          );
          expect(doctor.isProfileComplete, false);
        });

        test('returns false when both bio and education are empty', () {
          final doctor = createTestDoctor(
            bio: '',
            education: [],
          );
          expect(doctor.isProfileComplete, false);
        });
      });

      group('experienceTier', () {
        test('returns "new" for less than 5 years', () {
          expect(createTestDoctor(experienceYears: 0).experienceTier, 'new');
          expect(createTestDoctor(experienceYears: 2).experienceTier, 'new');
          expect(createTestDoctor(experienceYears: 4).experienceTier, 'new');
        });

        test('returns "5+" for 5-9 years', () {
          expect(createTestDoctor(experienceYears: 5).experienceTier, '5+');
          expect(createTestDoctor(experienceYears: 7).experienceTier, '5+');
          expect(createTestDoctor(experienceYears: 9).experienceTier, '5+');
        });

        test('returns "10+" for 10-14 years', () {
          expect(createTestDoctor(experienceYears: 10).experienceTier, '10+');
          expect(createTestDoctor(experienceYears: 12).experienceTier, '10+');
          expect(createTestDoctor(experienceYears: 14).experienceTier, '10+');
        });

        test('returns "15+" for 15+ years', () {
          expect(createTestDoctor(experienceYears: 15).experienceTier, '15+');
          expect(createTestDoctor(experienceYears: 20).experienceTier, '15+');
          expect(createTestDoctor(experienceYears: 30).experienceTier, '15+');
        });
      });

      group('topEducation', () {
        test('returns null when education is empty', () {
          final doctor = createTestDoctor(education: []);
          expect(doctor.topEducation, isNull);
        });

        test('returns first institution when education exists', () {
          final doctor = createTestDoctor(
            education: [
              EducationEntry(
                institution: 'Harvard',
                degree: 'MD',
                year: 2010,
              ),
              EducationEntry(
                institution: 'Stanford',
                degree: 'PhD',
                year: 2015,
              ),
            ],
          );
          expect(doctor.topEducation, 'Harvard');
        });
      });

      group('experienceLabel', () {
        test('uses singular form for 1 year', () {
          final doctor = createTestDoctor(experienceYears: 1);
          expect(doctor.experienceLabel, '1 year experience');
        });

        test('uses plural form for multiple years', () {
          final doctor = createTestDoctor(experienceYears: 10);
          expect(doctor.experienceLabel, '10 years experience');
        });
      });

      group('languagesLabel', () {
        test('joins languages with bullet separator', () {
          final doctor = createTestDoctor(languages: ['EN', 'RO', 'DE']);
          expect(doctor.languagesLabel, 'EN • RO • DE');
        });
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = createTestDoctor(
          fullName: 'Dr. Original',
          experienceYears: 10,
          consultationPrice: 200.0,
        );

        final copy = original.copyWith(
          fullName: 'Dr. Updated',
          experienceYears: 15,
        );

        expect(copy.uid, original.uid);
        expect(copy.fullName, 'Dr. Updated');
        expect(copy.experienceYears, 15);
        expect(copy.consultationPrice, 200.0); // unchanged
      });
    });

    group('equality', () {
      test('two doctors with same uid are equal', () {
        final doctor1 = createTestDoctor(uid: 'doc123', fullName: 'Dr. One');
        final doctor2 = createTestDoctor(uid: 'doc123', fullName: 'Dr. Two');

        expect(doctor1 == doctor2, true);
        expect(doctor1.hashCode, doctor2.hashCode);
      });

      test('two doctors with different uid are not equal', () {
        final doctor1 = createTestDoctor(uid: 'doc123');
        final doctor2 = createTestDoctor(uid: 'doc456');

        expect(doctor1 == doctor2, false);
      });
    });
  });

  group('EducationEntry', () {
    test('fromMap creates entry correctly', () {
      final map = {
        'institution': 'Harvard Medical School',
        'degree': 'MD',
        'year': 2005,
      };

      final entry = EducationEntry.fromMap(map);

      expect(entry.institution, 'Harvard Medical School');
      expect(entry.degree, 'MD');
      expect(entry.year, 2005);
    });

    test('toMap serializes correctly', () {
      final entry = EducationEntry(
        institution: 'Oxford',
        degree: 'PhD',
        year: 2010,
      );

      final map = entry.toMap();

      expect(map['institution'], 'Oxford');
      expect(map['degree'], 'PhD');
      expect(map['year'], 2010);
    });

    test('uses defaults for missing fields', () {
      final map = <String, dynamic>{};

      final entry = EducationEntry.fromMap(map);

      expect(entry.institution, '');
      expect(entry.degree, '');
      expect(entry.year, 0);
    });
  });

  group('MedicalSpecialty', () {
    test('fromString parses lowercase specialty', () {
      expect(
        MedicalSpecialtyExtension.fromString('cardiology'),
        MedicalSpecialty.cardiology,
      );
      expect(
        MedicalSpecialtyExtension.fromString('neurology'),
        MedicalSpecialty.neurology,
      );
    });

    test('fromString parses capitalized specialty', () {
      expect(
        MedicalSpecialtyExtension.fromString('Cardiology'),
        MedicalSpecialty.cardiology,
      );
      expect(
        MedicalSpecialtyExtension.fromString('ONCOLOGY'),
        MedicalSpecialty.oncology,
      );
    });

    test('fromString returns familyMedicine for unknown value', () {
      expect(
        MedicalSpecialtyExtension.fromString('unknown'),
        MedicalSpecialty.familyMedicine,
      );
    });

    test('key returns enum name', () {
      expect(MedicalSpecialty.cardiology.key, 'cardiology');
      expect(MedicalSpecialty.familyMedicine.key, 'familyMedicine');
    });

    test('toJson returns enum name', () {
      expect(MedicalSpecialty.oncology.toJson(), 'oncology');
    });
  });

  group('DateRange', () {
    test('fromMap parses correctly', () {
      final map = {
        'startDate': Timestamp.fromDate(DateTime(2024, 7, 1)),
        'endDate': Timestamp.fromDate(DateTime(2024, 7, 15)),
        'reason': 'Summer vacation',
      };

      final range = DateRange.fromMap(map);

      expect(range.startDate.year, 2024);
      expect(range.startDate.month, 7);
      expect(range.startDate.day, 1);
      expect(range.endDate.day, 15);
      expect(range.reason, 'Summer vacation');
    });

      test('toMap serializes correctly', () {
        final range = DateRange(
          startDate: DateTime(2024, 8, 1),
          endDate: DateTime(2024, 8, 10),
          reason: 'Conference',
        );

        final map = range.toMap();

        expect(map['reason'], 'Conference');
        expect(map['startDate'], isA<Timestamp>());
        expect(map['endDate'], isA<Timestamp>());
      });

    test('toMap excludes reason when null', () {
      final range = DateRange(
        startDate: DateTime(2024, 8, 1),
        endDate: DateTime(2024, 8, 10),
      );

      final map = range.toMap();

      expect(map.containsKey('reason'), false);
    });

    test('isActive returns true during active period', () {
      final now = DateTime.now();
      final range = DateRange(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 5)),
      );

      expect(range.isActive(), true);
    });

    test('isActive returns false before period', () {
      final now = DateTime.now();
      final range = DateRange(
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 10)),
      );

      expect(range.isActive(), false);
    });

    test('isActive returns false after period', () {
      final now = DateTime.now();
      final range = DateRange(
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 5)),
      );

      expect(range.isActive(), false);
    });
  });
}
