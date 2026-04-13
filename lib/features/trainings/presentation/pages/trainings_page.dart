import 'package:flutter/material.dart';

class TrainingsPage extends StatelessWidget {
  const TrainingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eğitimler'),
      ),
      body: const Center(
        child: Text(
          'Eğitimler Sayfası',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}