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

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDuz0QEJo_kUQjoIu78pGQcIw7tggGXp0AcJgxmxPGQskK7L2ZQS2ruYt4DCfcXRri9h2vlo-YDwOseOo-vd8Z7x9AHj3T3PdPSFUKwlk9ppeLiFVeye76ANtT7kj67W4aToEGm0LvACwfpS1KvRZFAUuMiAyXWZtMq4d184lwsw6emh4fqOS2b_qNTs6fmsx1Uj2G4_bWmG29cjSCmfex07S37Odru58d97O4ZpLIQsAHLH1mXNObkrLyx-eQc23Oe0h83SO1ebVtc',
      title: 'Find Top Specialists',
      description:
          'Browse verified doctors by specialty. View profiles, experience, and availability instantly.',
      badgeIcon: Icons.verified,
      badgeTitle: 'Top Specialists',
      badgeSubtitle: 'Verified Profiles',
      badgeColor: AppTheme.primaryBlue,
      accentColor: AppTheme.primaryBlue,
    ),
    OnboardingSlide(
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDtRyf2N6CjPY_-h-hDuQjiZVeOS70nHSChN0fGmrpmocSamayyHfHAo9sl3n8hGmvALdMYfvlGh_Du6D1FdXCX-43aRdCV0wRAUOGKmzO2db1pJIKFnK-j0tUFLKXKP9JZxz2LaT-lZ3NbXy2tH7NOVCNmOw4nscodht9rkTYqAzNmhLW6ggKDb2pWjyO27MyDbImcp_CXETUalUOrJFzmjOHR_W38Lwkg2LBPQykscFaNadzri7uNRCAZAGIhCbFIrb4JrTGJqo6t',
      title: 'Consult Anytime',
      description:
          'No appointments needed. Submit your symptoms and medical questions asynchronously, 24/7.',
      badgeIcon: Icons.forum,
      badgeTitle: 'Consult Anytime',
      badgeSubtitle: 'Async Support 24/7',
      badgeColor: AppTheme.warningOrange, // Coral/Orange accent
      accentColor: AppTheme.warningOrange,
    ),
    OnboardingSlide(
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBRQDu3ruKAc7WNAWcxbRt5tJO16ef7NhkxJjZ7kUr-wFxaJh8boJxM5taI7AmsUkBuWvumLdQN4LqxuZY4kKANqKY-B623COu2ZYk-lDSQXkqR7r-uQWjr6cOW16eY8x0CWqUaB8Q8GrjU997IHlWLP-KwL_zzRxnuSyG2fXt3wp2Fx58lwlq-mvgJxtruK_9m98uRfwOoPmVke45EwfyW6qBNFjPASmgnXm6Pu3uLNfsDEX3TYs1w12QM7oYO0FnsGT4Akbs7vaTJ',
      title: 'Get Expert Treatment',
      description:
          'Receive detailed medical advice, prescriptions, and follow-up care directly in the app.',
      badgeIcon: Icons.medical_services,
      badgeTitle: 'Expert Care',
      badgeSubtitle: 'Rx & Follow-up',
      badgeColor: AppTheme.successGreen, // Emerald accent
      accentColor: AppTheme.successGreen,
    ),
  ];

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
                        // Image
                        Image.network(
                          slide.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
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
  final String imageUrl;
  final String title;
  final String description;
  final IconData badgeIcon;
  final String badgeTitle;
  final String badgeSubtitle;
  final Color badgeColor;
  final Color accentColor;

  OnboardingSlide({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.badgeIcon,
    required this.badgeTitle,
    required this.badgeSubtitle,
    required this.badgeColor,
    required this.accentColor,
  });
}
