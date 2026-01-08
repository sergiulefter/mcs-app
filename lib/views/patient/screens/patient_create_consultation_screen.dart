import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/utils/validation/consultation_validator.dart';
import 'package:mcs_app/views/patient/screens/patient_main_shell.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';

class PatientCreateConsultationScreen extends StatefulWidget {
  final DoctorModel doctor;

  const PatientCreateConsultationScreen({super.key, required this.doctor});

  @override
  State<PatientCreateConsultationScreen> createState() =>
      _PatientCreateConsultationScreenState();
}

class _PatientCreateConsultationScreenState
    extends State<PatientCreateConsultationScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scrollHelper = FormScrollHelper();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form data
  String _title = '';
  String _description = '';
  String _urgency = 'normal'; // normal, priority
  bool _termsAccepted = false;

  // Inline error messages
  String? _titleError;
  String? _descriptionError;
  String? _termsError;

  // GlobalKeys for scroll-to-error functionality
  final _titleKey = GlobalKey();
  final _descriptionKey = GlobalKey();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollHelper.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      // Validate current step before proceeding
      if (_currentStep == 0 && !_validateStep1()) {
        return;
      }

      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _validateStep1() {
    // Clear previous errors
    _scrollHelper.clearErrors();
    setState(() {
      _titleError = null;
      _descriptionError = null;
    });

    // Use centralized validator
    final result = ConsultationValidator.validate(
      title: _title,
      description: _description,
      urgency: _urgency,
    );

    if (result.isValid) {
      return true;
    }

    // Map validation errors to UI
    if (result.hasError('title')) {
      setState(() {
        _titleError = result
            .getError('title')!
            .tr(namedArgs: {'min': AppConstants.titleMinLength.toString()});
      });
      _scrollHelper.setError('title');
    }

    if (result.hasError('description')) {
      setState(() {
        _descriptionError = result
            .getError('description')!
            .tr(
              namedArgs: {'min': AppConstants.descriptionMinLength.toString()},
            );
      });
      _scrollHelper.setError('description');
    }

    _scrollHelper.scrollToFirstError(context);
    return false;
  }

  Future<void> _submitRequest() async {
    setState(() {
      _termsError = null;
    });

    if (!_termsAccepted) {
      setState(() {
        _termsError = 'create_request.validation.accept_terms'.tr();
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authController = context.read<AuthController>();
      final consultationsController = context.read<ConsultationsController>();

      if (authController.currentUser == null) {
        throw Exception('No user logged in');
      }

      // Create consultation document
      final now = DateTime.now();
      final consultation = ConsultationModel(
        id: '', // Will be set by Firestore
        patientId: authController.currentUser!.uid,
        doctorId: widget.doctor.uid,
        status: 'pending',
        urgency: _urgency,
        title: _title.trim(),
        description: _description.trim(),
        attachments: [], // MVP: No file upload yet
        createdAt: now,
        updatedAt: now,
        termsAcceptedAt: now,
      );

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('consultations')
          .add(consultation.toFirestore());

      // Refresh consultations list
      await consultationsController.fetchUserConsultations(
        authController.currentUser!.uid,
      );

      if (mounted) {
        // Show success and navigate
        NotificationsHelper().showSuccess(
          'create_request.success_message'.tr(),
          context: context,
        );

        // Navigate to consultations tab with bottom navigation visible
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const PatientMainShell(initialIndex: 2),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        NotificationsHelper().showError(e.toString(), context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for content to allow scrolling behind fixed footer
    // Footer height (80) + Safe Area
    final contentPadding = EdgeInsets.only(
      bottom: 100 + MediaQuery.of(context).padding.bottom,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: Stack(
                children: [
                  // Main Content
                  SingleChildScrollView(
                    padding: AppTheme.screenPadding.add(contentPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStep == 0) _buildStep1(),
                        if (_currentStep == 1) _buildStep2(),
                        if (_currentStep == 2) _buildStep3(),
                      ],
                    ),
                  ),
                  // Fixed Footer
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildFixedFooter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nav Bar Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  onTap: _currentStep > 0
                      ? _previousStep
                      : () => Navigator.of(context).pop(),
                ),
                Text(
                  'create_request.title'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 48), // Balance spacing for centered title
              ],
            ),
          ),
          // Progress Bars
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: List.generate(3, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Step Text
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'create_request.step_indicator'
                  .tr(
                    namedArgs: {'current': '${_currentStep + 1}', 'total': '3'},
                  )
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedFooter() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ), // Extra safe area
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(
                  color: Colors.transparent,
                ), // Borderless look like HTML design
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : (_currentStep == 2 ? _submitRequest : _nextStep),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: colorScheme.primary.withValues(alpha: 0.3),
              ),
              icon: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const SizedBox.shrink(), // Icon handled in label usually, but HTML has trailing arrow
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getButtonLabel(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isSubmitting && _currentStep < 2) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonLabel() {
    if (_isSubmitting) return 'common.loading'.tr();
    if (_currentStep == 2) return 'create_request.submit_button'.tr();
    return 'common.next'
        .tr(); // "Next Step" in HTML, using "Next" for now or add key
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  // Step 1: Request Details
  Widget _buildStep1() {
    // Register fields in order for scroll-to-error
    _scrollHelper.register('title', _titleKey);
    _scrollHelper.register('description', _descriptionKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description (HTML: "Request Details")
        const SizedBox(height: 24),
        Text(
          'create_request.step1.main_title'.tr(), // "Request Details"
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'create_request.step1.main_subtitle'
              .tr(), // "Please describe your symptoms..."
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              KeyedSubtree(
                key: _titleKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'create_request.step1.title_label'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      maxLength: AppConstants.titleMaxLength,
                      onChanged: (value) {
                        setState(() {
                          _title = value;
                          if (_titleError != null) _titleError = null;
                        });
                      },
                      decoration: _getInputDecoration(
                        hint: 'create_request.step1.title_hint'.tr(),
                        error: _titleError,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description Field
              KeyedSubtree(
                key: _descriptionKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'create_request.step1.description_label'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLength: AppConstants.descriptionMaxLength,
                      maxLines: 5,
                      onChanged: (value) {
                        setState(() {
                          _description = value;
                          if (_descriptionError != null) {
                            _descriptionError = null;
                          }
                        });
                      },
                      decoration: _getInputDecoration(
                        hint: 'create_request.step1.description_hint'.tr(),
                        error: _descriptionError,
                      ).copyWith(alignLabelWithHint: true),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Urgency
              Text(
                'create_request.step1.urgency_label'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              _buildUrgencySelector(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration({required String hint, String? error}) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      hintStyle: TextStyle(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    final blueColor = Theme.of(context).colorScheme.primary;
    final orangeColor = Theme.of(
      context,
    ).extension<AppSemanticColors>()!.warning;

    return Column(
      children: [
        _buildUrgencyOption(
          value: 'normal',
          icon: Icons.schedule,
          title: 'common.urgency.standard'.tr(),
          description: 'create_request.urgency.standard_desc'.tr(),
          color: blueColor,
        ),
        const SizedBox(height: 12),
        _buildUrgencyOption(
          value: 'priority',
          icon: Icons.bolt, // Material bolt icon matches HTML
          title: 'common.urgency.priority'.tr(),
          description: 'create_request.urgency.priority_desc'.tr(),
          color: orangeColor,
          extraFee: AppConstants.priorityFee,
        ),
      ],
    );
  }

  Widget _buildUrgencyOption({
    required String value,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    double? extraFee,
  }) {
    final isSelected = _urgency == value;

    return InkWell(
      onTap: () => setState(() => _urgency = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected
                ? 2
                : 1, // HTML uses 2px for base border too? No check HTML. "border-2"
          ),
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (extraFee != null)
                    Text(
                      'create_request.urgency.priority_fee'.tr(
                        namedArgs: {'fee': extraFee.toInt().toString()},
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    )
                  else
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // Radio Circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.3)
                      : Theme.of(
                          context,
                        ).dividerColor, // HTML uses border-color/30
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Upload Documents (Placeholder)
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'create_request.step2.title'.tr(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'create_request.step2.subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.sectionSpacing),

        // Info message
        SurfaceCard(
          padding: AppTheme.cardPadding,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withValues(alpha: 0.1),
          borderColor: Theme.of(context).dividerColor,
          showShadow: false,
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.secondary,
                size: AppTheme.iconMedium,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  'create_request.step2.info_message'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Review & Submit
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'create_request.step3.title'.tr(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'create_request.step3.subtitle'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.sectionSpacing),

        // Request summary
        _buildSummarySection(
          title: 'create_request.step3.request_details'.tr(),
          onEdit: () => setState(() {
            _currentStep = 0;
            _pageController.jumpToPage(0);
          }),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                _description.length > AppConstants.descriptionCounterThreshold
                    ? '${_description.substring(0, AppConstants.descriptionCounterThreshold)}...'
                    : _description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing12),
              _buildUrgencyBadge(),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Terms and conditions
        SurfaceCard(
          padding: AppTheme.cardPadding,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          borderColor: _termsError != null
              ? Theme.of(context).colorScheme.error
              : null,
          showShadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                        if (_termsError != null) _termsError = null;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'create_request.step3.accept_terms'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacing48),
                child: Text(
                  'create_request.step3.terms_text'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_termsError != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.spacing48,
                    top: AppTheme.spacing8,
                  ),
                  child: Text(
                    _termsError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection({
    required String title,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return SurfaceCard(
      padding: AppTheme.cardPadding,
      borderColor: Theme.of(context).dividerColor,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: onEdit,
                  child: Text(
                    'common.edit'.tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          child,
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge() {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    Color badgeColor;
    String badgeText;

    switch (_urgency) {
      case 'priority':
        badgeColor =
            semanticColors?.warning ?? Theme.of(context).colorScheme.tertiary;
        badgeText = 'common.urgency.priority'.tr();
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.primary;
        badgeText = 'common.urgency.standard'.tr();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
