/// Medical specialties for doctor profiles
enum MedicalSpecialty {
  cardiology,
  oncology,
  neurology,
  orthopedics,
  endocrinology,
  dermatology,
  gastroenterology,
  pulmonology,
  nephrology,
  rheumatology,
  hematology,
  infectious,
  pediatrics,
  psychiatry,
  radiology,
  surgery,
  urology,
  gynecology,
  ophthalmology,
  otolaryngology,
  anesthesiology,
  pathology,
  familyMedicine,
  internalMedicine,
  emergency,
}

/// Extension to get display names for specialties
extension MedicalSpecialtyExtension on MedicalSpecialty {
  String get name {
    switch (this) {
      case MedicalSpecialty.cardiology:
        return 'Cardiology';
      case MedicalSpecialty.oncology:
        return 'Oncology';
      case MedicalSpecialty.neurology:
        return 'Neurology';
      case MedicalSpecialty.orthopedics:
        return 'Orthopedics';
      case MedicalSpecialty.endocrinology:
        return 'Endocrinology';
      case MedicalSpecialty.dermatology:
        return 'Dermatology';
      case MedicalSpecialty.gastroenterology:
        return 'Gastroenterology';
      case MedicalSpecialty.pulmonology:
        return 'Pulmonology';
      case MedicalSpecialty.nephrology:
        return 'Nephrology';
      case MedicalSpecialty.rheumatology:
        return 'Rheumatology';
      case MedicalSpecialty.hematology:
        return 'Hematology';
      case MedicalSpecialty.infectious:
        return 'Infectious Diseases';
      case MedicalSpecialty.pediatrics:
        return 'Pediatrics';
      case MedicalSpecialty.psychiatry:
        return 'Psychiatry';
      case MedicalSpecialty.radiology:
        return 'Radiology';
      case MedicalSpecialty.surgery:
        return 'General Surgery';
      case MedicalSpecialty.urology:
        return 'Urology';
      case MedicalSpecialty.gynecology:
        return 'Gynecology';
      case MedicalSpecialty.ophthalmology:
        return 'Ophthalmology';
      case MedicalSpecialty.otolaryngology:
        return 'Otolaryngology (ENT)';
      case MedicalSpecialty.anesthesiology:
        return 'Anesthesiology';
      case MedicalSpecialty.pathology:
        return 'Pathology';
      case MedicalSpecialty.familyMedicine:
        return 'Family Medicine';
      case MedicalSpecialty.internalMedicine:
        return 'Internal Medicine';
      case MedicalSpecialty.emergency:
        return 'Emergency Medicine';
    }
  }

  String toJson() => name;

  static MedicalSpecialty fromString(String value) {
    return MedicalSpecialty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicalSpecialty.familyMedicine,
    );
  }
}

/// Date range for vacation/unavailability periods
class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  DateRange({
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  factory DateRange.fromMap(Map<String, dynamic> map) {
    return DateRange(
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (reason != null) 'reason': reason,
    };
  }

  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}
