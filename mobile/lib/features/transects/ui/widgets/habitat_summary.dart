import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';

/// The transect's habitat description, plus the habitat types of its sections.
class HabitatSummary extends StatelessWidget {
  const HabitatSummary(this.transect, this.sections, {super.key});
  final Transect transect;
  final List<SectionWithHabitat> sections;

  @override
  Widget build(BuildContext context) {
    // Each habitat type once, in walking order.
    final types = sections.map((s) => s.habitatName).nonNulls.toSet();
    return Column(
      children: [
        ListTile(
          title: Text(
            transect.habitatSummary.isEmpty
                ? 'No habitat description'
                : transect.habitatSummary,
          ),
        ),
        if (types.isNotEmpty)
          ListTile(
            dense: true,
            leading: const Icon(Icons.grass_outlined),
            title: Text(types.join(', ')),
          ),
      ],
    );
  }
}
