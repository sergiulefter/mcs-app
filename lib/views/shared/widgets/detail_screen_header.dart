import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A reusable sticky header for detail screens.
/// Matches the HTML/CSS design with frosted glass effect.
class DetailScreenHeader extends StatelessWidget {
  const DetailScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing4,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withValues(alpha: 0.95)
            : AppTheme.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.slate800 : AppTheme.slate100,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          _buildBackButton(context),

          // Title (centered)
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: isDark ? Colors.white : AppTheme.slate900,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Trailing widget or empty spacer for balance
          trailing ?? const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBack ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : AppTheme.slate800,
          ),
        ),
      ),
    );
  }
}
