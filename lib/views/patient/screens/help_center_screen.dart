import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqItems = _buildFaqItems(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('help_center.title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context),
            const SizedBox(height: AppTheme.sectionSpacing),
            _buildSupportOptions(context),
            const SizedBox(height: AppTheme.sectionSpacing),
            _buildFaqSection(context, faqItems),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
            ),
            child: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
              size: AppTheme.iconXLarge,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'help_center.title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'help_center.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'help_center.contact_title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'help_center.contact_subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SupportOptionCard(
                  icon: Icons.mail_outline,
                  title: 'help_center.contact_email'.tr(),
                  description: 'help_center.contact_email_value'.tr(),
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _showSnack(context, 'help_center.contact_email_value'.tr()),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: _SupportOptionCard(
                  icon: Icons.forum_outlined,
                  title: 'help_center.contact_chat'.tr(),
                  description: 'help_center.contact_chat_desc'.tr(),
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => _showSnack(context, 'help_center.coming_soon'.tr()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        _SupportOptionCard(
          icon: Icons.call_outlined,
          title: 'help_center.contact_phone'.tr(),
          description: 'help_center.contact_phone_value'.tr(),
          color: Theme.of(context).colorScheme.tertiary,
          onTap: () => _showSnack(context, 'help_center.contact_phone_value'.tr()),
          compactRow: true,
        ),
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context, List<_FaqItem> faqItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'help_center.faq_title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        ...faqItems.map((item) => _buildFaqTile(context, item)),
      ],
    );
  }

  Widget _buildFaqTile(BuildContext context, _FaqItem item) {
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
          decoration: BoxDecoration(
            color: isExpanded
                ? colorScheme.primary.withValues(alpha: 0.06)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isExpanded
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : Theme.of(context).dividerColor,
            ),
          ),
          // Remove ExpansionTile's default divider since we use a custom border
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              onExpansionChanged: (expanded) => setState(() => isExpanded = expanded),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing20,
                vertical: AppTheme.spacing12,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppTheme.spacing20,
                0,
                AppTheme.spacing20,
                AppTheme.spacing20,
              ),
              trailing: AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.chevron_right,
                  color: isExpanded
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                item.question,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isExpanded
                          ? colorScheme.primary
                          : Theme.of(context).textTheme.titleMedium?.color,
                    ),
              ),
              children: [
                Text(
                  item.answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_FaqItem> _buildFaqItems(BuildContext context) {
    return [
      _FaqItem(
        'help_center.faq_request_question'.tr(),
        'help_center.faq_request_answer'.tr(),
      ),
      _FaqItem(
        'help_center.faq_documents_question'.tr(),
        'help_center.faq_documents_answer'.tr(),
      ),
      _FaqItem(
        'help_center.faq_timeline_question'.tr(),
        'help_center.faq_timeline_answer'.tr(),
      ),
      _FaqItem(
        'help_center.faq_profile_question'.tr(),
        'help_center.faq_profile_answer'.tr(),
      ),
    ];
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SupportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool compactRow;

  const _SupportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.compactRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final rowLayout = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
          ),
          child: Icon(
            icon,
            color: color,
            size: AppTheme.iconMedium,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                softWrap: false,
              ),
            ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );

    final columnLayout = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppTheme.iconMedium,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: compactRow ? rowLayout : columnLayout,
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}
