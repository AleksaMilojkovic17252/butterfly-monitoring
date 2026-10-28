import 'dart:convert';

/// A readable reason for a rejected queue item. [lastError] is the server's
/// `[{code, detail, fields}]` list as JSON text; the first error is used. An
/// unknown code shows the server's `detail`, and text that cannot be parsed is
/// shown as it is.
String syncErrorMessage(String? lastError) {
  if (lastError == null || lastError.isEmpty) {
    return 'The server did not say why.';
  }
  try {
    final first = (jsonDecode(lastError) as List).first as Map<String, dynamic>;
    final detail = first['detail'] as String?;
    final fields = first['fields'];
    return switch (first['code']) {
      'validation_error' =>
        fields is Map && fields.isNotEmpty
            ? 'Some values were not accepted: ${fields.keys.join(', ')}'
            : 'Some values were not accepted.',
      'not_found' => 'This record no longer exists on the server.',
      'permission_denied' => 'You are not allowed to change this record.',
      'deleted' => 'This record was deleted on the server.',
      'visit_locked' =>
        'An admin has locked this visit, so this change was not accepted. '
            'Discard it, or retry after the visit is unlocked.',
      // T034: e.g. a finished visit sent back to draft. `detail` names the move.
      'invalid_transition' =>
        detail == null
            ? "The visit's status can't change this way."
            : "The visit's status can't change this way: $detail",
      'read_only_entity' || 'unknown_entity_type' || 'operation_not_allowed' =>
        "This app version can't send this kind of change.",
      'integrity_error' =>
        'The change clashes with data already on the server.',
      'invalid_data' => 'A value is too long or out of range.',
      'mutation_id_taken' =>
        'The server refused this change\'s id. Retry sends it with a new one.',
      _ => detail ?? lastError,
    };
  } catch (_) {
    return lastError;
  }
}

/// Plural name of an entity type for the sync screen; an unknown type shows
/// its raw name.
String entityTypeLabel(String type) {
  // TODO(T044): name for observations.
  return switch (type) {
    'habitat_type' => 'Habitat types',
    'management_type' => 'Management types',
    'plant_taxon' => 'Plants',
    'survey_visit' => 'Visits',
    'survey_track_point' => 'Track points',
    'project_protocol' => 'Protocols',
    'taxon' => 'Butterfly species',
    'transect' => 'Transects',
    'transect_section' => 'Transect sections',
    'smoke_entity' => 'Test items',
    _ => type,
  };
}

/// `create` becomes "Create" and so on; an unknown value shows as it is.
String operationLabel(String operation) => switch (operation) {
  'create' => 'Create',
  'update' => 'Update',
  'delete' => 'Delete',
  'create_batch' => 'Create (batch)',
  _ => operation,
};
