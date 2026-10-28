import 'package:flutter/material.dart';

/// A centred sentence instead of the start-visit form.
class StartVisitMessage extends StatelessWidget {
  const StartVisitMessage(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(text)),
    );
  }
}
