import '../../utils/constants.dart';

/// Mixin providing shared consultation status filtering logic
/// Used by both ConsultationsController (patient) and DoctorConsultationsController (doctor)
mixin ConsultationFilterMixin {
  /// Returns true if the status represents an active consultation
  /// (pending, in_review, or info_requested)
  static bool isActiveStatus(String status) =>
      status == AppConstants.statusPending ||
      status == AppConstants.statusInReview ||
      status == AppConstants.statusInfoRequested;

  /// Returns true if the status represents a completed consultation
  static bool isCompletedStatus(String status) =>
      status == AppConstants.statusCompleted;

  /// Returns true if the status represents a cancelled consultation
  static bool isCancelledStatus(String status) =>
      status == AppConstants.statusCancelled;

  /// Returns true if the status represents a finished consultation
  /// (either completed or cancelled)
  static bool isFinishedStatus(String status) =>
      isCompletedStatus(status) || isCancelledStatus(status);
}
