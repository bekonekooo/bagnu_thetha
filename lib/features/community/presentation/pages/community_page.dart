import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk'),
      ),
      body: const Center(
        child: Text(
          'Topluluk Sayfası',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}