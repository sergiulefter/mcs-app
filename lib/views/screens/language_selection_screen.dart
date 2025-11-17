import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_theme.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    // Pre-select based on device locale or current app locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectInitialLanguage();
    });
  }

  void _detectInitialLanguage() {
    // Get device locale
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = deviceLocale.languageCode;

    // If device language is Romanian, pre-select Romanian
    if (languageCode == 'ro') {
      setState(() {
        _selectedLanguage = 'ro';
      });
      context.setLocale(const Locale('ro'));
    } else {
      // Default to English for all other languages
      setState(() {
        _selectedLanguage = 'en';
      });
      context.setLocale(const Locale('en'));
    }
  }

  void _selectLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
    context.setLocale(Locale(languageCode));
  }

  Future<void> _continueToOnboarding() async {
    // Save that language has been selected
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);

    if (!mounted) return;

    // Navigate to Onboarding screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing32,
            vertical: AppTheme.spacing24,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Header section
              _buildHeader(),

              const SizedBox(height: AppTheme.spacing48),

              // Language options
              _buildLanguageOptions(),

              const Spacer(flex: 3),

              // Continue button
              _buildContinueButton(),

              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: const Icon(
            Icons.language_outlined,
            size: 56,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: AppTheme.spacing32),

        // Title
        Text(
          'language_selection.title'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing12),

        // Subtitle
        Text(
          'language_selection.subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLanguageOptions() {
    return Column(
      children: [
        // Romanian option
        _buildLanguageCard(
          languageCode: 'ro',
          languageName: 'language_selection.romanian'.tr(),
          flagEmoji: '🇷🇴',
        ),
        const SizedBox(height: AppTheme.spacing16),

        // English option
        _buildLanguageCard(
          languageCode: 'en',
          languageName: 'language_selection.english'.tr(),
          flagEmoji: '🇬🇧',
        ),
      ],
    );
  }

  Widget _buildLanguageCard({
    required String languageCode,
    required String languageName,
    required String flagEmoji,
  }) {
    final isSelected = _selectedLanguage == languageCode;

    return InkWell(
      onTap: () => _selectLanguage(languageCode),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.05)
              : AppTheme.backgroundWhite,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            // Flag
            Text(
              flagEmoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: AppTheme.spacing16),

            // Language name
            Expanded(
              child: Text(
                languageName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),

            // Check icon for selected
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                ),
                child: const Icon(
                  Icons.check,
                  size: 18,
                  color: AppTheme.textOnPrimary,
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continueToOnboarding,
        child: Text('language_selection.continue_button'.tr()),
      ),
    );
  }
}
