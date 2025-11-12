class AppConstants {
  // App Information
  static const String appName = 'MCS App';
  static const String appVersion = '1.0.0';

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
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

  // Error Messages
  static const String genericError = 'An error occurred. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';

  // Success Messages
  static const String signUpSuccess = 'Account created successfully!';
  static const String signInSuccess = 'Welcome back!';
  static const String signOutSuccess = 'Signed out successfully.';
  static const String passwordResetSuccess = 'Password reset email sent!';
}
