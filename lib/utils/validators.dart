class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Experience years validation (0-60 range)
  static String? validateExperienceYears(String? value) {
    if (value == null || value.isEmpty) {
      return 'Years of experience is required';
    }

    final years = int.tryParse(value);
    if (years == null) {
      return 'Please enter a valid number';
    }

    if (years < 0 || years > 60) {
      return 'Experience must be between 0 and 60 years';
    }

    return null;
  }

  // Consultation price validation (positive number)
  static String? validateConsultationPrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Consultation price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    if (price > 10000) {
      return 'Price cannot exceed 10,000 RON';
    }

    return null;
  }

  // Phone validation (optional, but if provided must be valid)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'Phone number must have at least 10 digits';
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
      return 'Please enter a valid number';
    }

    if (years < 0 || years > 60) {
      return 'Experience must be between 0 and 60 years';
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
      return 'Please enter a valid price';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    if (price > 10000) {
      return 'Price cannot exceed 10,000 RON';
    }

    return null;
  }
}
