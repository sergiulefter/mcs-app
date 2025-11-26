import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/utils/app_theme.dart';
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
  final _messageController = TextEditingController();
  final List<TextEditingController> _questionControllers = [TextEditingController()];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    for (final controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.request_more_info.title'.tr()),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'doctor.request_more_info.message_label'.tr(),
                  controller: _messageController,
                  maxLines: 4,
                  hintText: 'doctor.request_more_info.message_hint'.tr(),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'doctor.request_more_info.validation.required'.tr();
                    }
                    if (text.length < 100) {
                      return 'doctor.request_more_info.validation.min_length'.tr();
                    }
                    if (text.length > 500) {
                      return 'doctor.request_more_info.validation.max_length'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.sectionSpacing),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'doctor.request_more_info.questions_title'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _questionControllers.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: AppTheme.spacing12),
                    itemBuilder: (context, index) {
                      return AppTextField(
                        label: '${'doctor.request_more_info.question_label'.tr()} ${index + 1}',
                        controller: _questionControllers[index],
                        hintText: 'doctor.request_more_info.question_hint'.tr(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _questionControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: Text('doctor.request_more_info.add_question'.tr()),
                  ),
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
    if (!_formKey.currentState!.validate()) return;

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
