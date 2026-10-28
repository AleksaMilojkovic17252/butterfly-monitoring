import 'package:flutter/material.dart';

/// Small heading above each card of the transect detail page.
class DetailSectionTitle extends StatelessWidget {
  const DetailSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
