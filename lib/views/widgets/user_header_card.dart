import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_theme.dart';

/// A reusable card widget for displaying user profile header information.
///
/// Shows user avatar (image or initials), display name, email, and account type badge.
/// Designed for use at the top of account/profile screens.
///
/// Example:
/// ```dart
/// UserHeaderCard(
///   displayName: 'John Doe',
///   email: 'john.doe@example.com',
///   userType: 'patient',
/// )
/// ```
class UserHeaderCard extends StatelessWidget {
  /// The user's display name.
  final String displayName;

  /// The user's email address.
  final String email;

  /// Optional: The user's profile photo URL.
  final String? photoUrl;

  /// The user type for the badge (e.g., 'patient', 'doctor').
  final String userType;

  /// Optional: Fallback text if display name is empty.
  final String? fallbackName;

  /// Optional: Avatar size (defaults to 72px).
  final double avatarSize;

  const UserHeaderCard({
    super.key,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.userType = 'patient',
    this.fallbackName,
    this.avatarSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveName = displayName.isNotEmpty
        ? displayName
        : (fallbackName ?? 'account.not_set'.tr());
    final initials = _getInitials(effectiveName);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.08),
            blurRadius: AppTheme.elevationLow,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Initials or Photo
          _buildAvatar(context, initials),
          const SizedBox(width: AppTheme.spacing16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Name
                Text(
                  effectiveName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                // Email
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                // Account Type Badge
                _buildUserTypeBadge(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String initials) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
      child: photoUrl != null
          ? ClipOval(
              child: Image.network(
                photoUrl!,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitials(context, initials);
                },
              ),
            )
          : _buildInitials(context, initials),
    );
  }

  Widget _buildInitials(BuildContext context, String initials) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildUserTypeBadge(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final badgeText = _getBadgeText();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (userType.toLowerCase()) {
      case 'doctor':
        return AppTheme.primaryBlue;
      case 'admin':
        return AppTheme.warningOrange;
      case 'patient':
      default:
        return AppTheme.secondaryGreen;
    }
  }

  String _getBadgeText() {
    switch (userType.toLowerCase()) {
      case 'doctor':
        return 'account.doctor_account'.tr();
      case 'admin':
        return 'account.admin_account'.tr();
      case 'patient':
      default:
        return 'account.patient_account'.tr();
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
