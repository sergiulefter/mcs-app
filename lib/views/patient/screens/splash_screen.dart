import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';

import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/views/admin/screens/admin_dashboard_screen.dart';
import 'package:mcs_app/views/doctor/screens/doctor_main_shell.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';
import 'patient_main_shell.dart';
import 'onboarding_screen.dart';
import 'patient_complete_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  final Future<FirebaseApp> firebaseInitialization;

  const SplashScreen({super.key, required this.firebaseInitialization});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showLoadingUi = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

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

          final navigator = Navigator.of(context);
          final shouldShowCompleteProfile = user?.profileCompleted == false;

          _navigateToMainShell();

          // If profile not completed, push CompleteProfileScreen on top
          if (shouldShowCompleteProfile) {
            // Give user time to see the home screen before prompting to complete profile
            Future.delayed(const Duration(milliseconds: 800), () {
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => const PatientCompleteProfileScreen(),
                ),
              );
            });
          }
        }
      } else {
        _navigateToAuthFlow(languageSelected, onboardingCompleted);
      }
    } catch (e) {
      // If Firebase fails to initialize, still show the app
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
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
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PatientMainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curvedAnimation, child: child);
        },
        transitionDuration: AppConstants.longDuration,
      ),
    );
  }

  void _navigateToAdminDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AdminDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curvedAnimation, child: child);
        },
        transitionDuration: AppConstants.longDuration,
      ),
    );
  }

  void _navigateToDoctorShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DoctorMainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curvedAnimation, child: child);
        },
        transitionDuration: AppConstants.longDuration,
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
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curvedAnimation, child: child);
        },
        transitionDuration: AppConstants.longDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoadingUi) {
      // For unauthenticated users we skip the dynamic splash; show a blank canvas while routing.
      return Scaffold(
        body: Container(color: Theme.of(context).scaffoldBackgroundColor),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Decorative Background Pattern (Subtle Gradient Blobs)
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Center Brand Section
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulse Rings and Icon
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Pulse Ring 2
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 144,
                                height: 144,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(48),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.05),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            // Outer Pulse Ring 1
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            // Main Icon Container
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.monitor_heart_outlined,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Brand Wordmark
                      Text(
                        'MCS',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              height: 1.1,
                              color: isDark ? Colors.white : primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Section: Loading & Meta
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 48,
                  ),
                  child: Column(
                    children: [
                      // Minimal Loading Indicator
                      SizedBox(
                        width: 160,
                        height: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B) // Slate 800
                                : const Color(0xFFF1F5F9), // Slate 100
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Meta Information
                      Text(
                        'Professional Medical Care',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? const Color(0xFF94A3B8) // Slate 400
                              : const Color(0xFF4C669A), // Slate Blue
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'v1.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? const Color(0xFF475569) // Slate 600
                              : const Color(0xFFCBD5E1), // Slate 300
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
