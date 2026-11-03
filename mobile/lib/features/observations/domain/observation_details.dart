import 'dart:convert';

import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/observation_values.dart';
import 'package:mobile/features/observations/domain/behaviour_json.dart';

/// The optional details of a butterfly observation (T046): sex, life stage,
/// behaviour, confidence, microhabitat, flight direction, notes and, since
/// T052, the host and nectar plant records it links to. The
/// defaults are what a quick entry leaves, so `const ObservationDetails()`
/// changes nothing.
class ObservationDetails {
  const ObservationDetails({
    this.sex = 'unknown',
    this.lifeStage = 'adult',
    this.behaviour = const [],
    this.confidence = 'confirmed_in_field',
    this.microhabitat = '',
    this.flightDirectionDeg,
    this.notes = '',
    this.hostPlantRecordId,
    this.nectarPlantRecordId,
  });

  /// The details of a stored row. Behaviour is put in the codelist's order, so
  /// comparing it with an edited list does not see a false change.
  factory ObservationDetails.fromObservation(ButterflyObservation row) =>
      ObservationDetails(
        sex: row.sex,
        lifeStage: row.lifeStage,
        behaviour: sortBehaviour(behaviourValuesFromJson(row.behaviour)),
        confidence: row.identificationConfidence,
        microhabitat: row.microhabitat,
        flightDirectionDeg: row.flightDirectionDeg,
        notes: row.notes,
        hostPlantRecordId: row.hostPlantRecordId,
        nectarPlantRecordId: row.nectarPlantRecordId,
      );

  final String sex;
  final String lifeStage;

  /// Always in `behaviourValues` order (see [sortBehaviour]).
  final List<String> behaviour;
  final String confidence;
  final String microhabitat;

  /// Degrees clockwise from north, 0 to 359, or null when not set.
  final int? flightDirectionDeg;
  final String notes;

  /// The plant record the larva or egg-laying was seen on, or null (T052).
  final String? hostPlantRecordId;

  /// The plant record the butterfly was feeding on, or null (T052).
  final String? nectarPlantRecordId;

  /// A copy with some fields changed. It cannot set the flight direction or a
  /// plant link back to null: use [withDirection], [withHostPlant] and
  /// [withNectarPlant] for those.
  ObservationDetails copyWith({
    String? sex,
    String? lifeStage,
    List<String>? behaviour,
    String? confidence,
    String? microhabitat,
    String? notes,
  }) => ObservationDetails(
    sex: sex ?? this.sex,
    lifeStage: lifeStage ?? this.lifeStage,
    behaviour: behaviour == null ? this.behaviour : sortBehaviour(behaviour),
    confidence: confidence ?? this.confidence,
    microhabitat: microhabitat ?? this.microhabitat,
    flightDirectionDeg: flightDirectionDeg,
    notes: notes ?? this.notes,
    hostPlantRecordId: hostPlantRecordId,
    nectarPlantRecordId: nectarPlantRecordId,
  );

  /// A copy with the flight direction set, or cleared with null.
  ObservationDetails withDirection(int? degrees) => ObservationDetails(
    sex: sex,
    lifeStage: lifeStage,
    behaviour: behaviour,
    confidence: confidence,
    microhabitat: microhabitat,
    flightDirectionDeg: degrees,
    notes: notes,
    hostPlantRecordId: hostPlantRecordId,
    nectarPlantRecordId: nectarPlantRecordId,
  );

  /// A copy with the host plant link set, or cleared with null.
  ObservationDetails withHostPlant(String? plantRecordId) => ObservationDetails(
    sex: sex,
    lifeStage: lifeStage,
    behaviour: behaviour,
    confidence: confidence,
    microhabitat: microhabitat,
    flightDirectionDeg: flightDirectionDeg,
    notes: notes,
    hostPlantRecordId: plantRecordId,
    nectarPlantRecordId: nectarPlantRecordId,
  );

  /// A copy with the nectar plant link set, or cleared with null.
  ObservationDetails withNectarPlant(String? plantRecordId) =>
      ObservationDetails(
        sex: sex,
        lifeStage: lifeStage,
        behaviour: behaviour,
        confidence: confidence,
        microhabitat: microhabitat,
        flightDirectionDeg: flightDirectionDeg,
        notes: notes,
        hostPlantRecordId: hostPlantRecordId,
        nectarPlantRecordId: plantRecordId,
      );

  /// A copy with the microhabitat and the notes trimmed, as they are stored.
  ObservationDetails trimmed() => ObservationDetails(
    sex: sex,
    lifeStage: lifeStage,
    behaviour: behaviour,
    confidence: confidence,
    microhabitat: microhabitat.trim(),
    flightDirectionDeg: flightDirectionDeg,
    notes: notes.trim(),
    hostPlantRecordId: hostPlantRecordId,
    nectarPlantRecordId: nectarPlantRecordId,
  );

  /// The fields with the server's names, for a sync payload.
  Map<String, Object?> toPayload() => {
    'sex': sex,
    'life_stage': lifeStage,
    'behaviour': behaviour,
    'identification_confidence': confidence,
    'microhabitat': microhabitat,
    'flight_direction_deg': flightDirectionDeg,
    'notes': notes,
    'host_plant_record': hostPlantRecordId,
    'nectar_plant_record': nectarPlantRecordId,
  };

  /// The behaviour as the JSON text the local table stores.
  String get behaviourJson => jsonEncode(behaviour);
}

/// [values] in the order of `behaviourValues`, without repeats. Values that are
/// not in the codelist go last, so the rules still see (and refuse) them.
List<String> sortBehaviour(List<String> values) {
  final unique = values.toSet().toList();
  int position(String value) {
    final index = behaviourValues.indexOf(value);
    return index == -1 ? behaviourValues.length : index;
  }

  unique.sort((a, b) => position(a).compareTo(position(b)));
  return unique;
}
