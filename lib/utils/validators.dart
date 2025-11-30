import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.email_required'.tr();
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'validation.invalid_email'.tr();
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.password_required'.tr();
    }

    if (value.length < AppConstants.passwordMinLength) {
      return 'validation.password_too_short'.tr(
        namedArgs: {'min': AppConstants.passwordMinLength.toString()},
      );
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'validation.confirm_password_required'.tr();
    }

    if (value != password) {
      return 'validation.passwords_not_match'.tr();
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.name_required'.tr();
    }

    if (value.length < AppConstants.nameMinLength) {
      return 'validation.name_too_short'.tr(
        namedArgs: {'min': AppConstants.nameMinLength.toString()},
      );
    }

    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'validation.required_field'.tr();
    }
    return null;
  }

  // Experience years validation (0-60 range)
  static String? validateExperienceYears(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.experience_required'.tr();
    }

    final years = int.tryParse(value);
    if (years == null) {
      return 'validation.invalid_number'.tr();
    }

    if (years < AppConstants.experienceMinYears || years > AppConstants.experienceMaxYears) {
      return 'validation.experience_range'.tr(
        namedArgs: {
          'min': AppConstants.experienceMinYears.toString(),
          'max': AppConstants.experienceMaxYears.toString(),
        },
      );
    }

    return null;
  }

  // Consultation price validation (positive number)
  static String? validateConsultationPrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.price_required'.tr();
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'validation.invalid_price'.tr();
    }

    if (price <= 0) {
      return 'validation.price_positive'.tr();
    }

    if (price > AppConstants.priceMax) {
      return 'validation.price_max'.tr(
        namedArgs: {'max': AppConstants.priceMax.toStringAsFixed(0)},
      );
    }

    return null;
  }

  // Phone validation (optional, but if provided must be valid)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < AppConstants.phoneMinDigits) {
      return 'validation.invalid_phone'.tr();
    }

    return null;
  }

  // Experience years validation - OPTIONAL (0-60 range if provided)
  static String? validateExperienceYearsOptional(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final years = int.tryParse(value);
    if (years == null) {
      return 'validation.invalid_number'.tr();
    }

    if (years < AppConstants.experienceMinYears || years > AppConstants.experienceMaxYears) {
      return 'validation.experience_range'.tr(
        namedArgs: {
          'min': AppConstants.experienceMinYears.toString(),
          'max': AppConstants.experienceMaxYears.toString(),
        },
      );
    }

    return null;
  }

  // Consultation price validation - OPTIONAL (positive number if provided)
  static String? validateConsultationPriceOptional(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'validation.invalid_price'.tr();
    }

    if (price <= 0) {
      return 'validation.price_positive'.tr();
    }

    if (price > AppConstants.priceMax) {
      return 'validation.price_max'.tr(
        namedArgs: {'max': AppConstants.priceMax.toStringAsFixed(0)},
      );
    }

    return null;
  }
}
