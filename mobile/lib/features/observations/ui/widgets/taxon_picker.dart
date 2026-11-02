import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/observations/domain/taxon_search.dart';
import 'package:mobile/features/observations/ui/widgets/sheet_list_title.dart';
import 'package:mobile/features/observations/ui/widgets/taxon_tile.dart';

/// The species picker of the entry and edit sheets: a search field over the
/// Recent and Favourites lists (or the search results). It fills the space it
/// gets, and keeps its own search text, which is lost when the picker is
/// closed. [selectedId] is highlighted; [onSelected] gets the tapped species.
class TaxonPicker extends ConsumerStatefulWidget {
  const TaxonPicker({
    super.key,
    required this.projectId,
    required this.selectedId,
    required this.onSelected,
  });
  final String projectId;
  final String? selectedId;
  final ValueChanged<Taxon> onSelected;

  @override
  ConsumerState<TaxonPicker> createState() => _TaxonPickerState();
}

class _TaxonPickerState extends ConsumerState<TaxonPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taxa = ref.watch(pickerTaxaProvider).value ?? [];
    final usage = ref.watch(taxonUsageProvider(widget.projectId)).value ?? [];
    final repository = ref.read(taxonRepositoryProvider);
    final favouriteIds = {
      for (final u in usage)
        if (u.isFavourite) u.taxonId,
    };

    final query = _search.text;
    final results = searchTaxa(taxa, query);

    Widget tile(Taxon taxon) => TaxonTile(
      taxon: taxon,
      selected: taxon.id == widget.selectedId,
      favourite: favouriteIds.contains(taxon.id),
      onTap: () => widget.onSelected(taxon),
      onToggleFavourite: () =>
          repository.toggleFavourite(widget.projectId, taxon.id),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search a species',
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
        Expanded(
          child: ListView(
            children: query.trim().isEmpty
                ? [
                    const SheetListTitle('Recent'),
                    ..._tilesOrHint(
                      recentTaxa(taxa, usage),
                      'Species you save show up here.',
                      tile,
                    ),
                    const SheetListTitle('Favourites'),
                    ..._tilesOrHint(
                      favouriteTaxa(taxa, usage),
                      'Tap a star to keep a species here.',
                      tile,
                    ),
                  ]
                : _tilesOrHint(
                    results,
                    'No species matches "${query.trim()}".',
                    tile,
                  ),
          ),
        ),
      ],
    );
  }

  /// A tile for each of [taxa], or the [hint] when there are none.
  List<Widget> _tilesOrHint(
    List<Taxon> taxa,
    String hint,
    Widget Function(Taxon) tile,
  ) {
    if (taxa.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(hint),
        ),
      ];
    }
    return [for (final taxon in taxa) tile(taxon)];
  }
}
