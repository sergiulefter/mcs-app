import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Centralized helper for displaying notifications to users.
/// This helper provides consistent error/success display.
class NotificationsHelper {
  static final NotificationsHelper _instance = NotificationsHelper._internal();
  factory NotificationsHelper() => _instance;
  NotificationsHelper._internal();

  /// Shows an error message to the user.
  /// Parses Firebase/common errors into user-friendly localized messages.
  void showError(String error, {required BuildContext context}) {
    final message = _parseError(error);
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: semanticColors?.error ?? Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a success message to the user.
  void showSuccess(String message, {required BuildContext context}) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: semanticColors?.success ?? Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an informational message to the user.
  void showInfo(String message, {required BuildContext context}) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: semanticColors?.info ?? Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Parses error strings into user-friendly localized messages.
  /// Handles Firebase Auth errors and common exceptions.
  String _parseError(String error) {
    final errorLower = error.toLowerCase();

    // Firebase Auth errors
    if (errorLower.contains('email-already-in-use')) {
      return 'errors.auth.email_in_use'.tr();
    }
    if (errorLower.contains('wrong-password') ||
        errorLower.contains('invalid-credential') ||
        errorLower.contains('user-not-found')) {
      return 'errors.auth.invalid_credentials'.tr();
    }
    if (errorLower.contains('weak-password')) {
      return 'errors.auth.weak_password'.tr();
    }
    if (errorLower.contains('invalid-email')) {
      return 'errors.auth.invalid_email'.tr();
    }
    if (errorLower.contains('user-disabled')) {
      return 'errors.auth.account_disabled'.tr();
    }
    if (errorLower.contains('too-many-requests')) {
      return 'errors.auth.too_many_attempts'.tr();
    }

    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('socket')) {
      return 'errors.network'.tr();
    }

    // Permission errors
    if (errorLower.contains('permission-denied') ||
        errorLower.contains('unauthorized')) {
      return 'errors.permission_denied'.tr();
    }

    // Generic fallback
    return 'errors.generic'.tr();
  }

  /// Prints debug messages only in debug mode.
  /// Use this for logging errors without showing to users.
  void printIfDebugMode(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationsHelper] $message');
    }
  }
}
