import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/utils/notifications_helper.dart';
import 'package:mcs_app/views/shared/widgets/detail_screen_header.dart';
import 'package:provider/provider.dart';

/// Doctor screen for requesting additional information from patient.
/// Redesigned to match the modern UI with custom header and styled form fields.
class RequestMoreInfoScreen extends StatefulWidget {
  const RequestMoreInfoScreen({super.key, required this.consultationId});

  final String consultationId;

  @override
  State<RequestMoreInfoScreen> createState() => _RequestMoreInfoScreenState();
}

class _RequestMoreInfoScreenState extends State<RequestMoreInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollHelper = FormScrollHelper();
  final _messageController = TextEditingController();
  final List<TextEditingController> _questionControllers = [
    TextEditingController(),
  ];
  final List<FocusNode> _questionFocusNodes = [FocusNode()];
  final List<GlobalKey> _questionKeys = [GlobalKey()];
  bool _isSubmitting = false;

  final _messageKey = GlobalKey();

  @override
  void dispose() {
    _scrollHelper.dispose();
    _messageController.dispose();
    for (final controller in _questionControllers) {
      controller.dispose();
    }
    for (final node in _questionFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Register fields for scroll-to-error
    _scrollHelper.register('message', _messageKey);
    for (var i = 0; i < _questionKeys.length; i++) {
      _scrollHelper.register('question_$i', _questionKeys[i]);
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            DetailScreenHeader(title: 'doctor.request_more_info.title'.tr()),

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message section
                      _buildSectionLabel(
                        context,
                        'doctor.request_more_info.message_label'.tr(),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      KeyedSubtree(
                        key: _messageKey,
                        child: _buildTextField(
                          context,
                          controller: _messageController,
                          hintText: 'doctor.request_more_info.message_hint'
                              .tr(),
                          maxLines: 4,
                          maxLength: AppConstants.infoMessageMaxLength,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'doctor.request_more_info.validation.required'
                                  .tr();
                            }
                            if (text.length <
                                AppConstants.infoMessageMinLength) {
                              return 'doctor.request_more_info.validation.min_length'
                                  .tr(
                                    namedArgs: {
                                      'min': AppConstants.infoMessageMinLength
                                          .toString(),
                                    },
                                  );
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing24),

                      // Questions section
                      _buildSectionLabel(
                        context,
                        'doctor.request_more_info.questions_title'.tr(),
                      ),
                      const SizedBox(height: AppTheme.spacing12),

                      // Question cards
                      ...List.generate(_questionControllers.length, (index) {
                        return _buildQuestionCard(context, index);
                      }),

                      // Add question button
                      const SizedBox(height: AppTheme.spacing12),
                      TextButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(
                          'doctor.request_more_info.add_question'.tr(),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),

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

  Widget _buildSectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: isDark ? AppTheme.slate400 : AppTheme.slate500,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
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

  Widget _buildQuestionCard(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: KeyedSubtree(
        key: _questionKeys[index],
        child: Container(
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
              // Question header with delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'doctor.request_more_info.question_label'.tr()} ${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_questionControllers.length > 1)
                    IconButton(
                      onPressed: () => _removeQuestion(index),
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: colorScheme.error,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Question field
              TextFormField(
                controller: _questionControllers[index],
                focusNode: _questionFocusNodes[index],
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'doctor.request_more_info.validation.question_required'
                        .tr();
                  }
                  if (text.length < AppConstants.infoQuestionMinLength) {
                    return 'doctor.request_more_info.validation.question_too_short'
                        .tr(
                          namedArgs: {
                            'min': AppConstants.infoQuestionMinLength
                                .toString(),
                          },
                        );
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'doctor.request_more_info.question_hint'.tr(),
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.slate800 : AppTheme.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
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
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined, size: 20),
            label: Text('doctor.request_more_info.submit'.tr()),
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

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
      _questionFocusNodes.add(FocusNode());
      _questionKeys.add(GlobalKey());
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _questionFocusNodes.last.requestFocus();
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionControllers.removeAt(index).dispose();
      _questionFocusNodes.removeAt(index).dispose();
      _questionKeys.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollHelper.scrollToFirstError(context);
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = context.read<DoctorConsultationsController>();
    final questions = _questionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final navigator = Navigator.of(context);

    try {
      await controller.requestMoreInfo(
        widget.consultationId,
        message: _messageController.text.trim(),
        questions: questions,
      );
      if (mounted) {
        NotificationsHelper().showSuccess(
          'doctor.request_more_info.success'.tr(),
          context: this.context,
        );
      }
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        NotificationsHelper().showError(e.toString(), context: this.context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
