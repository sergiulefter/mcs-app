import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcs_app/controllers/consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/views/patient/widgets/cards/surface_card.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:mcs_app/views/patient/widgets/layout/section_header.dart';

class RespondToInfoScreen extends StatefulWidget {
  final ConsultationModel consultation;
  final InfoRequestModel infoRequest;

  const RespondToInfoScreen({
    super.key,
    required this.consultation,
    required this.infoRequest,
  });

  @override
  State<RespondToInfoScreen> createState() => _RespondToInfoScreenState();
}

class _RespondToInfoScreenState extends State<RespondToInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _additionalInfoController = TextEditingController();
  final List<TextEditingController> _answerControllers = [];
  bool _isSubmitting = false;

  static const int _answerMin = 10;
  static const int _answerMax = 500;

  @override
  void initState() {
    super.initState();
    // Initialize answer controllers for each question
    for (var i = 0; i < widget.infoRequest.questions.length; i++) {
      _answerControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('info_response.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor's message section
                Padding(
                  padding: AppTheme.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDoctorMessage(context),
                      const SizedBox(height: AppTheme.sectionSpacing),
                      _buildQuestionsSection(context),
                      const SizedBox(height: AppTheme.sectionSpacing),
                      _buildAdditionalInfo(context),
                      const SizedBox(height: AppTheme.sectionSpacing),
                      _buildAttachmentsPlaceholder(context),
                      const SizedBox(height: AppTheme.sectionSpacing),
                      _buildSubmitButton(context),
                      const SizedBox(height: AppTheme.sectionSpacing),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'info_response.doctor_message_title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        SurfaceCard(
          padding: AppTheme.cardPadding,
          backgroundColor: colorScheme.secondary.withValues(alpha: 0.05),
          borderColor: colorScheme.secondary.withValues(alpha: 0.2),
          showShadow: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.medical_information_outlined,
                color: colorScheme.secondary,
                size: AppTheme.iconMedium,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.infoRequest.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      DateFormat.yMMMd().format(widget.infoRequest.requestedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'info_response.questions_title'.tr(
            namedArgs: {'count': widget.infoRequest.questions.length.toString()},
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        ...List.generate(widget.infoRequest.questions.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < widget.infoRequest.questions.length - 1
                  ? AppTheme.spacing20
                  : 0,
            ),
            child: _buildQuestionCard(context, index),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      padding: AppTheme.cardPadding,
      borderColor: colorScheme.outline.withValues(alpha: 0.3),
      showShadow: false,
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
          const SizedBox(height: AppTheme.spacing8),
          // Question text
          Text(
            widget.infoRequest.questions[index],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Answer input
          AppTextField(
            label: 'info_response.your_answer'.tr(),
            hintText: 'info_response.answer_hint'.tr(),
            controller: _answerControllers[index],
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'info_response.validation.answer_required'.tr();
              }
              if (text.length < _answerMin) {
                return 'info_response.validation.answer_too_short'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_answerControllers[index].text.trim().length}/$_answerMax',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'info_response.additional_info_title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        AppTextField(
          label: 'info_response.additional_info_label'.tr(),
          hintText: 'info_response.additional_info_hint'.tr(),
          controller: _additionalInfoController,
          maxLines: 4,
          isOptional: true,
        ),
      ],
    );
  }

  Widget _buildAttachmentsPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'info_response.attachments_title'.tr()),
        const SizedBox(height: AppTheme.spacing16),
        SurfaceCard(
          padding: AppTheme.cardPadding,
          backgroundColor: colorScheme.surfaceContainerHighest,
          showShadow: false,
          child: Column(
            children: [
              Icon(
                Icons.attach_file_outlined,
                size: AppTheme.iconLarge,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'info_response.attachments_coming_soon'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.send_outlined),
        label: Text('info_response.submit'.tr()),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final controller = context.read<ConsultationsController>();
    final answers = _answerControllers.map((c) => c.text.trim()).toList();
    final additionalInfo = _additionalInfoController.text.trim().isNotEmpty
        ? _additionalInfoController.text.trim()
        : null;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final successText = 'info_response.success'.tr();
    final errorText = 'info_response.error'.tr();
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      await controller.submitInfoResponse(
        widget.consultation.id,
        widget.infoRequest.id,
        answers: answers,
        additionalInfo: additionalInfo,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(successText)),
      );
      navigator.pop(true);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: errorColor,
          content: Text(errorText),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
