import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mcs_app/controllers/auth_controller.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'consultations_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final DoctorModel doctor;

  const CreateRequestScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form data
  String _title = '';
  String _description = '';
  String _urgency = 'normal'; // normal, urgent, emergency
  bool _termsAccepted = false;

  @override
  void dispose() {
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
        curve: Curves.easeInOut,
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
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateStep1() {
    if (_title.trim().length < 10) {
      _showError('create_request.validation.title_too_short'.tr());
      return false;
    }
    if (_description.trim().length < 50) {
      _showError('create_request.validation.description_too_short'.tr());
      return false;
    }
    return true;
  }

  void _showError(String message) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            semanticColors?.error ?? Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            semanticColors?.success ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_termsAccepted) {
      _showError('create_request.validation.accept_terms'.tr());
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
      await consultationsController
          .fetchUserConsultations(authController.currentUser!.uid);

      if (mounted) {
        // Show success and navigate
        _showSuccess('create_request.success_message'.tr());

        // Navigate to consultations screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ConsultationsScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showError('create_request.error_message'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('create_request.title'.tr()),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          _buildDoctorCard(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing32,
        vertical: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'create_request.step_indicator'
                    .tr(namedArgs: {'current': '${_currentStep + 1}', 'total': '3'}),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${((_currentStep + 1) / 3 * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: SurfaceCard(
        padding: AppTheme.cardPadding,
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        showShadow: false,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              ),
              child: Center(
                child: Text(
                  widget.doctor.fullName.substring(0, 1).toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctor.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    widget.doctor.specialty.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${widget.doctor.consultationPrice.toInt()} ${'doctor_profile.currency'.tr()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Request Details
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'create_request.step1.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'create_request.step1.subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppTheme.sectionSpacing),

            // Title field
            Text(
              'create_request.step1.title_label'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              maxLength: 100,
              onChanged: (value) => setState(() => _title = value),
              decoration: InputDecoration(
                hintText: 'create_request.step1.title_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Description field
            Text(
              'create_request.step1.description_label'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.spacing8),
            TextField(
              maxLength: 1000,
              maxLines: 6,
              onChanged: (value) => setState(() => _description = value),
              decoration: InputDecoration(
                hintText: 'create_request.step1.description_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Urgency selector
            Text(
              'create_request.step1.urgency_label'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.spacing12),
            _buildUrgencySelector(),

            const SizedBox(height: AppTheme.sectionSpacing),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: AppTheme.buttonHeight,
              child: ElevatedButton(
                onPressed: _nextStep,
                child: Text('create_request.continue_button'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();

    return Column(
      children: [
        _buildUrgencyOption(
          value: 'normal',
          icon: Icons.schedule,
          title: 'create_request.urgency.normal'.tr(),
          description: 'create_request.urgency.normal_desc'.tr(),
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildUrgencyOption(
          value: 'urgent',
          icon: Icons.priority_high,
          title: 'create_request.urgency.urgent'.tr(),
          description: 'create_request.urgency.urgent_desc'.tr(),
          color: semanticColors?.warning ??
              Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildUrgencyOption(
          value: 'emergency',
          icon: Icons.emergency,
          title: 'create_request.urgency.emergency'.tr(),
          description: 'create_request.urgency.emergency_desc'.tr(),
          color:
              semanticColors?.error ?? Theme.of(context).colorScheme.error,
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
  }) {
    final isSelected = _urgency == value;

    return InkWell(
      onTap: () => setState(() => _urgency = value),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // Step 2: Upload Documents (Placeholder)
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'create_request.step2.title'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
            backgroundColor:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
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
          const SizedBox(height: AppTheme.sectionSpacing),

          // Skip and Continue buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _nextStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                  ),
                  child: Text('create_request.skip_button'.tr()),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                  ),
                  child: Text('create_request.continue_button'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Review & Submit
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'create_request.step3.title'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  _description.length > 200
                      ? '${_description.substring(0, 200)}...'
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
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            showShadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) =>
                          setState(() => _termsAccepted = value ?? false),
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
              ],
            ),
          ),
          const SizedBox(height: AppTheme.sectionSpacing),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              child: _isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text('create_request.submit_button'.tr()),
            ),
          ),
        ],
      ),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: onEdit,
                  child: Text(
                    'create_request.step3.edit_button'.tr(),
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
      case 'urgent':
        badgeColor = semanticColors?.warning ??
            Theme.of(context).colorScheme.tertiary;
        badgeText = 'create_request.urgency.urgent'.tr();
        break;
      case 'emergency':
        badgeColor =
            semanticColors?.error ?? Theme.of(context).colorScheme.error;
        badgeText = 'create_request.urgency.emergency'.tr();
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.primary;
        badgeText = 'create_request.urgency.normal'.tr();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
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
