import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CustomTextField(label: "E-posta"),
            const SizedBox(height: 16),
            const CustomTextField(label: "Şifre", isPassword: true),
            const SizedBox(height: 24),

            CustomButton(
              text: "Giriş Yap",
              onPressed: () {
                context.go('/home');
              },
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                context.go('/register');
              },
              child: const Text("Hesabın yok mu? Kayıt ol"),
            )
          ],
        ),
      ),
    );
  }
}