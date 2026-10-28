import 'package:mobile/core/validation/rule_messages.dart';

/// Thrown by `VisitRepository.finish` and `checkCanFinish` when a visit rule
/// (V05-V07) refuses the visit. [errors] is the rule result, field to rule
/// IDs, so the Finish screen can word it for the observer. [toString] is the
/// plain rule sentences. A [StateError] cannot be extended, hence its own
/// class.
class VisitRuleError implements Exception {
  const VisitRuleError(this.errors);
  final Map<String, List<String>> errors;

  /// True when [ruleId] (for example `V05`) is among the errors.
  bool has(String ruleId) => errors.values.any((ids) => ids.contains(ruleId));

  @override
  String toString() => ruleErrorText(errors);
}
