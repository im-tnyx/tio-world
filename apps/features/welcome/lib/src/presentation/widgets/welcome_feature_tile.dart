import 'package:flutter/material.dart';

class WelcomeFeatureTile extends StatelessWidget {
  const WelcomeFeatureTile({
    required this.title,
    required this.description,
    required this.iconWidget,
    super.key,
  });

  final String title;
  final String description;
  final Widget iconWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.normal,
            color: Colors.white60,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
