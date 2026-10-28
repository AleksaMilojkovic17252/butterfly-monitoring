import 'package:flutter/material.dart';

/// A screen with only a message, for a visit that cannot be shown.
class VisitMessageScreen extends StatelessWidget {
  const VisitMessageScreen(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
