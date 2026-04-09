import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "BagnuTheta’ya Hoş Geldin",
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),

            const Text(
              "Kendini keşfet, öğretmenlerle bağlantı kur ve dönüşümünü başlat.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text("Başla"),
            )
          ],
        ),
      ),
    );
  }
}