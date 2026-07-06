import 'package:flutter/material.dart';

class TioShellPlaceholder extends StatelessWidget {
  const TioShellPlaceholder({required this.title, required this.description, super.key});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$title\n$description', textAlign: TextAlign.center),
    );
  }
}
