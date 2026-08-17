import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../data/services/social_auth_service.dart';
import '../widgets/social_auth_buttons.dart';

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
  String? socialLoadingLabel;
  final SocialAuthService socialAuthService = SocialAuthService();

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
          content: Text('Kayıt hatası: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    await _signInWithSocial(
      label: 'Google ile devam ediliyor...',
      action: socialAuthService.signInWithGoogle,
    );
  }

  Future<void> signInWithApple() async {
    await _signInWithSocial(
      label: 'Apple ile devam ediliyor...',
      action: socialAuthService.signInWithApple,
    );
  }

  Future<void> _signInWithSocial({
    required String label,
    required Future<dynamic> Function() action,
  }) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      socialLoadingLabel = label;
    });

    try {
      await action();
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı.');
      final profile = await supabase
          .from('profiles')
          .select('role, onboarding_completed')
          .eq('id', user.id)
          .maybeSingle();
      final role = profile?['role']?.toString() ?? 'student';
      final onboardingCompleted = profile?['onboarding_completed'] == true;

      if (!mounted) return;
      if (role == 'teacher') {
        context.go('/teacher-dashboard');
      } else if (!onboardingCompleted) {
        context.go('/profile-onboarding');
      } else {
        context.go('/home');
      }
    } on SocialAuthCancelledException {
      // Provider dialog was dismissed.
    } catch (_) {
      if (!mounted) return;
      final provider = label.startsWith('Google') ? 'Google' : 'Apple';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$provider ile giriş yapılamadı. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        socialLoadingLabel = null;
      });
    }
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
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DED3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_add_alt_1, color: Color(0xFFC76D4B), size: 42),
          const SizedBox(height: 18),
          const Text(
            'BagnuTheta’ya Katıl',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF18202A),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hesabını oluştur, ardından seni daha iyi tanıyalım.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF72706B),
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
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.deepPurple,
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
              const SizedBox(height: 20),
              SocialAuthButtons(
                onGoogle: signInWithGoogle,
                onApple: signInWithApple,
                isLoading: isLoading,
                loadingLabel: socialLoadingLabel,
              ),
              const SizedBox(height: 16),
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
