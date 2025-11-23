import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/consultation_model.dart';
import '../../../utils/app_theme.dart';
import '../consultation_card.dart';
import '../onboarding_card.dart';
import '../quick_action_card.dart';
import '../stat_card.dart';

class HomeWelcomeHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final VoidCallback onNotificationsTap;

  const HomeWelcomeHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'home.welcome_subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Material(
          shape: const CircleBorder(),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'home.notifications'.tr(),
            onPressed: onNotificationsTap,
          ),
        ),
      ],
    );
  }
}

class ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;

  const ProfileCompletionBanner({
    super.key,
    required this.onCompleteProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sectionSpacing),
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.tertiary,
                size: AppTheme.iconMedium,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'home.profile_incomplete'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'home.profile_incomplete_desc'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCompleteProfile,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.tertiary),
                foregroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: Text('home.complete_profile_button'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeStatsSection extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final int completedCount;

  const HomeStatsSection({
    super.key,
    required this.totalCount,
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppTheme.spacing12;
        final cardWidth =
            (constraints.maxWidth - (spacing * 2)) / 3; // three cards + two gaps

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home.your_stats'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    icon: Icons.assignment_outlined,
                    value: '$totalCount',
                    label: 'home.total_consultations'.tr(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    icon: Icons.pending_actions_outlined,
                    value: '$pendingCount',
                    label: 'home.pending_requests'.tr(),
                    color: Theme.of(context).extension<AppSemanticColors>()!.warning,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    value: '$completedCount',
                    label: 'home.completed'.tr(),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onHelpCenterTap;

  const HomeQuickActions({
    super.key,
    required this.onHelpCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.quick_actions'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.help_outline,
                  title: 'home.help_center'.tr(),
                  description: 'home.help_center_desc'.tr(),
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: onHelpCenterTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActiveConsultationsSection extends StatelessWidget {
  final List<ConsultationModel> activeConsultations;
  final VoidCallback? onViewAll;
  final ValueChanged<ConsultationModel> onConsultationTap;
  final VoidCallback? onEmptyActionTap;

  const ActiveConsultationsSection({
    super.key,
    required this.activeConsultations,
    required this.onConsultationTap,
    this.onViewAll,
    this.onEmptyActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasConsultations = activeConsultations.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.active_consultations'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (hasConsultations && onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Text('home.view_all'.tr()),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),

        if (!hasConsultations)
          OnboardingCard(
            icon: Icons.assignment_outlined,
            title: 'home.no_active_consultations'.tr(),
            description: 'home.no_active_consultations_desc'.tr(),
            actionText: 'home.learn_how'.tr(),
            onActionTap: onEmptyActionTap,
          )
        else
          Column(
            children: activeConsultations.map((consultation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                child: ConsultationCard(
                  consultation: consultation,
                  onTap: () => onConsultationTap(consultation),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class MedicalDisclaimerCard extends StatelessWidget {
  const MedicalDisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: AppTheme.iconSmall,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              'home.medical_disclaimer'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
