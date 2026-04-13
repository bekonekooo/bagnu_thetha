import 'package:flutter/material.dart';

class GuidancePage extends StatelessWidget {
  const GuidancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Rehberlik'),
      ),
      body: const Center(
        child: Text(
          'Aylık Rehberlik Sayfası',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}