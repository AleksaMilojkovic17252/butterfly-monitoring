import 'dart:convert';

/// The raw behaviour values from the observation's JSON text
/// (`["flying","resting"]`). Bad JSON counts as no behaviour. Turn a value
/// into its label with `observationValueLabel`.
List<String> behaviourValuesFromJson(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return [for (final b in decoded) '$b'];
  } on FormatException {
    return [];
  }
}
