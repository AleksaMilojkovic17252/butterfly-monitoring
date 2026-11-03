import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/ui/widgets/sheet_list_title.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/plant_taxon_search.dart';

/// What the species sheet answers: the chosen plant, or `id: null` for
/// "Unidentified plant". Closing the sheet without choosing answers null.
typedef PlantPick = ({String? id});

/// The plant species sheet of the plant form (T052): a search field over the
/// plants, with **Unidentified plant** on top and, before anything is typed,
/// the plants of the user's own recent records. Deactivated plants are not
/// offered, but a record keeps the name it was saved with.
class PlantTaxonPickerSheet extends ConsumerStatefulWidget {
  const PlantTaxonPickerSheet({
    super.key,
    required this.projectId,
    required this.selectedId,
  });
  final String projectId;

  /// The plant that is chosen now, highlighted.
  final String? selectedId;

  /// Opens the sheet and returns the choice, or null when it was closed.
  static Future<PlantPick?> show(
    BuildContext context, {
    required String projectId,
    required String? selectedId,
  }) {
    return showModalBottomSheet<PlantPick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          PlantTaxonPickerSheet(projectId: projectId, selectedId: selectedId),
    );
  }

  @override
  ConsumerState<PlantTaxonPickerSheet> createState() =>
      _PlantTaxonPickerSheetState();
}

class _PlantTaxonPickerSheetState extends ConsumerState<PlantTaxonPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _tile(PlantTaxon plant) {
    return ListTile(
      selected: plant.id == widget.selectedId,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      title: Text(plantTitle(plant)),
      subtitle: Text(
        plant.scientificName,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
      onTap: () => Navigator.pop<PlantPick>(context, (id: plant.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(pickerPlantTaxaProvider).value ?? [];
    final records =
        ref.watch(plantRecordsProvider(widget.projectId)).value ?? [];
    final query = _search.text;
    final results = searchPlantTaxa(plants, query);
    final recent = recentPlantTaxa(plants, records);

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: screenHeight * 0.9 - keyboardHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search a plant',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Unidentified plant'),
              subtitle: const Text('Add notes to describe it'),
              selected: widget.selectedId == null,
              onTap: () => Navigator.pop<PlantPick>(context, (id: null)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: query.trim().isEmpty
                    ? [
                        const SheetListTitle('Recent'),
                        if (recent.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text('Plants you record show up here.'),
                          )
                        else
                          for (final plant in recent) _tile(plant),
                      ]
                    : results.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text('No plant matches "${query.trim()}".'),
                        ),
                      ]
                    : [for (final plant in results) _tile(plant)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
