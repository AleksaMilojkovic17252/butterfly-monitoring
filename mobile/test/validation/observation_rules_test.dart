// One group per observation rule (T055). The server has the same cases in
// `backend/apps/observations/tests.py`.
//
// Run from mobile/: flutter test test/validation

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/validation/observation_rules.dart';

final started = DateTime.utc(2026, 6, 1, 8);
final ended = DateTime.utc(2026, 6, 1, 9);

ObservationRuleContext makeContext({
  String? visitStatus = 'in_progress',
  DateTime? visitEndedAt,
  bool visitZeroConfirmed = false,
  bool taxonPhotoRequired = false,
  int photoCount = 0,
}) {
  return ObservationRuleContext(
    visitStatus: visitStatus,
    visitStartedAt: started,
    visitEndedAt: visitEndedAt,
    visitZeroConfirmed: visitZeroConfirmed,
    toleranceMin: 5,
    accuracyWarningM: 25,
    taxonPhotoRequired: taxonPhotoRequired,
    photoCount: photoCount,
  );
}

ObservationInput makeInput({
  DateTime? observedAt,
  bool noObservedAt = false,
  int count = 1,
  double? lat = 43.3,
  double? lon = 21.9,
  double? accuracyM,
  String source = 'transect',
  String sex = 'unknown',
  String lifeStage = 'adult',
  String confidence = 'confirmed_in_field',
  List<String> behaviour = const [],
}) {
  return ObservationInput(
    observedAt: noObservedAt
        ? null
        : observedAt ?? started.add(const Duration(minutes: 10)),
    count: count,
    lat: lat,
    lon: lon,
    accuracyM: accuracyM,
    source: source,
    sex: sex,
    lifeStage: lifeStage,
    confidence: confidence,
    behaviour: behaviour,
  );
}

