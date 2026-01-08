import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingSlide> get _slides {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return [
      OnboardingSlide(
        imagePath: 'assets/images/onboarding/find_specialists.jpg',
        title: 'Find Top Specialists',
        description:
            'Browse verified doctors by specialty. View profiles, experience, and availability instantly.',
        badgeIcon: Icons.verified,
        badgeTitle: 'Top Specialists',
        badgeSubtitle: 'Verified Profiles',
        badgeColor: primary,
        accentColor: primary,
      ),
      OnboardingSlide(
        imagePath: 'assets/images/onboarding/consult_anytime.jpg',
        title: 'Consult Anytime',
        description:
            'No appointments needed. Submit your symptoms and medical questions asynchronously, 24/7.',
        badgeIcon: Icons.forum,
        badgeTitle: 'Consult Anytime',
        badgeSubtitle: 'Async Support 24/7',
        badgeColor: semantic.warning,
        accentColor: semantic.warning,
      ),
      OnboardingSlide(
        imagePath: 'assets/images/onboarding/expert_treatment.jpg',
        title: 'Get Expert Treatment',
        description:
            'Receive detailed medical advice, prescriptions, and follow-up care directly in the app.',
        badgeIcon: Icons.medical_services,
        badgeTitle: 'Expert Care',
        badgeSubtitle: 'Rx & Follow-up',
        badgeColor: semantic.success,
        accentColor: semantic.success,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!prefs.containsKey('theme_mode')) {
      await prefs.setString('theme_mode', 'system');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            _buildSkipButton(),

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

            // Page indicator and next button
            _buildBottomSection(),
            const SizedBox(height: AppTheme.spacing24),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing16,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _completeOnboarding,
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: AppTheme.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded-xl
            ),
          ),
          child: Text(
            'common.skip'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacing8),
            // Image Card
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Shadow/Glow effect at bottom
                Positioned(
                  bottom: -24,
                  left: 20,
                  right: 20,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: slide.accentColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Card
                AspectRatio(
                  aspectRatio: 1.0, // Square as per design
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32), // Rounded-[2rem]
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image (local asset - loads instantly)
                        Image.asset(
                          slide.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              ),
                        ),

                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Floating Badge
                        Positioned(
                          bottom: 24,
                          left: 24,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: slide.badgeColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    slide.badgeIcon,
                                    color: slide.badgeColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slide.badgeTitle,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      slide.badgeSubtitle,
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),

                        // Status Dot on Badge (Top Right)
                        Positioned(
                          bottom:
                              74, // badge height (approx 70) + bottom pos (24) - offset
                          left: 24 + 200, // badge width approx
                          child: Container(
                            // This positioning is brittle, better to put it inside the badge stack if possible
                            // But for now matching visual simplified
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing32),

            // Text Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Text(
                    slide.title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    slide.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
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
          const SizedBox(height: 32),

          // Next / Get Started button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _slides.length - 1
                        ? 'onboarding.get_started'.tr()
                        : 'common.next'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor, // Slate 200 equivalent
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

class OnboardingSlide {
  final String imagePath;
  final String title;
  final String description;
  final IconData badgeIcon;
  final String badgeTitle;
  final String badgeSubtitle;
  final Color badgeColor;
  final Color accentColor;

  OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.badgeIcon,
    required this.badgeTitle,
    required this.badgeSubtitle,
    required this.badgeColor,
    required this.accentColor,
  });
}
