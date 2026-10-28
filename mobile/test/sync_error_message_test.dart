// The sync screen's text for a rejected item (T055: rule IDs become
// sentences).
//
// Run from mobile/: flutter test test/sync_error_message_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sync/domain/sync_error_message.dart';

String lastError(Map<String, Object?> fields) => jsonEncode([
  {
    'code': 'validation_error',
    'detail': 'Validation failed.',
    'fields': fields,
  },
]);

void main() {
  test('a rule ID becomes its sentence, with the field', () {
    final message = syncErrorMessage(
      lastError({
        'observed_at': ['V04'],
      }),
    );
    expect(
      message,
      "Not accepted: The observation time is outside the visit's time "
      '(observed_at).',
    );
  });

  test('several fields and messages are all listed', () {
    final message = syncErrorMessage(
      lastError({
        'count': ['V01'],
        'survey_visit': ['V03', 'V06'],
      }),
    );
    expect(message, contains('The count must be at least 1 (count)'));
    expect(message, contains('(survey_visit); '));
    expect(message, contains('The true-zero confirmation'));
  });

  test('a text that is not a rule ID keeps the server text', () {
    final message = syncErrorMessage(
      lastError({
        'taxon': ['This taxon was deleted.'],
      }),
    );
    expect(message, 'Not accepted: This taxon was deleted (taxon).');
  });

  test('a nested error shows its messages, not map syntax', () {
    final message = syncErrorMessage(
      lastError({
        'behaviour': {
          '0': ['V07'],
        },
        'non_field_errors': ['Something else.'],
      }),
    );
    expect(
      message,
      'Not accepted: A value is not one of the allowed choices (behaviour); '
      'Something else.',
    );
  });

  test('a validation error without fields keeps the short text', () {
    expect(syncErrorMessage(lastError({})), 'Some values were not accepted.');
  });

  test('other codes are unchanged', () {
    final error = jsonEncode([
      {'code': 'not_found', 'detail': 'x', 'fields': {}},
    ]);
    expect(
      syncErrorMessage(error),
      'This record no longer exists on the server.',
    );
  });
}
