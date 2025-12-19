import 'package:cloud_firestore/cloud_firestore.dart';

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
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      if (reason != null) 'reason': reason,
    };
  }

  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  if (value == null) {
    throw const FormatException('Date value is null');
  }
  return DateTime.parse(value.toString());
}
