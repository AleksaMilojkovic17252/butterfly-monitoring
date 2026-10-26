import 'package:mobile/core/db/app_database.dart';

/// A transect section with its habitat type (null when none is set).
class SectionWithHabitat {
  const SectionWithHabitat(this.section, this.habitat);
  final TransectSection section;
  final HabitatType? habitat;

  /// English name of the habitat type, else its code, else null.
  String? get habitatName {
    final h = habitat;
    if (h == null) return null;
    return h.nameEn.isNotEmpty ? h.nameEn : h.code;
  }
}
