import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CustomTextField(label: "Ad Soyad"),
            const SizedBox(height: 16),
            const CustomTextField(label: "E-posta"),
            const SizedBox(height: 16),
            const CustomTextField(label: "Şifre", isPassword: true),
            const SizedBox(height: 24),

            CustomButton(
              text: "Kayıt Ol",
              onPressed: () {
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}