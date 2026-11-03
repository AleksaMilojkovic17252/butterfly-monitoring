import 'package:mobile/core/db/app_database.dart';

/// The title of a habitat type: the English name, else the code (the rule
/// `SectionWithHabitat.habitatName` uses).
String habitatTypeTitle(HabitatType type) =>
    type.nameEn.isNotEmpty ? type.nameEn : type.code;

/// The title of a management type: the English name, else the code.
String managementTypeTitle(ManagementType type) =>
    type.nameEn.isNotEmpty ? type.nameEn : type.code;
