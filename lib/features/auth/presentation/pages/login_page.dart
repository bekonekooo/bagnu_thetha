import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../data/services/social_auth_service.dart';
import '../widgets/social_auth_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? socialLoadingLabel;
  final SocialAuthService socialAuthService = SocialAuthService();

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('role, onboarding_completed')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  bool validateForm() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen e-posta ve şifre alanlarını doldur.'),
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

  Future<void> signIn() async {
    if (isLoading) return;

    if (!validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final authResponse = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final profile = await fetchUserProfile(user.id);

      final role = profile?['role']?.toString() ?? 'student';
      final onboardingCompleted =
          profile?['onboarding_completed'] == true;

      if (!mounted) return;

      if (role == 'teacher') {
        context.go('/teacher-dashboard');
        return;
      }

      if (!onboardingCompleted) {
        context.go('/profile-onboarding');
        return;
      }

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş hatası: $e'),
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
      final profile = await fetchUserProfile(user.id);
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
      // Provider dialog was dismissed; keep the login screen unchanged.
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
    emailController.dispose();
    passwordController.dispose();
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
          const Icon(Icons.self_improvement_outlined, color: Color(0xFFC76D4B), size: 42),
          const SizedBox(height: 18),
          const Text(
            'Yeniden Kendine',
            style: TextStyle(
              color: Color(0xFF18202A),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dönüşüm yolculuğuna kaldığın yerden devam et.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              const SizedBox(height: 32),
              const Text(
                'Hesabına giriş yap',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2438),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Seanslarını, bildirimlerini ve profilini yönetmek için giriş yap.',
                style: TextStyle(
                  color: Colors.grey,
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
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Şifre',
                controller: passwordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                hintText: 'Şifreni gir',
              ),
              const SizedBox(height: 26),
              CustomButton(
                text: 'Giriş Yap',
                isLoading: isLoading,
                icon: Icons.login,
                onPressed: signIn,
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
                          context.go('/register');
                        },
                  child: const Text('Hesabın yok mu? Kayıt ol'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
