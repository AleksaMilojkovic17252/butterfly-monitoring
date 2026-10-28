import 'package:flutter/material.dart';

/// The start-visit form's live weather check: what is missing, suitable, or
/// which thresholds fail. [failed] is null while the weather is incomplete.
class WeatherSuitability extends StatelessWidget {
  const WeatherSuitability({super.key, required this.failed});
  final List<String>? failed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failed = this.failed;
    if (failed == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Fill in temperature and wind'),
          subtitle: Text('The weather is then checked against the protocol.'),
        ),
      );
    }
    if (failed.isEmpty) {
      return Card(
        color: scheme.primaryContainer,
        child: const ListTile(
          leading: Icon(Icons.check_circle_outline),
          title: Text('Weather is suitable'),
        ),
      );
    }
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: const Text('Weather is outside the protocol'),
        subtitle: Text(failed.join('\n')),
      ),
    );
  }
}
