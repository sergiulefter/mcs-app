import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';

/// A modal bottom sheet that explains the consultation process
/// with a carousel-style walkthrough.
class ConsultationGuideSheet extends StatefulWidget {
  const ConsultationGuideSheet({super.key});

  /// Shows the consultation guide as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConsultationGuideSheet(),
    );
  }

  @override
  State<ConsultationGuideSheet> createState() => _ConsultationGuideSheetState();
}

class _ConsultationGuideSheetState extends State<ConsultationGuideSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_GuideSlide> get _slides => [
        _GuideSlide(
          icon: Icons.search_outlined,
          titleKey: 'consultation_guide.slide1_title',
          descriptionKey: 'consultation_guide.slide1_desc',
        ),
        _GuideSlide(
          icon: Icons.person_outlined,
          titleKey: 'consultation_guide.slide2_title',
          descriptionKey: 'consultation_guide.slide2_desc',
        ),
        _GuideSlide(
          icon: Icons.edit_document,
          titleKey: 'consultation_guide.slide3_title',
          descriptionKey: 'consultation_guide.slide3_desc',
        ),
        _GuideSlide(
          icon: Icons.rate_review_outlined,
          titleKey: 'consultation_guide.slide4_title',
          descriptionKey: 'consultation_guide.slide4_desc',
        ),
        _GuideSlide(
          icon: Icons.question_answer_outlined,
          titleKey: 'consultation_guide.slide5_title',
          descriptionKey: 'consultation_guide.slide5_desc',
        ),
        _GuideSlide(
          icon: Icons.check_circle_outlined,
          titleKey: 'consultation_guide.slide6_title',
          descriptionKey: 'consultation_guide.slide6_desc',
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          _buildHandleBar(context),

          // Header with close button
          _buildHeader(context),

          // Page content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildSlide(_slides[index]);
              },
            ),
          ),

          // Bottom section with dots and button
          _buildBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildHandleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'consultation_guide.title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_GuideSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            ),
            child: Icon(
              slide.icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),

          // Title
          Text(
            slide.titleKey.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Description
          Text(
            slide.descriptionKey.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        children: [
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => _buildDot(index),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Next / Got It button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: Text(
                _currentPage == _slides.length - 1
                    ? 'consultation_guide.got_it'.tr()
                    : 'common.next'.tr(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
      ),
    );
  }
}

class _GuideSlide {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  _GuideSlide({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}
