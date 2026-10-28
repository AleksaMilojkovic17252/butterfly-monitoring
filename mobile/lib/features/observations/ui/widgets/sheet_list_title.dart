import 'package:flutter/material.dart';

/// A small heading over a list in the sheet ("Recent", "Favourites").
class SheetListTitle extends StatelessWidget {
  const SheetListTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
