import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş hatası: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(
              label: 'E-posta',
              controller: emailController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Şifre',
              controller: passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: isLoading ? 'Yükleniyor...' : 'Giriş Yap',
              onPressed: isLoading ? () {} : signIn,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                context.go('/register');
              },
              child: const Text('Hesabın yok mu? Kayıt ol'),
            ),
          ],
        ),
      ),
    );
  }
}