void main() {
  test('a good observation has no errors or warnings', () {
    expect(validateObservation(makeInput(), makeContext()), isEmpty);
    expect(observationWarnings(makeInput(), makeContext()), isEmpty);
  });

  group('V01', () {
    test('count of at least 1 is valid', () {
      expect(validateObservation(makeInput(count: 1), makeContext()), isEmpty);
    });
    test('count below 1 is refused', () {
      expect(validateObservation(makeInput(count: 0), makeContext()), {
        'count': ['V01'],
      });
    });
  });

  group('V02', () {
    test('missing observed_at and position are refused', () {
      final errors = validateObservation(
        makeInput(noObservedAt: true, lat: null, lon: null),
        makeContext(),
      );
      expect(errors, {
        'observed_at': ['V02'],
        'geometry': ['V02'],
      });
    });
  });

  group('V03', () {
    test('visit statuses that accept a transect observation', () {
      for (final status in ['in_progress', 'completed', 'synced', 'reviewed']) {
        expect(
          validateObservation(makeInput(), makeContext(visitStatus: status)),
          isEmpty,
          reason: status,
        );
      }
    });
    test('draft, cancelled, locked and no visit are refused', () {
      for (final status in ['draft', 'cancelled', 'locked', null]) {
        expect(
          validateObservation(makeInput(), makeContext(visitStatus: status)),
          {
            'survey_visit': ['V03'],
          },
          reason: '$status',
        );
      }
    });
    test('an incidental observation needs no visit', () {
      final errors = validateObservation(
        makeInput(source: 'incidental'),
        makeContext(visitStatus: null),
      );
      expect(errors, isEmpty);
    });
  });

  group('V04', () {
    test('inside the visit, tolerance included, is valid', () {
      final context = makeContext(visitEndedAt: ended);
      for (final at in [
        started.subtract(const Duration(minutes: 5)),
        started,
        ended,
        ended.add(const Duration(minutes: 5)),
      ]) {
        expect(
          validateObservation(makeInput(observedAt: at), context),
          isEmpty,
          reason: '$at',
        );
      }
    });
    test('outside the tolerance is refused', () {
      final context = makeContext(visitEndedAt: ended);
      for (final at in [
        started.subtract(const Duration(minutes: 6)),
        ended.add(const Duration(minutes: 6)),
      ]) {
        expect(validateObservation(makeInput(observedAt: at), context), {
          'observed_at': ['V04'],
        }, reason: '$at');
      }
    });
    test('without ended_at only the lower bound applies', () {
      final late = makeInput(observedAt: ended.add(const Duration(days: 1)));
      expect(validateObservation(late, makeContext()), isEmpty);
      final early = makeInput(
        observedAt: started.subtract(const Duration(minutes: 6)),
      );
      expect(validateObservation(early, makeContext()), {
        'observed_at': ['V04'],
      });
    });
  });

  group('V06', () {
    test('a transect observation on a true-zero visit is refused', () {
      final context = makeContext(visitZeroConfirmed: true);
      expect(validateObservation(makeInput(), context), {
        'survey_visit': ['V06'],
      });
      expect(
        validateObservation(makeInput(source: 'incidental'), context),
        isEmpty,
      );
    });
  });

  group('V07', () {
    test('unknown sex, life stage, source and confidence are refused', () {
      final errors = validateObservation(
        makeInput(sex: 'x', lifeStage: 'x', source: 'x', confidence: 'x'),
        makeContext(),
      );
      for (final field in [
        'sex',
        'life_stage',
        'source',
        'identification_confidence',
      ]) {
        expect(errors[field], ['V07'], reason: field);
      }
    });
    test('a behaviour that is not in the list is refused', () {
      expect(
        validateObservation(
          makeInput(behaviour: ['flying', 'resting']),
          makeContext(),
        ),
        isEmpty,
      );
      expect(
        validateObservation(
          makeInput(behaviour: ['flying', 'dancing']),
          makeContext(),
        ),
        {
          'behaviour': ['V07'],
        },
      );
    });
  });

  group('V08', () {
    test('the corners of the world are valid', () {
      for (final (lat, lon) in [(-90.0, -180.0), (90.0, 180.0)]) {
        expect(
          validateObservation(makeInput(lat: lat, lon: lon), makeContext()),
          isEmpty,
        );
      }
    });
    test('a position out of range is refused', () {
      for (final (lat, lon) in [(0.0, 181.0), (91.0, 0.0), (double.nan, 0.0)]) {
        expect(
          validateObservation(makeInput(lat: lat, lon: lon), makeContext()),
          {
            'geometry': ['V08'],
          },
          reason: '$lat, $lon',
        );
      }
    });
  });

  group('W01', () {
    test('photo required and none taken', () {
      expect(photoMissing(true, 0), isTrue);
      expect(photoMissing(true, 1), isFalse);
      expect(photoMissing(false, 0), isFalse);
      expect(
        observationWarnings(makeInput(), makeContext(taxonPhotoRequired: true)),
        ['W01'],
      );
      expect(
        observationWarnings(
          makeInput(),
          makeContext(taxonPhotoRequired: true, photoCount: 1),
        ),
        isEmpty,
      );
    });
  });

  group('W02', () {
    test('accuracy worse than the warning value', () {
      expect(isPoorAccuracy(25.1, 25), isTrue);
      expect(isPoorAccuracy(25, 25), isFalse);
      expect(isPoorAccuracy(null, 25), isFalse);
      expect(observationWarnings(makeInput(accuracyM: 30), makeContext()), [
        'W02',
      ]);
    });
  });

  group('W03', () {
    test('oviposition warns', () {
      expect(
        observationWarnings(
          makeInput(behaviour: ['flying', 'oviposition']),
          makeContext(),
        ),
        ['W03'],
      );
      expect(
        observationWarnings(makeInput(behaviour: ['flying']), makeContext()),
        isEmpty,
      );
    });
  });

  group('W04', () {
    test('larva warns', () {
      expect(
        observationWarnings(makeInput(lifeStage: 'larva'), makeContext()),
        ['W04'],
      );
      expect(
        observationWarnings(makeInput(lifeStage: 'pupa'), makeContext()),
        isEmpty,
      );
    });
  });
}
