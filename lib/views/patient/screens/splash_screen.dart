import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/admin/screens/admin_dashboard_screen.dart';
import 'package:mcs_app/views/doctor/screens/doctor_main_shell.dart';
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
  bool _showLoadingUi = false;

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
      await _waitForAuthState(authController);

      if (!mounted) return;

      if (authController.isAuthenticated) {
        setState(() {
          _showLoadingUi = true;
        });
      }

      // Check preferences for language selection and onboarding
      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      if (authController.isAuthenticated) {
        // Check user type for role-based routing
        final user = authController.currentUser;

        if (user?.userType == 'admin') {
          // Admin users go to admin dashboard
          if (!mounted) return;
          _navigateToAdminDashboard();
        } else if (user?.isDoctor == true) {
          // Doctor users go to doctor portal
          if (!mounted) return;
          _navigateToDoctorShell();
        } else {
          // Patient users go to main shell
          await _primeUserData(authController);
          if (!mounted) return;
          _navigateToMainShell();
        }
      } else {
        _navigateToAuthFlow(languageSelected, onboardingCompleted);
      }
    } catch (e) {
      // If Firebase fails to initialize, still show the app
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      if (!mounted) return;
      _navigateToAuthFlow(languageSelected, onboardingCompleted);
    }
  }

  // Wait for auth state to be initialized (checks if Firebase has determined auth status)
  Future<void> _waitForAuthState(AuthController authController) async {
    while (!authController.authStateInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _primeUserData(AuthController authController) async {
    final userId = authController.currentUser?.uid;
    if (userId == null) return;
    final consultationsController = context.read<ConsultationsController>();
    await consultationsController.primeForUser(userId, force: true);
  }

  void _navigateToMainShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
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

  void _navigateToAdminDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AdminDashboardScreen(),
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

  void _navigateToDoctorShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DoctorMainShell(),
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

  void _navigateToAuthFlow(bool languageSelected, bool onboardingCompleted) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
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
    if (!_showLoadingUi) {
      // For unauthenticated users we skip the dynamic splash; show a blank canvas while routing.
      return Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      );
    }

    return Scaffold(
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
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Icon(
        Icons.medical_services_outlined,
        size: 56,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAppName() {
    return Text(
      AppConstants.appName,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
    );
  }

  Widget _buildAppDescription() {
    return Text(
      AppConstants.appDescription,
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Text(
          'Loading...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
