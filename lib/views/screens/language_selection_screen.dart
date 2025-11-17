import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_theme.dart';
import '../widgets/language_selection_card.dart';
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
          padding: AppTheme.screenPadding,
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
        const SizedBox(height: AppTheme.sectionSpacing),

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
        LanguageSelectionCard(
          languageCode: 'ro',
          languageName: 'language_selection.romanian'.tr(),
          isSelected: _selectedLanguage == 'ro',
          onTap: () => _selectLanguage('ro'),
        ),
        const SizedBox(height: AppTheme.spacing16),
        LanguageSelectionCard(
          languageCode: 'en',
          languageName: 'language_selection.english'.tr(),
          isSelected: _selectedLanguage == 'en',
          onTap: () => _selectLanguage('en'),
        ),
      ],
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
