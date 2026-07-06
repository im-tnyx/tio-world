import 'package:flutter/material.dart';

class TioPlaceholderPage extends StatelessWidget {
  const TioPlaceholderPage({required this.title, required this.description, super.key});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('$title\n$description', textAlign: TextAlign.center),
      ),
    );
  }
}
