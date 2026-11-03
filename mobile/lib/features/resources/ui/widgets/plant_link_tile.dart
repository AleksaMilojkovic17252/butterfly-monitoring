import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/plant_links.dart';
import 'package:mobile/features/resources/domain/plant_taxon_search.dart';
import 'package:mobile/features/resources/ui/widgets/plant_link_sheet.dart';

/// One link of the butterfly Details form (T052): "Host plant" or "Nectar
/// plant". It shows the linked plant's name or "Not linked", a button to clear
/// the link, and opens [PlantLinkSheet] on tap. The form owns the value:
/// [onChanged] gets the new record id, or null when cleared.
class PlantLinkTile extends ConsumerWidget {
  const PlantLinkTile({
    super.key,
    required this.role,
    required this.projectId,
    required this.visitId,
    required this.value,
    required this.onChanged,
  });
  final PlantLinkRole role;
  final String projectId;

  /// The observation's visit, so the sheet lists its plant records first.
  final String? visitId;

  /// The id of the linked plant record, or null.
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = value;
    final record = id == null ? null : ref.watch(plantRecordProvider(id)).value;
    final taxonId = record?.plantTaxonId;
    final plant = taxonId == null
        ? null
        : ref.watch(plantTaxaByIdsProvider(taxonId)).value?.firstOrNull;
    final name = id == null
        ? 'Not linked'
        : record == null
        ? 'Linked plant record'
        : plant == null
        ? 'Unidentified plant'
        : plantTitle(plant);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.local_florist_outlined),
      title: Text(plantLinkLabel(role)),
      subtitle: Text(name),
      trailing: id == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              tooltip: 'Remove the link',
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
      onTap: () async {
        final chosen = await PlantLinkSheet.show(
          context,
          role: role,
          projectId: projectId,
          visitId: visitId,
          selectedId: id,
        );
        if (chosen != null) onChanged(chosen);
      },
    );
  }
}
