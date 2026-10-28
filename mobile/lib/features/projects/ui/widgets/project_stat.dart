import 'package:flutter/material.dart';

/// A small icon and label, one per number on the project card.
class ProjectStat extends StatelessWidget {
  const ProjectStat({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(text)],
    );
  }
}
