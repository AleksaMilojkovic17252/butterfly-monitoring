import 'dart:convert';

import 'package:mobile/core/validation/rule_messages.dart';

/// A readable reason for a rejected queue item. [lastError] is the server's
/// `[{code, detail, fields}]` list as JSON text; the first error is used. An
/// unknown code shows the server's `detail`, and text that cannot be parsed is
/// shown as it is. A `validation_error` names each field with its message; a
/// rule ID such as `V04` (T055) becomes its sentence.
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
            ? 'Not accepted: ${_fieldMessages(fields)}.'
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

/// "The count must be at least 1 (count); ...": each message of each field,
/// with the field in brackets. A rule ID is replaced by its sentence, any
/// other text is the server's own. A nested error (an error of one list item)
/// is flattened to its messages, and `non_field_errors` has no field name.
String _fieldMessages(Map fields) {
  final parts = <String>[];
  for (final MapEntry(:key, :value) in fields.entries) {
    for (final message in _messagesOf(value)) {
      final readable = isRuleId(message) ? ruleMessage(message) : message;
      // "A value is too long." and "A value is too long" read the same here.
      final sentence = readable.endsWith('.')
          ? readable.substring(0, readable.length - 1)
          : readable;
      parts.add(key == 'non_field_errors' ? sentence : '$sentence ($key)');
    }
  }
  return parts.join('; ');
}

/// Every message text inside [value]: a string, a list or a map of them.
List<String> _messagesOf(Object? value) {
  if (value is List) return [for (final item in value) ..._messagesOf(item)];
  if (value is Map) {
    return [for (final item in value.values) ..._messagesOf(item)];
  }
  return [value.toString()];
}

/// Plural name of an entity type for the sync screen; an unknown type shows
/// its raw name.
String entityTypeLabel(String type) {
  return switch (type) {
    'butterfly_observation' => 'Butterfly observations',
    'habitat_type' => 'Habitat types',
    'management_type' => 'Management types',
    'photo' => 'Photo records',
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
