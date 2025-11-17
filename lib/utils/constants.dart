class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Medical Correct Solution';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Professional Medical Second Opinions';

  // Spacing (legacy - prefer AppTheme.spacing* for new code)
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius (legacy - prefer AppTheme.radius* for new code)
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int maxNameLength = 100;
  static const int maxBioLength = 500;
  static const int maxQuestionLength = 2000;

  // File Upload Limits
  static const int maxFileCount = 10;
  static const int maxFileSizeMB = 25;
  static const List<String> allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];

  // Request Status
  static const String statusSubmitted = 'submitted';
  static const String statusInReview = 'in_review';
  static const String statusInfoRequested = 'info_requested';
  static const String statusCompleted = 'completed';
  static const String statusExpired = 'expired';

  // User Types
  static const String userTypePatient = 'patient';
  static const String userTypeDoctor = 'doctor';
  static const String userTypeAdmin = 'admin';

  // Languages
  static const String languageRomanian = 'ro';
  static const String languageEnglish = 'en';

  // Error Messages
  static const String genericError = 'An error occurred. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String fileUploadError = 'Failed to upload file. Please try again.';
  static const String fileSizeError = 'File size exceeds the maximum limit.';
  static const String fileTypeError = 'File type not supported.';

  // Success Messages
  static const String signUpSuccess = 'Account created successfully!';
  static const String signInSuccess = 'Welcome back!';
  static const String signOutSuccess = 'Signed out successfully.';
  static const String passwordResetSuccess = 'Password reset email sent!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
  static const String requestSubmitSuccess = 'Your request has been submitted!';

  // Medical Disclaimer
  static const String medicalDisclaimer =
      'This service does not replace direct medical consultation. '
      'Always consult with your primary healthcare provider for medical decisions.';
}
