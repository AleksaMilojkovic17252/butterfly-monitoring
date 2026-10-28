import 'package:flutter/material.dart';

/// One row of the protocol summary: an icon and a sentence.
class ProtocolSummaryLine extends StatelessWidget {
  const ProtocolSummaryLine(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(dense: true, leading: Icon(icon), title: Text(text));
  }
}
