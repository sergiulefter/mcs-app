import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/utils/validators.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:mcs_app/views/admin/screens/admin_dashboard_screen.dart';
import 'package:mcs_app/views/doctor/screens/doctor_main_shell.dart';
import 'signup_screen.dart';
import 'package:mcs_app/views/patient/screens/patient_main_shell.dart';
import 'package:mcs_app/views/shared/widgets/auth/forgot_password_sheet.dart';
import 'package:mcs_app/views/patient/screens/patient_complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollHelper = FormScrollHelper();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPrefetching = false;
  String _selectedRole = 'Patient'; // 'Patient' or 'Doctor'

  // GlobalKeys for scroll-to-error functionality
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();

  @override
  void dispose() {
    _scrollHelper.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous errors before validation
    _scrollHelper.clearErrors();

    if (!_formKey.currentState!.validate()) {
      _scrollHelper.scrollToFirstError(context);
      return;
    }

    final authController = context.read<AuthController>();
    final consultationsController = context.read<ConsultationsController>();

    try {
      await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        expectedRole: _selectedRole.toLowerCase(),
      );

      if (!mounted) return;

      setState(() => _isPrefetching = true);

      final user = authController.currentUser;
      final userId = user?.uid;

      // Only prefetch consultations for patients (not doctors/admins)
      if (userId != null &&
          user?.isDoctor != true &&
          user?.userType != 'admin') {
        await consultationsController.primeForUser(userId, force: true);
      }

      if (!mounted) return;

      // Role-based navigation
      if (user?.userType == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else if (user?.isDoctor == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DoctorMainShell()),
        );
      } else {
        // Patient navigation
        final navigator = Navigator.of(context);
        final shouldShowCompleteProfile = user?.profileCompleted == false;

        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const PatientMainShell()),
        );

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
    } catch (e) {
      if (!mounted) return;
      NotificationsHelper().showError(e.toString(), context: context);
    } finally {
      if (mounted) {
        setState(() => _isPrefetching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Register fields in order for scroll-to-error
    _scrollHelper.register('email', _emailKey);
    _scrollHelper.register('password', _passwordKey);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Text
                Text(
                  'auth.welcome_back'.tr(),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4), // Reduced from 8
                Text(
                  'auth.sign_in_subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20), // Reduced from 24
                // Role Toggle
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    // Slate background
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Sliding background indicator
                      AnimatedAlign(
                        alignment: _selectedRole == 'Patient'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 1),
                                ),
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Role options text
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleToggleOption(
                              'Patient',
                              'auth.role_patient'.tr(),
                            ),
                          ),
                          Expanded(
                            child: _buildRoleToggleOption(
                              'Doctor',
                              'auth.role_doctor'.tr(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Reduced from 24
                // Form Fields
                KeyedSubtree(key: _emailKey, child: _buildEmailField()),
                const SizedBox(height: 12), // Reduced from 16
                KeyedSubtree(key: _passwordKey, child: _buildPasswordField()),
                const SizedBox(height: 4), // Reduced from 8
                // Forgot Password
                _buildForgotPassword(),
                const SizedBox(height: 16),
                // Sign In Button
                _buildSignInButton(),

                const SizedBox(height: 20), // Reduced from 24
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'auth.or_continue_with'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Reduced from 24
                // Social Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        'auth.social_google'.tr(),
                        'assets/icons/google.png',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        'auth.social_apple'.tr(),
                        null,
                        icon: Icons.apple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20), // Reduced from 24
                // Sign Up Link
                _buildSignUpLink(),

                const SizedBox(height: 12), // Reduced from 16
                // Terms
                Text(
                  'auth.terms_agreement'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggleOption(String roleKey, String label) {
    final isSelected = _selectedRole == roleKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleKey;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'common.email'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        AppTextField(
          // label: 'common.email'.tr(), // Label moved outside as per design
          hintText: 'name@example.com',
          controller: _emailController,
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.validateEmail,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'auth.password'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        AppTextField(
          // label: 'auth.password'.tr(),
          hintText: '••••••••',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          suffixIcon: _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixIconTap: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          validator: Validators.validatePassword,
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => ForgotPasswordSheet.show(context),
        child: Text(
          'auth.forgot_password'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: (authController.isLoading || _isPrefetching)
                ? null
                : _handleLogin,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.35),
            ),
            child: (authController.isLoading || _isPrefetching)
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    'auth.sign_in'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSocialButton(String label, String? assetPath, {IconData? icon}) {
    return SizedBox(
      height: 48, // h-12
      child: OutlinedButton(
        onPressed: () {
          // Social login impl
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath != null)
              // Fallback icon since we might not have assets
              // Image.asset(assetPath, width: 20, height: 20)
              // Using generic icons for now to avoid asset errors
              const Icon(Icons.g_mobiledata, size: 24) // Placeholder for Google
            else if (icon != null)
              Icon(icon, size: 20),

            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'auth.no_account'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          child: Text(
            'auth.sign_up'.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
