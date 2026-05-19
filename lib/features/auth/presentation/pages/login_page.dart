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

  Future<String> fetchUserRole(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return response?['role']?.toString() ?? 'student';
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

      final role = await fetchUserRole(user.id);

      if (!mounted) return;

      if (role == 'teacher') {
        context.go('/teacher-dashboard');
      } else {
        context.go('/home');
      }
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
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.20),
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
              Icons.self_improvement,
              color: Colors.deepPurple,
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'BagnuTheta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dönüşüm yolculuğuna kaldığın yerden devam et.',
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

              const SizedBox(height: 18),

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