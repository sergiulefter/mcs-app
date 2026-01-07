import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/views/shared/widgets/detail_screen_header.dart';
import 'package:mcs_app/views/shared/widgets/timeline_message.dart';

/// Patient screen for responding to doctor's information request.
/// Redesigned to match the modern UI with custom header and styled form fields.
class PatientRespondInfoScreen extends StatefulWidget {
  final ConsultationModel consultation;
  final InfoRequestModel infoRequest;

  const PatientRespondInfoScreen({
    super.key,
    required this.consultation,
    required this.infoRequest,
  });

  @override
  State<PatientRespondInfoScreen> createState() =>
      _PatientRespondInfoScreenState();
}

class _PatientRespondInfoScreenState extends State<PatientRespondInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollHelper = FormScrollHelper();
  final _additionalInfoController = TextEditingController();
  final List<TextEditingController> _answerControllers = [];
  final List<GlobalKey> _answerKeys = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.infoRequest.questions.length; i++) {
      _answerControllers.add(TextEditingController());
      _answerKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _scrollHelper.dispose();
    _additionalInfoController.dispose();
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Register fields for scroll-to-error
    for (var i = 0; i < _answerKeys.length; i++) {
      _scrollHelper.register('answer_$i', _answerKeys[i]);
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            DetailScreenHeader(title: 'info_response.title'.tr()),

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor's message section
                      _buildDoctorMessage(context),

                      const SizedBox(height: AppTheme.spacing24),

                      // Questions section
                      _buildQuestionsSection(context),

                      const SizedBox(height: AppTheme.spacing24),

                      // Additional info section
                      _buildAdditionalInfo(context),

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

  Widget _buildDoctorMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, 'info_response.doctor_message_title'.tr()),
        const SizedBox(height: AppTheme.spacing16),

        // Display as timeline message
        TimelineMessage(
          sender: TimelineMessageSender.doctor,
          senderName: widget.consultation.doctorName ?? 'Doctor',
          message: widget.infoRequest.message,
          timestamp: widget.infoRequest.requestedAt,
        ),
      ],
    );
  }

  Widget _buildQuestionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          context,
          'info_response.questions_title'.tr(
            namedArgs: {
              'count': widget.infoRequest.questions.length.toString(),
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),

        // Question cards with answer fields
        ...List.generate(widget.infoRequest.questions.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < widget.infoRequest.questions.length - 1
                  ? AppTheme.spacing20
                  : 0,
            ),
            child: KeyedSubtree(
              key: _answerKeys[index],
              child: _buildQuestionCard(context, index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question label
          Text(
            '${'info_response.question_label'.tr()} ${index + 1}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Question text
          Text(
            widget.infoRequest.questions[index],
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // Answer field
          TextFormField(
            controller: _answerControllers[index],
            maxLines: 4,
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'info_response.validation.answer_required'.tr();
              }
              if (text.length < AppConstants.infoAnswerMinLength) {
                return 'info_response.validation.answer_too_short'.tr(
                  namedArgs: {
                    'min': AppConstants.infoAnswerMinLength.toString(),
                  },
                );
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'info_response.your_answer'.tr(),
              hintText: 'info_response.answer_hint'.tr(),
              hintStyle: TextStyle(
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
              filled: true,
              fillColor: isDark ? AppTheme.slate800 : AppTheme.slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.error),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          // Character count
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_answerControllers[index].text.trim().length}/${AppConstants.infoAnswerMaxLength}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          context,
          'info_response.additional_info_title'.tr(),
          isOptional: true,
        ),
        const SizedBox(height: AppTheme.spacing12),

        TextFormField(
          controller: _additionalInfoController,
          maxLines: 4,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'info_response.additional_info_hint'.tr(),
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
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
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
                : const Icon(Icons.send_outlined, size: 20),
            label: Text('info_response.submit'.tr()),
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

    final controller = context.read<ConsultationsController>();
    final answers = _answerControllers.map((c) => c.text.trim()).toList();
    final additionalInfo = _additionalInfoController.text.trim().isNotEmpty
        ? _additionalInfoController.text.trim()
        : null;
    final navigator = Navigator.of(context);

    try {
      await controller.submitInfoResponse(
        widget.consultation.id,
        widget.infoRequest.id,
        answers: answers,
        additionalInfo: additionalInfo,
      );
      if (mounted) {
        NotificationsHelper().showSuccess(
          'info_response.success'.tr(),
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
