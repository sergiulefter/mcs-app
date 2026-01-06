import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/views/shared/widgets/detail_screen_header.dart';
import 'package:provider/provider.dart';

/// Doctor screen for submitting diagnosis/response.
/// Redesigned to match the modern UI with custom header and styled form fields.
class ResponseFormScreen extends StatefulWidget {
  const ResponseFormScreen({super.key, required this.consultationId});

  final String consultationId;

  @override
  State<ResponseFormScreen> createState() => _ResponseFormScreenState();
}

class _ResponseFormScreenState extends State<ResponseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollHelper = FormScrollHelper();
  final _responseController = TextEditingController();
  final _recommendationsController = TextEditingController();
  bool _followUpNeeded = false;
  bool _isSubmitting = false;

  final _responseKey = GlobalKey();

  @override
  void dispose() {
    _scrollHelper.dispose();
    _responseController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<DoctorConsultationsController>();
    final consultation = controller.consultationById(widget.consultationId);

    if (consultation == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              DetailScreenHeader(title: 'doctor.response_form.title'.tr()),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    _scrollHelper.register('response', _responseKey);

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            DetailScreenHeader(title: 'doctor.response_form.title'.tr()),

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Consultation title card
                      _buildConsultationHeader(context, consultation),

                      const SizedBox(height: AppTheme.spacing24),

                      // Response section
                      _buildSectionLabel(
                        context,
                        'doctor.response_form.response_label'.tr(),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      KeyedSubtree(
                        key: _responseKey,
                        child: _buildTextField(
                          context,
                          controller: _responseController,
                          hintText: 'doctor.response_form.response_hint'.tr(),
                          maxLines: 8,
                          maxLength: AppConstants.responseMaxLength,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'doctor.response_form.validation.required'
                                  .tr();
                            }
                            if (text.length < AppConstants.responseMinLength) {
                              return 'doctor.response_form.validation.min_length'
                                  .tr(
                                    namedArgs: {
                                      'min': AppConstants.responseMinLength
                                          .toString(),
                                    },
                                  );
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing24),

                      // Recommendations section
                      _buildSectionLabel(
                        context,
                        'doctor.response_form.recommendations_label'.tr(),
                        isOptional: true,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      _buildTextField(
                        context,
                        controller: _recommendationsController,
                        hintText: 'doctor.response_form.recommendations_hint'
                            .tr(),
                        maxLines: 4,
                      ),

                      const SizedBox(height: AppTheme.spacing24),

                      // Follow-up toggle card
                      _buildFollowUpCard(context),

                      const SizedBox(height: 100), // Space for fixed button
                    ],
                  ),
                ),
              ),
            ),

            // Fixed submit button
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationHeader(
    BuildContext context,
    ConsultationModel consultation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'doctor.response_form.responding_to'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String label, {
    bool isOptional = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark ? AppTheme.slate400 : AppTheme.slate500,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        if (isOptional) ...[
          const SizedBox(width: 8),
          Text(
            '(${'common.optional'.tr()})',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (_) => setState(() {}),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? AppTheme.slate500 : AppTheme.slate400,
            ),
            filled: true,
            fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppTheme.slate700 : AppTheme.slate200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppTheme.slate700 : AppTheme.slate200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (maxLength != null) ...[
          const SizedBox(height: 4),
          Text(
            '${controller.text.trim().length}/$maxLength',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppTheme.slate500 : AppTheme.slate400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFollowUpCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.slate700 : AppTheme.slate200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'doctor.response_form.follow_up_title'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'doctor.response_form.follow_up_subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _followUpNeeded,
            onChanged: (value) => setState(() => _followUpNeeded = value),
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.slate800 : AppTheme.slate200,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text('doctor.response_form.submit'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollHelper.scrollToFirstError(context);
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = context.read<DoctorConsultationsController>();
    final navigator = Navigator.of(context);

    try {
      await controller.addDoctorResponse(
        widget.consultationId,
        responseText: _responseController.text.trim(),
        recommendations: _recommendationsController.text.trim().isEmpty
            ? null
            : _recommendationsController.text.trim(),
        followUpNeeded: _followUpNeeded,
        attachments: const <AttachmentModel>[],
      );

      if (mounted) {
        NotificationsHelper().showSuccess(
          'doctor.response_form.success'.tr(),
          context: context,
        );
      }
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        NotificationsHelper().showError(e.toString(), context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
