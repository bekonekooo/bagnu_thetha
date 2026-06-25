import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/app/theme.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';

import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen e-posta adresini gir.'),
        ),
      );
      return false;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir e-posta adresi gir.'),
        ),
      );
      return false;
    }

    return true;
  }

  String _friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('rate') || message.contains('limit')) {
        return 'Çok fazla deneme yaptın. Lütfen biraz sonra tekrar dene.';
      }

      if (message.contains('email')) {
        return 'E-posta adresini kontrol edip tekrar dene.';
      }
    }

    return 'Bir şeyler ters gitti. Lütfen tekrar dene.';
  }

  Future<void> sendResetLink() async {
    if (isLoading) return;

    if (!_validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await supabase.auth.resetPasswordForEmail(
        emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sıfırlama bağlantısı e-postana gönderildi'),
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryPurple,
            AppTheme.darkPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.lock_reset,
              color: AppTheme.primaryPurple,
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Şifreni mi unuttun?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'E-posta adresini gir, sana sıfırlama bağlantısı gönderelim.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softCream,
      appBar: AppBar(
        title: const Text('Şifre Sıfırlama'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              const Text(
                'Sıfırlama bağlantısı al',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hesabına kayıtlı e-posta adresine bir bağlantı göndereceğiz.',
                style: TextStyle(
                  color: AppTheme.textSoft,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'E-posta',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                hintText: 'ornek@email.com',
              ),
              const SizedBox(height: 26),
              CustomButton(
                text: 'Sıfırlama bağlantısı gönder',
                isLoading: isLoading,
                icon: Icons.send_outlined,
                onPressed: sendResetLink,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                  child: const Text('Girişe geri dön'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
