class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Medical Correct Solution';
  static const String appDescription = 'Professional Medical Second Opinions';

  // Animation Durations - smooth transitions
  static const Duration shortDuration = Duration(milliseconds: 250);  // Micro-animations
  static const Duration mediumDuration = Duration(milliseconds: 350); // Page slides
  static const Duration longDuration = Duration(milliseconds: 400);   // Prominent transitions

  // Pricing
  static const double priorityFee = 100.0; // RON - extra fee for priority consultations

  // ===== TEXT FIELD VALIDATION CONSTANTS =====

  // Consultation Request (Patient)
  static const int titleMinLength = 10;
  static const int titleMaxLength = 100;
  static const int descriptionMinLength = 50;
  static const int descriptionMaxLength = 1000;

  // Doctor Response (Medical Opinion)
  static const int responseMinLength = 200;
  static const int responseMaxLength = 2000;

  // Doctor Bio
  static const int bioMinLength = 50;
  static const int bioMaxLength = 1000;

  // Info Request (Doctor → Patient)
  static const int infoMessageMinLength = 100;
  static const int infoMessageMaxLength = 500;
  static const int infoQuestionMinLength = 10;
  static const int infoQuestionMaxLength = 200;

  // Info Response (Patient → Doctor)
  static const int infoAnswerMinLength = 10;
  static const int infoAnswerMaxLength = 500;

  // Availability Reason
  static const int availabilityReasonMinLength = 3;
  static const int availabilityReasonMaxLength = 120;

  // Auth & Profile
  static const int passwordMinLength = 6;
  static const int nameMinLength = 2;
  static const int phoneMinDigits = 10;

  // Doctor Profile
  static const int experienceMinYears = 0;
  static const int experienceMaxYears = 60;
  static const double priceMax = 10000.0;

  // UI Display Thresholds
  static const int descriptionCounterThreshold = 200;
  static const int messagePreviewTruncate = 150;

  // ===== CONSULTATION STATUS CONSTANTS =====
  static const String statusPending = 'pending';
  static const String statusInReview = 'in_review';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusInfoRequested = 'info_requested';

  // ===== FIRESTORE COLLECTION NAMES =====
  static const String collectionUsers = 'users';
  static const String collectionDoctors = 'doctors';
  static const String collectionConsultations = 'consultations';
}
