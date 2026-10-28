import 'package:flutter/material.dart';
import 'package:mobile/features/visits/domain/beaufort.dart';

/// Bottom sheet with the 13 Beaufort forces; large rows for one thumb. Used
/// by the start form (T035) and the Finish screen (T040).
class WindPickerSheet extends StatelessWidget {
  const WindPickerSheet({super.key, this.selected});
  final int? selected;

  /// Opens the sheet and returns the picked force, or null when it is closed
  /// without a pick.
  static Future<int?> show(BuildContext context, {int? selected}) {
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => WindPickerSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (var force = 0; force <= 12; force++)
            ListTile(
              selected: force == selected,
              leading: CircleAvatar(child: Text('$force')),
              title: Text(beaufortDescriptions[force]),
              subtitle: Text(beaufortHints[force]),
              onTap: () => Navigator.pop(context, force),
            ),
        ],
      ),
    );
  }
}
