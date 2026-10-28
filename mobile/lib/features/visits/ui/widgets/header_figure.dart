import 'package:flutter/material.dart';

/// One figure of the visit header: a large value over a small label.
class HeaderFigure extends StatelessWidget {
  const HeaderFigure({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: text.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: text.labelSmall),
      ],
    );
  }
}
