import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';

/// One skeleton ping: position, time, note and whether it was sent.
// T044: delete with the skeleton.
class PingTile extends StatelessWidget {
  const PingTile({super.key, required this.ping});
  final SkeletonPing ping;

  @override
  Widget build(BuildContext context) {
    final sent = ping.sentAt != null;
    return ListTile(
      leading: Icon(
        sent ? Icons.cloud_done : Icons.cloud_off,
        color: sent ? Colors.green : Colors.orange,
      ),
      title: Text(
        '${ping.lat.toStringAsFixed(5)}, ${ping.lon.toStringAsFixed(5)}',
      ),
      subtitle: Text(
        '${ping.observedAt.toLocal()}'
        '${ping.note.isEmpty ? '' : '\n${ping.note}'}',
      ),
      trailing: Text(sent ? 'sent' : 'pending'),
    );
  }
}
