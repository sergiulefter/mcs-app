import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/validators.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'complete_profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Inline error messages from Firebase auth
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // Clear previous auth errors before validation
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      final authController = context.read<AuthController>();

      // Get the current language from EasyLocalization (set in LanguageSelectionScreen)
      final currentLanguage = context.locale.languageCode;

      final success = await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        preferredLanguage: currentLanguage,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
        );
      } else if (mounted) {
        // Map Firebase error to appropriate field
        final errorCode = authController.errorCode;
        final errorMessage = authController.errorMessage ?? 'errors.signup_failed'.tr();

        setState(() {
          if (errorCode == 'email-already-in-use' || errorCode == 'invalid-email') {
            _emailError = errorMessage;
          } else if (errorCode == 'weak-password') {
            _passwordError = errorMessage;
          } else {
            // For other errors, show under email field as general error
            _emailError = errorMessage;
          }
        });

        // Trigger form revalidation to show the inline error
        _formKey.currentState!.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
            padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button
                _buildBackButton(),
                const SizedBox(height: AppTheme.spacing16),

                // App Branding
                _buildHeader(),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Signup Form
                AppTextField(
                  label: 'common.full_name'.tr(),
                  hintText: 'auth.name_hint'.tr(),
                  controller: _nameController,
                  prefixIcon: Icons.person_outlined,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: AppTheme.spacing16),

                AppTextField(
                  label: 'common.email'.tr(),
                  hintText: 'auth.email_hint'.tr(),
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (_emailError != null) return _emailError;
                    return Validators.validateEmail(value);
                  },
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                _buildPasswordField(),
                const SizedBox(height: AppTheme.spacing16),

                _buildConfirmPasswordField(),
                const SizedBox(height: AppTheme.sectionSpacing),

                // Sign Up Button
                _buildSignUpButton(),
                const SizedBox(height: AppTheme.spacing24),

                // Sign In Link
                _buildSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(AppTheme.spacing12),
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
          child: Icon(
            Icons.medical_services_outlined,
            size: AppTheme.iconXLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Title
        Text(
          'auth.sign_up'.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),

        // Subtitle
        Text(
          'auth.sign_up_subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.password'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
          decoration: InputDecoration(
            hintText: 'auth.create_password_hint'.tr(),
            prefixIcon: const Icon(
              Icons.lock_outlined,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (_passwordError != null) return _passwordError;
            return Validators.validatePassword(value);
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.confirm_password'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSignup(),
          decoration: InputDecoration(
            hintText: 'auth.confirm_password_hint'.tr(),
            prefixIcon: const Icon(
              Icons.lock_outlined,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) => Validators.validateConfirmPassword(
            value,
            _passwordController.text,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return ElevatedButton(
          onPressed: authController.isLoading ? null : _handleSignup,
          child: authController.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text('auth.sign_up'.tr()),
        );
      },
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'auth.have_account'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('auth.sign_in'.tr()),
        ),
      ],
    );
  }
}
