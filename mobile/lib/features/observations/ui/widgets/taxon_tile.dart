import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/domain/taxon_search.dart';

/// One species in the picker: the Serbian name (or the scientific one when
/// there is none), the scientific and English names under it, and a star to
/// make it a favourite.
class TaxonTile extends StatelessWidget {
  const TaxonTile({
    super.key,
    required this.taxon,
    required this.selected,
    required this.favourite,
    required this.onTap,
    required this.onToggleFavourite,
  });
  final Taxon taxon;
  final bool selected;
  final bool favourite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      onTap: onTap,
      title: Text(taxonTitle(taxon)),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: taxon.scientificName,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            if (taxon.vernacularNameEn.isNotEmpty)
              TextSpan(text: ' · ${taxon.vernacularNameEn}'),
          ],
        ),
      ),
      trailing: IconButton(
        // Kept for TalkBack, which reads the tooltip as the label.
        tooltip: favourite ? 'Remove from favourites' : 'Add to favourites',
        isSelected: favourite,
        icon: const Icon(Icons.star_outline),
        selectedIcon: const Icon(Icons.star),
        onPressed: onToggleFavourite,
      ),
    );
  }
}
