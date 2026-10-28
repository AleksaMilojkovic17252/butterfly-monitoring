// One readable sentence for each rule ID of
// docs/requirements/validation-rules.md. The server answers a rejected save
// with the ID only (`{"observed_at": ["V04"]}`), and the app's own checks use
// the same IDs.

const ruleMessages = {
  'V01': 'The count must be at least 1',
  'V02': 'The time and the position are required',
  'V03': 'A butterfly can only be added to a visit that is in progress or finished',
  'V04': "The observation time is outside the visit's time",
  'V05': 'The weather at the start and at the end, or a reason, is required',
  'V06': 'The true-zero confirmation does not match the butterfly records',
  'V07': 'A value is not one of the allowed choices',
  'V08': 'The position is not valid',
  'W01': 'This species needs a photo. The record will wait for validation',
  'W02': 'Low GPS accuracy',
  'W03': 'Egg-laying: link the host plant',
  'W04': 'Larva: link the host plant',
  'W06': 'The weather is outside the protocol',
  'W07': 'The visit is outside the season or the daily time window',
};

/// A rule ID looks like `V04` or `W01`.
final _ruleId = RegExp(r'^[VW]\d\d$');

bool isRuleId(String text) => _ruleId.hasMatch(text);

/// The sentence for [id] (no full stop at the end); an unknown ID is returned
/// as it is.
String ruleMessage(String id) => ruleMessages[id] ?? id;

/// The sentences of every error in [errors] (field to rule IDs), without
/// repeats, as one text: "The count must be at least 1. The position is not
/// valid."
String ruleErrorText(Map<String, List<String>> errors) {
  final sentences = <String>{
    for (final ids in errors.values)
      for (final id in ids) ruleMessage(id),
  };
  return '${sentences.join('. ')}.';
}
