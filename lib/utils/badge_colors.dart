import 'package:flutter/material.dart';

/// Theme extension for consultation badge colors.
///
/// Provides muted, professional color palettes for status and urgency badges
/// with proper WCAG AA contrast ratios in both light and dark modes.
class AppBadgeColors extends ThemeExtension<AppBadgeColors> {
  const AppBadgeColors({
    required this.neutralText,
    required this.neutralBg,
    required this.accentText,
    required this.accentBg,
    required this.successText,
    required this.successBg,
    required this.errorText,
    required this.errorBg,
  });

  /// Neutral category - for in-progress states (in_review)
  final Color neutralText;
  final Color neutralBg;

  /// Accent category - for attention/action needed (pending, info_requested, priority)
  final Color accentText;
  final Color accentBg;

  /// Success category - for positive terminal state (completed)
  final Color successText;
  final Color successBg;

  /// Error category - for negative terminal state (cancelled)
  final Color errorText;
  final Color errorBg;

  /// Light mode colors - Very muted, desaturated tones
  static const light = AppBadgeColors(
    // Neutral (Gray) - barely tinted
    neutralText: Color(0xFF6B7280), // Gray 500
    neutralBg: Color(0xFFF3F4F6), // Gray 100
    // Accent (Muted amber/brown) - desaturated warm tone
    accentText: Color(0xFF92702D), // Desaturated amber
    accentBg: Color(0xFFF5F3EF), // Warm gray tint
    // Success (Muted green) - desaturated sage
    successText: Color(0xFF4D7C5B), // Desaturated sage green
    successBg: Color(0xFFEFF3F0), // Very subtle green tint
    // Error (Muted red) - desaturated burgundy
    errorText: Color(0xFF8B5A5A), // Desaturated burgundy
    errorBg: Color(0xFFF5F0F0), // Very subtle pink tint
  );

  /// Dark mode colors - muted, desaturated tones for dark backgrounds
  static const dark = AppBadgeColors(
    // Neutral (Gray) - subtle
    neutralText: Color(0xFF9CA3AF), // Gray 400
    neutralBg: Color(0xFF2D3239), // Dark gray
    // Accent (Muted amber) - desaturated warm tone
    accentText: Color(0xFFCDB87D), // Desaturated gold
    accentBg: Color(0xFF3A3630), // Dark warm gray
    // Success (Muted green) - desaturated sage
    successText: Color(0xFF8BAF96), // Desaturated sage
    successBg: Color(0xFF2D3530), // Dark green-gray
    // Error (Muted red) - desaturated dusty rose
    errorText: Color(0xFFBF9494), // Desaturated dusty rose
    errorBg: Color(0xFF3A3030), // Dark red-gray
  );

  /// Get colors and icon for a consultation status
  ({Color text, Color bg, IconData icon}) forStatus(String status) {
    switch (status) {
      case 'pending':
        return (text: accentText, bg: accentBg, icon: Icons.schedule_outlined);
      case 'in_review':
        return (
          text: neutralText,
          bg: neutralBg,
          icon: Icons.visibility_outlined
        );
      case 'info_requested':
        return (text: accentText, bg: accentBg, icon: Icons.help_outline);
      case 'completed':
        return (
          text: successText,
          bg: successBg,
          icon: Icons.check_circle_outline
        );
      case 'cancelled':
        return (text: errorText, bg: errorBg, icon: Icons.cancel_outlined);
      default:
        return (text: neutralText, bg: neutralBg, icon: Icons.circle_outlined);
    }
  }

  /// Get colors and icon for urgency level
  /// Returns null for 'standard' urgency (should not be displayed)
  ({Color text, Color bg, IconData icon})? forUrgency(String urgency) {
    switch (urgency) {
      case 'priority':
        return (text: accentText, bg: accentBg, icon: Icons.bolt);
      default:
        return null; // Standard urgency - don't show badge
    }
  }

  @override
  AppBadgeColors copyWith({
    Color? neutralText,
    Color? neutralBg,
    Color? accentText,
    Color? accentBg,
    Color? successText,
    Color? successBg,
    Color? errorText,
    Color? errorBg,
  }) {
    return AppBadgeColors(
      neutralText: neutralText ?? this.neutralText,
      neutralBg: neutralBg ?? this.neutralBg,
      accentText: accentText ?? this.accentText,
      accentBg: accentBg ?? this.accentBg,
      successText: successText ?? this.successText,
      successBg: successBg ?? this.successBg,
      errorText: errorText ?? this.errorText,
      errorBg: errorBg ?? this.errorBg,
    );
  }

  @override
  AppBadgeColors lerp(ThemeExtension<AppBadgeColors>? other, double t) {
    if (other is! AppBadgeColors) return this;
    return AppBadgeColors(
      neutralText: Color.lerp(neutralText, other.neutralText, t)!,
      neutralBg: Color.lerp(neutralBg, other.neutralBg, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentBg: Color.lerp(accentBg, other.accentBg, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
    );
  }
}
