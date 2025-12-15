/// Represents the result of a validation operation.
/// Contains whether validation passed and a map of field-specific errors.
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const ValidationResult._({required this.isValid, required this.errors});

  /// Creates a successful validation result with no errors.
  factory ValidationResult.success() =>
      const ValidationResult._(isValid: true, errors: {});

  /// Creates a failed validation result with the given errors.
  /// [errors] is a map of field names to error messages.
  factory ValidationResult.failure(Map<String, String> errors) =>
      ValidationResult._(isValid: false, errors: errors);

  /// Returns the error message for a specific field, or null if no error.
  String? getError(String field) => errors[field];

  /// Returns true if the given field has an error.
  bool hasError(String field) => errors.containsKey(field);

  /// Returns a list of all error messages.
  List<String> get allErrors => errors.values.toList();

  /// Returns the first error message, or null if no errors.
  String? get firstError => errors.values.isEmpty ? null : errors.values.first;
}
