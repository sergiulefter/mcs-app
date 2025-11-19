import 'medical_specialty.dart';

/// Education entry for doctor's academic background
class EducationEntry {
  final String institution;
  final String degree;
  final int year;

  EducationEntry({
    required this.institution,
    required this.degree,
    required this.year,
  });

  factory EducationEntry.fromMap(Map<String, dynamic> map) {
    return EducationEntry(
      institution: map['institution'] ?? '',
      degree: map['degree'] ?? '',
      year: map['year'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institution': institution,
      'degree': degree,
      'year': year,
    };
  }
}

/// Complete doctor profile model
/// This extends the basic UserModel with medical professional details
class DoctorModel {
  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;

  // Professional details
  final MedicalSpecialty specialty;
  final List<String> subspecialties;
  final int experienceYears;
  final String bio;

  // Credentials
  final List<EducationEntry> education;

  // Consultation details
  final double consultationPrice;
  final List<String> languages;

  // Availability
  final bool isAvailable;
  final List<DateRange> vacationPeriods;

  // Metadata
  final DateTime createdAt;
  final DateTime? lastActive;

  DoctorModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.specialty,
    this.subspecialties = const [],
    required this.experienceYears,
    required this.bio,
    this.education = const [],
    required this.consultationPrice,
    required this.languages,
    this.isAvailable = true,
    this.vacationPeriods = const [],
    required this.createdAt,
    this.lastActive,
  });

  /// Check if doctor is currently available (not on vacation)
  bool get isCurrentlyAvailable {
    if (!isAvailable) return false;

    for (final vacation in vacationPeriods) {
      if (vacation.isActive()) {
        return false;
      }
    }
    return true;
  }

  /// Get formatted experience string
  String get experienceLabel => '$experienceYears ${experienceYears == 1 ? 'year' : 'years'} experience';

  /// Get formatted languages string
  String get languagesLabel => languages.join(' • ');

  /// Create DoctorModel from Firestore document
  factory DoctorModel.fromMap(Map<String, dynamic> map, String uid) {
    return DoctorModel(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      photoUrl: map['photoUrl'],
      specialty: MedicalSpecialtyExtension.fromString(map['specialty'] ?? 'Family Medicine'),
      subspecialties: List<String>.from(map['subspecialties'] ?? []),
      experienceYears: map['experienceYears'] ?? 0,
      bio: map['bio'] ?? '',
      education: (map['education'] as List?)
              ?.map((e) => EducationEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      consultationPrice: (map['consultationPrice'] ?? 0).toDouble(),
      languages: List<String>.from(map['languages'] ?? ['EN']),
      isAvailable: map['isAvailable'] ?? true,
      vacationPeriods: (map['vacationPeriods'] as List?)
              ?.map((e) => DateRange.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActive: map['lastActive'] != null
          ? DateTime.parse(map['lastActive'])
          : null,
    );
  }

  /// Convert DoctorModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'specialty': specialty.name,
      'subspecialties': subspecialties,
      'experienceYears': experienceYears,
      'bio': bio,
      'education': education.map((e) => e.toMap()).toList(),
      'consultationPrice': consultationPrice,
      'languages': languages,
      'isAvailable': isAvailable,
      'vacationPeriods': vacationPeriods.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  DoctorModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? photoUrl,
    MedicalSpecialty? specialty,
    List<String>? subspecialties,
    int? experienceYears,
    String? bio,
    List<EducationEntry>? education,
    double? consultationPrice,
    List<String>? languages,
    bool? isAvailable,
    List<DateRange>? vacationPeriods,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return DoctorModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      specialty: specialty ?? this.specialty,
      subspecialties: subspecialties ?? this.subspecialties,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      education: education ?? this.education,
      consultationPrice: consultationPrice ?? this.consultationPrice,
      languages: languages ?? this.languages,
      isAvailable: isAvailable ?? this.isAvailable,
      vacationPeriods: vacationPeriods ?? this.vacationPeriods,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
