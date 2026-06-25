import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/app/theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordAgainController = TextEditingController();

  bool isLoading = false;

  bool validateForm() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final passwordAgain = passwordAgainController.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordAgain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm zorunlu alanları doldur.'),
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

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre en az 6 karakter olmalı.'),
        ),
      );
      return false;
    }

    if (password != passwordAgain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler aynı olmalı.'),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> signUp() async {
    if (isLoading) return;

    if (!validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final authResponse = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {
          'full_name': nameController.text.trim(),
          'role': 'student',
        },
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception('Kullanıcı oluşturulamadı.');
      }

      await supabase.from('profiles').update({
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': 'student',
        'onboarding_completed': false,
      }).eq('id', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabın oluşturuldu. Şimdi profilini tamamlayalım.'),
        ),
      );

      context.go('/profile-onboarding');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(e)),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  String _friendlyAuthError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('already') ||
          message.contains('registered') ||
          message.contains('exists')) {
        return 'Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.';
      }

      if (message.contains('password')) {
        return 'Şifre güvenlik koşullarını sağlamıyor. Daha güçlü bir şifre dene.';
      }

      if (message.contains('email')) {
        return 'Lütfen geçerli bir e-posta adresi gir.';
      }

      if (message.contains('rate') || message.contains('limit')) {
        return 'Çok fazla deneme yaptın. Lütfen biraz sonra tekrar dene.';
      }
    }

    return 'Hesap oluşturulamadı. Lütfen tekrar dene.';
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordAgainController.dispose();
    super.dispose();
  }

  Widget buildHeader() {
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
              Icons.person_add_alt_1,
              color: AppTheme.primaryPurple,
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'BagnuTheta’ya Katıl',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hesabını oluştur, ardından seni daha iyi tanıyalım.',
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

  Widget buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            color: AppTheme.primaryPurple,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu adımda sadece temel hesap bilgilerini alıyoruz. Profilini bir sonraki ekranda adım adım tamamlayacaksın.',
              style: TextStyle(
                height: 1.35,
                color: Color(0xFF4B405A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              const SizedBox(height: 30),
              const Text(
                'Yeni hesap oluştur',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2438),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Önce hesabını oluşturalım. Sonraki adımda profilini kişiselleştireceğiz.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Ad Soyad *',
                controller: nameController,
                prefixIcon: Icons.badge_outlined,
                hintText: 'Adını ve soyadını yaz',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Telefon *',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                hintText: '05xx xxx xx xx',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'E-posta *',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                hintText: 'ornek@email.com',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Şifre *',
                controller: passwordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                hintText: 'En az 6 karakter',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Şifre Tekrar *',
                controller: passwordAgainController,
                isPassword: true,
                prefixIcon: Icons.lock_reset_outlined,
                hintText: 'Şifreni tekrar gir',
              ),
              const SizedBox(height: 20),
              buildInfoBox(),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Hesap Oluştur',
                isLoading: isLoading,
                icon: Icons.person_add_alt_1,
                onPressed: signUp,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.go('/login');
                        },
                  child: const Text('Zaten hesabın var mı? Giriş yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}