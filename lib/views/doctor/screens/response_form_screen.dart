import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/controllers/doctor_consultations_controller.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/utils/app_theme.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/form_scroll_helper.dart';
import 'package:mcs_app/views/patient/widgets/forms/app_text_field.dart';
import 'package:provider/provider.dart';

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

  // GlobalKeys for scroll-to-error functionality
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
    final controller = context.watch<DoctorConsultationsController>();
    final consultation = controller.consultationById(widget.consultationId);

    if (consultation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Register fields in order for scroll-to-error
    _scrollHelper.register('response', _responseKey);

    return Scaffold(
      appBar: AppBar(
        title: Text('doctor.response_form.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.sectionSpacing),
                KeyedSubtree(
                  key: _responseKey,
                  child: AppTextField(
                    label: 'doctor.response_form.response_label'.tr(),
                    controller: _responseController,
                    maxLines: 8,
                    hintText: 'doctor.response_form.response_hint'.tr(),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'doctor.response_form.validation.required'.tr();
                      }
                      if (text.length < AppConstants.responseMinLength) {
                        return 'doctor.response_form.validation.min_length'.tr(
                          namedArgs: {'min': AppConstants.responseMinLength.toString()},
                        );
                      }
                      if (text.length > AppConstants.responseMaxLength) {
                        return 'doctor.response_form.validation.max_length'.tr(
                          namedArgs: {'max': AppConstants.responseMaxLength.toString()},
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
                    '${_responseController.text.trim().length}/${AppConstants.responseMaxLength}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                AppTextField(
                  label: 'doctor.response_form.recommendations_label'.tr(),
                  controller: _recommendationsController,
                  maxLines: 4,
                  hintText: 'doctor.response_form.recommendations_hint'.tr(),
                ),
                const SizedBox(height: AppTheme.spacing16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('doctor.response_form.follow_up_title'.tr()),
                  subtitle:
                      Text('doctor.response_form.follow_up_subtitle'.tr()),
                  value: _followUpNeeded,
                  onChanged: (value) =>
                      setState(() => _followUpNeeded = value),
                ),
                const SizedBox(height: AppTheme.sectionSpacing),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submit(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('doctor.response_form.submit'.tr()),
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final successText = 'doctor.response_form.success'.tr();
    final errorText = 'doctor.response_form.error'.tr();
    final errorColor = Theme.of(context).colorScheme.error;

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
