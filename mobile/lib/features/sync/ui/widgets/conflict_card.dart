import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/sync/domain/sync_error_message.dart';

/// A conflict, read only: an admin settles it in Django admin.
class ConflictCard extends StatelessWidget {
  const ConflictCard({super.key, required this.conflict});
  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
    final resolvedAt = conflict.resolvedAt;
    final String text;
    if (conflict.status == 'open') {
      text = 'An admin will resolve this. Your change is kept on the server.';
    } else {
      final winner = conflict.status == 'resolved_server'
          ? 'Server version kept'
          : 'Your change applied';
      final when = resolvedAt == null
          ? ''
          : ' · ${_formatTime(context, resolvedAt)}';
      final note = conflict.resolutionNote.isEmpty
          ? ''
          : '\n${conflict.resolutionNote}';
      text = '$winner$when$note';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entityTypeLabel(conflict.entityType)} · '
              '${operationLabel(conflict.operation)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text('Fields: ${_fieldsText(conflict.conflictingFields)}'),
            const SizedBox(height: 4),
            Text(text),
          ],
        ),
      ),
    );
  }
}

/// The conflicting field names, stored as a JSON list.
String _fieldsText(String json) {
  try {
    return (jsonDecode(json) as List).join(', ');
  } catch (_) {
    return json;
  }
}

/// Local date and time, like the Settings sync tile.
String _formatTime(BuildContext context, DateTime time) {
  final localizations = MaterialLocalizations.of(context);
  final local = time.toLocal();
  return '${localizations.formatShortDate(local)}, '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
