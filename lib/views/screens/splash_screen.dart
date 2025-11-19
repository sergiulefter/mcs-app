import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final Future<FirebaseApp> firebaseInitialization;

  const SplashScreen({super.key, required this.firebaseInitialization});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for Firebase to initialize (non-blocking from main)
      await widget.firebaseInitialization;

      if (!mounted) return;

      // Wait for AuthController to receive initial auth state from Firebase
      final authController = context.read<AuthController>();

      // Wait for auth state to be initialized
      // Shows loading UI while Firebase checks for existing session
      await Future.any([
        Future.delayed(const Duration(seconds: 3)), // Max 3 seconds timeout
        _waitForAuthState(authController),
      ]);

      if (!mounted) return;

      // Check preferences for language selection and onboarding
      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      // Navigate to appropriate screen based on auth state
      _navigateToNextScreen(languageSelected, onboardingCompleted);
    } catch (e) {
      // If Firebase fails to initialize, still show the app
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      if (!mounted) return;
      _navigateToNextScreen(languageSelected, onboardingCompleted);
    }
  }

  // Wait for auth state to be initialized (checks if Firebase has determined auth status)
  Future<void> _waitForAuthState(AuthController authController) async {
    // If auth state has been initialized, return immediately
    if (authController.authStateInitialized) {
      return;
    }

    // Otherwise wait briefly and check again
    await Future.delayed(const Duration(milliseconds: 100));
    return _waitForAuthState(authController);
  }

  void _navigateToNextScreen(bool languageSelected, bool onboardingCompleted) {
    final authController = context.read<AuthController>();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // If user is authenticated, go directly to MainShell
          if (authController.isAuthenticated) {
            return const MainShell();
          }

          // If language not selected, show language selection first
          if (!languageSelected) {
            return const LanguageSelectionScreen();
          }

          // If onboarding not completed, show onboarding
          if (!onboardingCompleted) {
            return const OnboardingScreen();
          }

          // Otherwise, show login
          return const LoginScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: AppConstants.mediumDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Main content - centered
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAppIcon(),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildAppName(),
                    const SizedBox(height: AppTheme.spacing8),
                    _buildAppDescription(),
                  ],
                ),
              ),
            ),

            // Loading indicator at bottom
            _buildLoadingIndicator(),
            const SizedBox(height: AppTheme.spacing48),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: const Icon(
        Icons.medical_services_outlined,
        size: 56,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildAppName() {
    return Text(
      AppConstants.appName,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
    );
  }

  Widget _buildAppDescription() {
    return Text(
      AppConstants.appDescription,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: AppTheme.dividerColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue,
            ),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          'Loading...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
        ),
      ],
    );
  }
}
