import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/core/validation/proposal_values.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/visits/domain/local_time.dart';

/// One row of My proposals (T108): the name, reason and date, the length, a
/// status chip, the transect it replaces, the admin's review note and, once
/// accepted, the code of the new transect.
class ProposalTile extends ConsumerWidget {
  const ProposalTile({super.key, required this.proposal});
  final TransectProposal proposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replacedId = proposal.replacesTransectId;
    final replaced = replacedId == null
        ? null
        : ref.watch(transectProvider(replacedId)).value;
    final createdId = proposal.createdTransectId;
    final created = createdId == null
        ? null
        : ref.watch(transectProvider(createdId)).value;

    // The server's length once pulled, else our estimate from the line.
    final lengthM = proposal.lengthM ?? lineLengthM(_line());
    final scheme = Theme.of(context).colorScheme;
    final sent = proposal.syncStatus == SyncStatus.synced;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proposal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    sent
                        ? proposalStatusLabel(proposal.status)
                        : 'Not sent yet',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(
              '${proposalReasonLabel(proposal.reason)} · '
              '${formatLocalDateTime(proposal.createdAt)} · '
              '${formatLength(lengthM)}',
            ),
            if (replacedId != null)
              Text('Replaces ${replaced?.code ?? 'a transect'}'),
            if (proposal.reviewNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Admin: ${proposal.reviewNote}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            if (proposal.status == 'accepted')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  created == null
                      ? 'Accepted. Sync to get the new transect.'
                      : 'New transect: ${created.code}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The proposal's line; empty when it cannot be read.
  List<LatLng> _line() => parseLineString(proposal.geometryGeojson);
}
