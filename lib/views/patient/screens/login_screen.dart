import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/validators.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:mcs_app/views/admin/screens/admin_dashboard_screen.dart';
import 'package:mcs_app/views/doctor/screens/doctor_main_shell.dart';
import 'signup_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPrefetching = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authController = context.read<AuthController>();
      final consultationsController = context.read<ConsultationsController>();

      final success = await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        setState(() => _isPrefetching = true);

        final user = authController.currentUser;
        final userId = user?.uid;

        // Only prefetch consultations for patients (not doctors/admins)
        if (userId != null && user?.isDoctor != true && user?.userType != 'admin') {
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainShell()),
          );
        }

        if (mounted) {
          setState(() => _isPrefetching = false);
        }
      } else if (mounted) {
        setState(() => _isPrefetching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Login failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppTheme.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  _buildHeader(),
                  const SizedBox(height: AppTheme.spacing48),

                  // Login Form
                  _buildEmailField(),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildPasswordField(),
                  const SizedBox(height: AppTheme.spacing8),

                  // Forgot Password
                  _buildForgotPassword(),
                  const SizedBox(height: AppTheme.sectionSpacing),

                  // Sign In Button
                  _buildSignInButton(),
                  const SizedBox(height: AppTheme.spacing24),

                  // Sign Up Link
                  _buildSignUpLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            size: AppTheme.iconXLarge,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Title
        Text(
          'auth.sign_in'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),

        // Subtitle
        Text(
          'auth.sign_in_subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return AppTextField(
      label: 'auth.email'.tr(),
      hintText: 'auth.email_hint'.tr(),
      controller: _emailController,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: Validators.validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return AppTextField(
      label: 'auth.password'.tr(),
      hintText: 'auth.password_hint'.tr(),
      controller: _passwordController,
      prefixIcon: Icons.lock_outlined,
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
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implement forgot password
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing8,
            vertical: AppTheme.spacing4,
          ),
        ),
        child: Text(
          'auth.forgot_password'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return ElevatedButton(
          onPressed:
              (authController.isLoading || _isPrefetching) ? null : _handleLogin,
          child: (authController.isLoading || _isPrefetching)
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text('auth.sign_in'.tr()),
        );
      },
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'auth.no_account'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
          child: Text('auth.sign_up'.tr()),
        ),
      ],
    );
  }
}
