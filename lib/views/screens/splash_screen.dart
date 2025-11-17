import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

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
    // Minimum splash duration for professional appearance
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Check if onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return;

    // Check authentication status and navigate
    _navigateToNextScreen(onboardingCompleted);
  }

  void _navigateToNextScreen(bool onboardingCompleted) {
    final authController = context.read<AuthController>();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // If user is authenticated, go directly to MainShell
          if (authController.isAuthenticated) {
            return const MainShell();
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
