import 'package:flutter/material.dart';

/// Helper class to scroll to first error field in a form.
///
/// Usage in form screens:
/// ```dart
/// class _MyFormState extends State<MyForm> {
///   final _formKey = GlobalKey<FormState>();
///   final _scrollHelper = FormScrollHelper();
///
///   // Register fields in build():
///   _scrollHelper.register('email', _emailKey);
///   _scrollHelper.register('password', _passwordKey);
///
///   // On submit:
///   void _submit() {
///     _scrollHelper.clearErrors();
///
///     if (!_formKey.currentState!.validate()) {
///       _scrollHelper.scrollToFirstError(context);
///       return;
///     }
///
///     // Custom validation
///     if (_selectedLanguages.isEmpty) {
///       _scrollHelper.setError('languages');
///       _scrollHelper.scrollToFirstError(context);
///       return;
///     }
///   }
/// }
/// ```
class FormScrollHelper {
  final Map<String, GlobalKey> _fieldKeys = {};
  final List<String> _fieldOrder = [];
  final Set<String> _errorFields = {};

  /// Register a field with its GlobalKey. Call in order of appearance.
  void register(String fieldId, GlobalKey key) {
    if (!_fieldOrder.contains(fieldId)) {
      _fieldOrder.add(fieldId);
    }
    _fieldKeys[fieldId] = key;
  }

  /// Mark a field as having an error (for custom validation).
  void setError(String fieldId) {
    _errorFields.add(fieldId);
  }

  /// Clear all custom error markers.
  void clearErrors() {
    _errorFields.clear();
  }

  /// Check if field has custom error.
  bool hasError(String fieldId) => _errorFields.contains(fieldId);

  /// Scroll to first field with error (either FormField error or custom).
  Future<void> scrollToFirstError(BuildContext context) async {
    // Find first error field in registration order
    for (final fieldId in _fieldOrder) {
      final key = _fieldKeys[fieldId];
      if (key == null) continue;

      // Check custom error first
      if (_errorFields.contains(fieldId)) {
        await _scrollToKey(key);
        return;
      }

      // Check if this key's context contains a FormField with error
      final keyContext = key.currentContext;
      if (keyContext != null && _hasFormFieldError(keyContext)) {
        await _scrollToKey(key);
        return;
      }
    }
  }

  /// Check if the given context or any of its descendants has a FormField with error.
  bool _hasFormFieldError(BuildContext context) {
    bool hasError = false;

    void visitor(Element element) {
      if (hasError) return; // Already found an error

      // Check if this element's state is a FormFieldState with error
      if (element is StatefulElement) {
        final state = element.state;
        if (state is FormFieldState && state.hasError) {
          hasError = true;
          return;
        }
      }

      // Continue visiting children
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return hasError;
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.2, // Show field 20% from top
    );
  }

  void dispose() {
    _fieldKeys.clear();
    _fieldOrder.clear();
    _errorFields.clear();
  }
}
