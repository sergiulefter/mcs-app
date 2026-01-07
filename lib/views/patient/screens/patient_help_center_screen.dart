import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/utils/app_theme.dart';

class PatientHelpCenterScreen extends StatefulWidget {
  const PatientHelpCenterScreen({super.key});

  @override
  State<PatientHelpCenterScreen> createState() =>
      _PatientHelpCenterScreenState();
}

class _PatientHelpCenterScreenState extends State<PatientHelpCenterScreen> {
  // Track which FAQ items are expanded
  final Map<int, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqItems = _buildFaqItems(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Header
              _buildHeader(context),

              // Hero Banner
              _buildHeroBanner(context),

              // Support Options Grid
              _buildSupportOptions(context),

              // FAQ Section
              _buildFaqSection(context, faqItems),

              // Extra padding for bottom navigation
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the sticky header with back button and centered title.
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.slate800 : AppTheme.slate100,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          SizedBox(
            width: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Centered title
          Expanded(
            child: Text(
              'help_center.header_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Spacer for balance
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// Builds the hero banner with primary color background.
  Widget _buildHeroBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing24,
        AppTheme.spacing16,
        AppTheme.spacing8,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacing32),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'help_center.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              'help_center.hero_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the support options grid.
  Widget _buildSupportOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          // Top row: Email + Live Chat
          Row(
            children: [
              // Email Support
              Expanded(
                child: _buildSupportCard(
                  context,
                  icon: Icons.mail_outlined,
                  title: 'help_center.contact_email'.tr(),
                  onTap: () => _showSnack(
                    context,
                    'help_center.contact_email_value'.tr(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              // Live Chat (Coming Soon)
              Expanded(
                child: _buildSupportCard(
                  context,
                  icon: Icons.forum_outlined,
                  title: 'help_center.contact_chat'.tr(),
                  comingSoon: true,
                  onTap: () => _showSnack(context, 'common.coming_soon'.tr()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          // Phone Support (full width)
          _buildPhoneSupportCard(context),
        ],
      ),
    );
  }

  /// Builds a support option card (Email or Live Chat).
  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool comingSoon = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isDark ? AppTheme.slate700 : AppTheme.slate100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Coming Soon badge
              if (comingSoon)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.slate700 : AppTheme.slate100,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusCircular,
                      ),
                    ),
                    child: Text(
                      'common.coming_soon'.tr().toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.slate300 : AppTheme.slate500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              // Card content
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.slate700
                          : colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 22, color: colorScheme.primary),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the phone support card (full width with chevron).
  Widget _buildPhoneSupportCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            _showSnack(context, 'help_center.contact_phone_value'.tr()),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isDark ? AppTheme.slate700 : AppTheme.slate100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.slate700
                      : colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_outlined,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'help_center.contact_phone'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                size: 24,
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the FAQ section with expandable items.
  Widget _buildFaqSection(BuildContext context, List<_FaqItem> faqItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing4,
              vertical: AppTheme.spacing8,
            ),
            child: Text(
              'help_center.faq_title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          ...faqItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildFaqTile(context, item, index);
          }),
        ],
      ),
    );
  }

  /// Builds a single FAQ tile with expand/collapse animation.
  Widget _buildFaqTile(BuildContext context, _FaqItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = _expandedItems[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isExpanded
              ? colorScheme.primary.withValues(alpha: 0.3)
              : (isDark ? AppTheme.slate700 : AppTheme.slate100),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Summary (header)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedItems[index] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.primary.withValues(alpha: 0.2)
                            : colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    // Question text
                    Expanded(
                      child: Text(
                        item.question,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.slate100
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    // Expand icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 24,
                        color: isExpanded
                            ? colorScheme.primary
                            : (isDark ? AppTheme.slate500 : AppTheme.slate400),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Answer (expandable content)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                60, // Align with text after icon
                0,
                AppTheme.spacing16,
                AppTheme.spacing16,
              ),
              child: Text(
                item.answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  List<_FaqItem> _buildFaqItems(BuildContext context) {
    return [
      _FaqItem(
        Icons.post_add_outlined,
        'help_center.faq_request_question'.tr(),
        'help_center.faq_request_answer'.tr(),
      ),
      _FaqItem(
        Icons.upload_file_outlined,
        'help_center.faq_documents_question'.tr(),
        'help_center.faq_documents_answer'.tr(),
      ),
      _FaqItem(
        Icons.timer_outlined,
        'help_center.faq_timeline_question'.tr(),
        'help_center.faq_timeline_answer'.tr(),
      ),
    ];
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _FaqItem {
  final IconData icon;
  final String question;
  final String answer;

  const _FaqItem(this.icon, this.question, this.answer);
}
