import 'package:mcs_app/utils/constants.dart';
import 'validation_result.dart';

/// Validator for consultation request data.
/// Validates title, description, and urgency fields.
class ConsultationValidator {
  ConsultationValidator._();

  /// Valid urgency levels for consultations.
  static const validUrgencyLevels = ['normal', 'priority'];

  /// Validates consultation request fields.
  /// Returns a [ValidationResult] with field-specific errors.
  ///
  /// Note: Error messages are keys, not localized strings.
  /// The UI should use these keys to display localized messages.
  static ValidationResult validate({
    required String title,
    required String description,
    required String urgency,
  }) {
    final errors = <String, String>{};

    // Title validation
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      errors['title'] = 'validation.required_field';
    } else if (trimmedTitle.length < AppConstants.titleMinLength) {
      errors['title'] = 'create_request.validation.title_too_short';
    } else if (trimmedTitle.length > AppConstants.titleMaxLength) {
      errors['title'] = 'create_request.validation.title_too_long';
    }

    // Description validation
    final trimmedDesc = description.trim();
    if (trimmedDesc.isEmpty) {
      errors['description'] = 'validation.required_field';
    } else if (trimmedDesc.length < AppConstants.descriptionMinLength) {
      errors['description'] = 'create_request.validation.description_too_short';
    } else if (trimmedDesc.length > AppConstants.descriptionMaxLength) {
      errors['description'] = 'create_request.validation.description_too_long';
    }

    // Urgency validation
    if (!validUrgencyLevels.contains(urgency)) {
      errors['urgency'] = 'create_request.validation.invalid_urgency';
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Validates only the title field.
  static String? validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return 'validation.required_field';
    }
    if (trimmed.length < AppConstants.titleMinLength) {
      return 'create_request.validation.title_too_short';
    }
    if (trimmed.length > AppConstants.titleMaxLength) {
      return 'create_request.validation.title_too_long';
    }
    return null;
  }

  /// Validates only the description field.
  static String? validateDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      return 'validation.required_field';
    }
    if (trimmed.length < AppConstants.descriptionMinLength) {
      return 'create_request.validation.description_too_short';
    }
    if (trimmed.length > AppConstants.descriptionMaxLength) {
      return 'create_request.validation.description_too_long';
    }
    return null;
  }
}
