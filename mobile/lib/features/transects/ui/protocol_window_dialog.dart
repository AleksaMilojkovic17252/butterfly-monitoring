import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/protocol_window.dart';

/// Warns (without blocking) when now is outside the protocol's season or daily
/// time window (T035). Returns true when there is nothing to warn about or the
/// observer taps "Start anyway", and false on Cancel, a dismissed dialog or a
/// [context] that is no longer mounted.
///
/// Shared by transect detail and the draft sheet of the Start visit tile
/// (T105), so the window check stays in one place.
Future<bool> confirmProtocolWindow(
  BuildContext context,
  ProjectProtocol? protocol,
) async {
  final now = DateTime.now();
  final warnings = protocol == null
      ? <String>[]
      : [
          seasonWarning(protocol, now),
          timeWindowWarning(protocol, now),
        ].nonNulls.toList();
  if (warnings.isEmpty) return true;

  final goOn = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: const Text('Outside the protocol window'),
      content: Text(warnings.join('\n')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          child: const Text('Start anyway'),
        ),
      ],
    ),
  );
  return goOn == true && context.mounted;
}
