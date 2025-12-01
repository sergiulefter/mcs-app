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

/// Extension for MedicalSpecialty translation and serialization.
///
/// Uses Dart's built-in enum `name` property for the translation key.
/// Example: MedicalSpecialty.cardiology.name returns "cardiology"
extension MedicalSpecialtyExtension on MedicalSpecialty {
  /// Returns the translation key (same as enum name).
  /// Example: "cardiology", "familyMedicine"
  String get key => name;

  /// Serialize to JSON (uses the enum name).
  String toJson() => name;

  /// Parse a specialty from a string value.
  /// Handles both lowercase enum names ("cardiology") and
  /// legacy capitalized format ("Cardiology").
  static MedicalSpecialty fromString(String value) {
    final normalized = value.toLowerCase();
    return MedicalSpecialty.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
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
