import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const PlaceholderPage(
        title: 'Profile',
        description: 'Manage your personal information and health data.',
      ),
    );
  }
}
