import 'package:flutter_test/flutter_test.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:mcs_app/utils/validation/consultation_validator.dart';

void main() {
  group('ConsultationValidator', () {
    group('validate', () {
      test('returns success for valid input', () {
        final result = ConsultationValidator.validate(
          title: 'A' * AppConstants.titleMinLength, // Exactly min length
          description: 'B' * AppConstants.descriptionMinLength, // Exactly min length
          urgency: 'normal',
        );

        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('returns success for maximum valid input', () {
        final result = ConsultationValidator.validate(
          title: 'A' * AppConstants.titleMaxLength,
          description: 'B' * AppConstants.descriptionMaxLength,
          urgency: 'priority',
        );

        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      group('title validation', () {
        test('fails for empty title', () {
          final result = ConsultationValidator.validate(
            title: '',
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('title'), true);
          expect(result.getError('title'), 'validation.required_field');
        });

        test('fails for whitespace-only title', () {
          final result = ConsultationValidator.validate(
            title: '   ',
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('title'), true);
          expect(result.getError('title'), 'validation.required_field');
        });

        test('fails for title shorter than minimum', () {
          final result = ConsultationValidator.validate(
            title: 'A' * (AppConstants.titleMinLength - 1),
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('title'), true);
          expect(result.getError('title'), 'create_request.validation.title_too_short');
        });

        test('fails for title longer than maximum', () {
          final result = ConsultationValidator.validate(
            title: 'A' * (AppConstants.titleMaxLength + 1),
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('title'), true);
          expect(result.getError('title'), 'create_request.validation.title_too_long');
        });

        test('trims whitespace before validating length', () {
          // Title with padding that would make it long enough if not trimmed
          final paddedTitle = '  ${'A' * (AppConstants.titleMinLength - 1)}  ';
          final result = ConsultationValidator.validate(
            title: paddedTitle,
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('title'), true);
        });
      });

      group('description validation', () {
        test('fails for empty description', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: '',
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('description'), true);
          expect(result.getError('description'), 'validation.required_field');
        });

        test('fails for whitespace-only description', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: '     ',
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('description'), true);
          expect(result.getError('description'), 'validation.required_field');
        });

        test('fails for description shorter than minimum', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: 'B' * (AppConstants.descriptionMinLength - 1),
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('description'), true);
          expect(
            result.getError('description'),
            'create_request.validation.description_too_short',
          );
        });

        test('fails for description longer than maximum', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: 'B' * (AppConstants.descriptionMaxLength + 1),
            urgency: 'normal',
          );

          expect(result.isValid, false);
          expect(result.hasError('description'), true);
          expect(
            result.getError('description'),
            'create_request.validation.description_too_long',
          );
        });
      });

      group('urgency validation', () {
        test('accepts "normal" urgency', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'normal',
          );

          expect(result.isValid, true);
          expect(result.hasError('urgency'), false);
        });

        test('accepts "priority" urgency', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'priority',
          );

          expect(result.isValid, true);
          expect(result.hasError('urgency'), false);
        });

        test('fails for invalid urgency value', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'emergency', // Not a valid urgency
          );

          expect(result.isValid, false);
          expect(result.hasError('urgency'), true);
          expect(result.getError('urgency'), 'create_request.validation.invalid_urgency');
        });

        test('fails for empty urgency', () {
          final result = ConsultationValidator.validate(
            title: 'A' * AppConstants.titleMinLength,
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: '',
          );

          expect(result.isValid, false);
          expect(result.hasError('urgency'), true);
        });
      });

      group('multiple errors', () {
        test('returns all field errors when multiple validations fail', () {
          final result = ConsultationValidator.validate(
            title: '',
            description: '',
            urgency: 'invalid',
          );

          expect(result.isValid, false);
          expect(result.errors.length, 3);
          expect(result.hasError('title'), true);
          expect(result.hasError('description'), true);
          expect(result.hasError('urgency'), true);
        });

        test('allErrors returns list of all error messages', () {
          final result = ConsultationValidator.validate(
            title: '',
            description: '',
            urgency: 'normal',
          );

          expect(result.allErrors.length, 2);
          expect(result.allErrors, contains('validation.required_field'));
        });

        test('firstError returns first error message', () {
          final result = ConsultationValidator.validate(
            title: '',
            description: 'B' * AppConstants.descriptionMinLength,
            urgency: 'normal',
          );

          expect(result.firstError, isNotNull);
        });
      });
    });

    group('validateTitle', () {
      test('returns null for valid title', () {
        final error = ConsultationValidator.validateTitle(
          'A' * AppConstants.titleMinLength,
        );
        expect(error, isNull);
      });

      test('returns error key for empty title', () {
        final error = ConsultationValidator.validateTitle('');
        expect(error, 'validation.required_field');
      });

      test('returns error key for short title', () {
        final error = ConsultationValidator.validateTitle(
          'A' * (AppConstants.titleMinLength - 1),
        );
        expect(error, 'create_request.validation.title_too_short');
      });

      test('returns error key for long title', () {
        final error = ConsultationValidator.validateTitle(
          'A' * (AppConstants.titleMaxLength + 1),
        );
        expect(error, 'create_request.validation.title_too_long');
      });
    });

    group('validateDescription', () {
      test('returns null for valid description', () {
        final error = ConsultationValidator.validateDescription(
          'B' * AppConstants.descriptionMinLength,
        );
        expect(error, isNull);
      });

      test('returns error key for empty description', () {
        final error = ConsultationValidator.validateDescription('');
        expect(error, 'validation.required_field');
      });

      test('returns error key for short description', () {
        final error = ConsultationValidator.validateDescription(
          'B' * (AppConstants.descriptionMinLength - 1),
        );
        expect(error, 'create_request.validation.description_too_short');
      });

      test('returns error key for long description', () {
        final error = ConsultationValidator.validateDescription(
          'B' * (AppConstants.descriptionMaxLength + 1),
        );
        expect(error, 'create_request.validation.description_too_long');
      });
    });

    group('validUrgencyLevels', () {
      test('contains expected values', () {
        expect(ConsultationValidator.validUrgencyLevels, contains('normal'));
        expect(ConsultationValidator.validUrgencyLevels, contains('priority'));
        expect(ConsultationValidator.validUrgencyLevels.length, 2);
      });
    });
  });

  group('ValidationResult', () {
    test('success creates valid result', () {
      final result = ConsultationValidator.validate(
        title: 'A' * AppConstants.titleMinLength,
        description: 'B' * AppConstants.descriptionMinLength,
        urgency: 'normal',
      );

      expect(result.isValid, true);
      expect(result.errors, isEmpty);
      expect(result.firstError, isNull);
    });

    test('failure creates invalid result with errors', () {
      final result = ConsultationValidator.validate(
        title: '',
        description: '',
        urgency: 'invalid',
      );

      expect(result.isValid, false);
      expect(result.errors, isNotEmpty);
      expect(result.firstError, isNotNull);
    });

    test('getError returns error for specific field', () {
      final result = ConsultationValidator.validate(
        title: '',
        description: 'B' * AppConstants.descriptionMinLength,
        urgency: 'normal',
      );

      expect(result.getError('title'), 'validation.required_field');
      expect(result.getError('description'), isNull);
    });

    test('hasError correctly identifies fields with errors', () {
      final result = ConsultationValidator.validate(
        title: '',
        description: 'B' * AppConstants.descriptionMinLength,
        urgency: 'normal',
      );

      expect(result.hasError('title'), true);
      expect(result.hasError('description'), false);
      expect(result.hasError('urgency'), false);
    });
  });
}
