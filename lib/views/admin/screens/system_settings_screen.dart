import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// Placeholder screen for system settings (Coming Soon).
/// Will include app configuration, maintenance mode, etc.
class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('admin.system_settings.title'.tr()),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Icon(
                    Icons.construction_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Title
                Text(
                  'admin.system_settings.coming_soon_title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing12),

                // Description
                Text(
                  'admin.system_settings.coming_soon_description'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing32),

                // Planned features list
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin.system_settings.planned_features'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      _buildFeatureItem(
                        context,
                        Icons.tune_outlined,
                        'admin.system_settings.feature_app_config'.tr(),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      _buildFeatureItem(
                        context,
                        Icons.engineering_outlined,
                        'admin.system_settings.feature_maintenance'.tr(),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      _buildFeatureItem(
                        context,
                        Icons.notifications_outlined,
                        'admin.system_settings.feature_notifications'.tr(),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      _buildFeatureItem(
                        context,
                        Icons.analytics_outlined,
                        'admin.system_settings.feature_analytics'.tr(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ),
      ],
    );
  }
}
