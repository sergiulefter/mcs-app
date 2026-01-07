import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Sender type for timeline messages
enum TimelineMessageSender { doctor, patient }

/// A reusable timeline message bubble widget for conversation-style displays.
/// Matches the HTML/CSS design with avatar, message card, and timestamp.
class TimelineMessage extends StatelessWidget {
  const TimelineMessage({
    super.key,
    required this.sender,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.avatarUrl,
    this.isWaiting = false,
  });

  final TimelineMessageSender sender;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final String? avatarUrl;
  final bool isWaiting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors based on sender
    final isDoctor = sender == TimelineMessageSender.doctor;
    final avatarBgColor = isDoctor
        ? colorScheme.primary
        : (isDark ? AppTheme.slate700 : AppTheme.slate200);
    final avatarIconColor = isDoctor ? Colors.white : null;
    final messageBgColor = isDoctor
        ? (isDark ? AppTheme.surfaceDark : Colors.white)
        : (isDark
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.primary.withValues(alpha: 0.08));
    final messageBorderColor = isDoctor
        ? (isDark ? AppTheme.slate700 : AppTheme.slate100)
        : (isDark
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.2));
    final nameColor = isDoctor ? colorScheme.primary : colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar (40px matching design)
        _buildAvatar(
          context,
          isDoctor: isDoctor,
          bgColor: avatarBgColor,
          iconColor: avatarIconColor,
        ),
        const SizedBox(width: AppTheme.spacing12),

        // Message bubble
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: messageBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero, // Pointer effect
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: messageBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: name and timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      senderName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: nameColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTime(timestamp),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing8),

                // Message text
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.slate200 : AppTheme.slate800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(
    BuildContext context, {
    required bool isDoctor,
    required Color bgColor,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If we have an avatar URL, show image
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppTheme.backgroundDark : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(
              context,
              bgColor: bgColor,
              iconColor: iconColor,
              isDoctor: isDoctor,
            ),
          ),
        ),
      );
    }

    return _buildInitialsAvatar(
      context,
      bgColor: bgColor,
      iconColor: iconColor,
      isDoctor: isDoctor,
    );
  }

  Widget _buildInitialsAvatar(
    BuildContext context, {
    required Color bgColor,
    Color? iconColor,
    required bool isDoctor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(
          color: isDark ? AppTheme.backgroundDark : Colors.white,
          width: 2,
        ),
        boxShadow: isDoctor
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isDoctor
            ? Icon(
                Icons.medical_services,
                size: 18,
                color: iconColor ?? Colors.white,
              )
            : Text(
                _getInitials(senderName),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDark ? AppTheme.slate300 : AppTheme.slate600,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}

/// A waiting indicator shown at the end of the timeline
class TimelineWaitingIndicator extends StatelessWidget {
  const TimelineWaitingIndicator({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: 0.6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Waiting avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppTheme.slate800 : Colors.white,
              border: Border.all(
                color: isDark ? AppTheme.slate600 : AppTheme.slate200,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.more_horiz,
                size: 18,
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),

          // Waiting text
          Expanded(
            child: Container(
              height: 40,
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
