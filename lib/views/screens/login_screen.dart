import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/validators.dart';
import '../../utils/app_theme.dart';
import '../widgets/app_text_field.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authController = context.read<AuthController>();

      final success = await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Login failed'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
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
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            size: AppTheme.iconXLarge,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Title
        Text(
          'auth.sign_in'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),

        // Subtitle
        Text(
          'auth.sign_in_subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
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
                color: AppTheme.primaryBlue,
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
          onPressed: authController.isLoading ? null : _handleLogin,
          child: authController.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textOnPrimary,
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
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
