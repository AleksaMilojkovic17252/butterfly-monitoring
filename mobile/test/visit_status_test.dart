// The app's visit lifecycle must match the shared spec the server also reads
// (T034). An exception to D-021, asked for by the ticket; the server has the
// same check in `backend/apps/surveys/tests.py`.
//
// Run from mobile/: flutter test test/visit_status_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/validation/visit_values.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

void main() {
  // `flutter test` runs in mobile/, and docs/ sits next to it.
  final spec = jsonDecode(
    File('../docs/requirements/visit-states.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('statuses match the spec', () {
    expect(visitStatuses, spec['statuses']);
  });

  test('cancel reasons match the spec', () {
    expect(cancelReasons, spec['cancel_reasons']);
  });

  test('transitions match the spec', () {
    final specTransitions = {
      for (final row in spec['transitions'] as List)
        '${row['from']} -> ${row['to']}': row['by'],
    };
    final appTransitions = {
      for (final transition in visitTransitions)
        '${transition.from} -> ${transition.to}': transition.by.name,
    };
    expect(specTransitions.length, (spec['transitions'] as List).length);
    expect(appTransitions.length, visitTransitions.length);
    expect(appTransitions, specTransitions);
  });
}
