import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:provider/provider.dart';

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
  final List<TextEditingController> _questionControllers = [TextEditingController()];
  final List<FocusNode> _questionFocusNodes = [FocusNode()];
  final List<GlobalKey> _questionKeys = [GlobalKey()];
  bool _isSubmitting = false;

  // GlobalKeys for scroll-to-error functionality
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
    // Register fields in order for scroll-to-error
    _scrollHelper.register('message', _messageKey);
    for (var i = 0; i < _questionKeys.length; i++) {
      _scrollHelper.register('question_$i', _questionKeys[i]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.request_more_info.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyedSubtree(
                  key: _messageKey,
                  child: AppTextField(
                    label: 'doctor.request_more_info.message_label'.tr(),
                    controller: _messageController,
                    maxLines: 4,
                    hintText: 'doctor.request_more_info.message_hint'.tr(),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'doctor.request_more_info.validation.required'.tr();
                      }
                      if (text.length < AppConstants.infoMessageMinLength) {
                        return 'doctor.request_more_info.validation.min_length'.tr(
                          namedArgs: {'min': AppConstants.infoMessageMinLength.toString()},
                        );
                      }
                      if (text.length > AppConstants.infoMessageMaxLength) {
                        return 'doctor.request_more_info.validation.max_length'.tr(
                          namedArgs: {'max': AppConstants.infoMessageMaxLength.toString()},
                        );
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_messageController.text.trim().length}/${AppConstants.infoMessageMaxLength}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ),
                const SizedBox(height: AppTheme.sectionSpacing),
                Text(
                  'doctor.request_more_info.questions_title'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacing12),
                // Questions list (no longer in Expanded ListView)
                ...List.generate(_questionControllers.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _questionControllers.length - 1
                          ? AppTheme.spacing12
                          : 0,
                    ),
                    child: KeyedSubtree(
                      key: _questionKeys[index],
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                            label: '${'doctor.request_more_info.question_label'.tr()} ${index + 1}',
                            controller: _questionControllers[index],
                            hintText: 'doctor.request_more_info.question_hint'.tr(),
                            focusNode: _questionFocusNodes[index],
                            onChanged: (_) => setState(() {}),
                            maxLines: 2,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'doctor.request_more_info.validation.question_required'.tr();
                              }
                              if (text.length < AppConstants.infoQuestionMinLength) {
                                return 'doctor.request_more_info.validation.question_too_short'.tr(
                                  namedArgs: {'min': AppConstants.infoQuestionMinLength.toString()},
                                );
                              }
                              if (text.length > AppConstants.infoQuestionMaxLength) {
                                return 'doctor.request_more_info.validation.question_too_long'.tr(
                                  namedArgs: {'max': AppConstants.infoQuestionMaxLength.toString()},
                                );
                              }
                              return null;
                            },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          if (_questionControllers.length > 1)
                            IconButton(
                              tooltip: 'common.delete'.tr(),
                              onPressed: () {
                                setState(() {
                                  _questionControllers.removeAt(index).dispose();
                                  _questionFocusNodes.removeAt(index).dispose();
                                  _questionKeys.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Theme.of(context).colorScheme.error,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppTheme.spacing12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _questionControllers.add(TextEditingController());
                      _questionFocusNodes.add(FocusNode());
                      _questionKeys.add(GlobalKey());
                    });
                    // Move focus to the newly added field.
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _questionFocusNodes.last.requestFocus();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text('doctor.request_more_info.add_question'.tr()),
                ),
                const SizedBox(height: AppTheme.spacing16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submit(context),
                    icon: const Icon(Icons.send_outlined),
                    label: Text('doctor.request_more_info.submit'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final successText = 'doctor.request_more_info.success'.tr();
    final errorText = 'doctor.request_more_info.error'.tr();
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      await controller.requestMoreInfo(
        widget.consultationId,
        message: _messageController.text.trim(),
        questions: questions,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(successText),
        ),
      );
      navigator.pop(true);
    } catch (e) {
      debugPrint('Error requesting more info: $e');
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
