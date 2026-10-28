import 'package:flutter/material.dart';

/// The buttons under the map: a large Add butterfly, the other two entries,
/// then Pause/Resume and Finish. Sized for one thumb.
class VisitButtons extends StatelessWidget {
  const VisitButtons({
    super.key,
    required this.paused,
    required this.canPause,
    required this.onAddButterfly,
    required this.onAddPlant,
    required this.onAddHabitat,
    required this.onPause,
    required this.onFinish,
  });
  final bool paused;

  /// False while a pause or resume is saved, or when this phone does not
  /// record the visit's route.
  final bool canPause;
  final VoidCallback onAddButterfly;
  final VoidCallback onAddPlant;
  final VoidCallback onAddHabitat;
  final VoidCallback onPause;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: 8);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddButterfly,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 72),
                  textStyle: Theme.of(context).textTheme.titleLarge,
                ),
                icon: const Icon(Icons.add, size: 32),
                label: const Text('Add butterfly'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAddPlant,
                    icon: const Icon(Icons.local_florist_outlined),
                    label: const Text('Add plant'),
                  ),
                ),
                gap,
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAddHabitat,
                    icon: const Icon(Icons.forest_outlined),
                    label: const Text('Add habitat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canPause ? onPause : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                    label: Text(paused ? 'Resume' : 'Pause'),
                  ),
                ),
                gap,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFinish,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Finish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
