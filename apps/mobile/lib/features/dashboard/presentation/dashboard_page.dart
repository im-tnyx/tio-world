import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Dashboard',
      description: 'Your daily health and fitness overview.',
    );
  }
}
