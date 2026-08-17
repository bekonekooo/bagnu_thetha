import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/supabase_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    checkAuthAndRedirect();
  }

  Future<String> fetchUserRole(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return response?['role']?.toString() ?? 'student';
    } catch (_) {
      return 'student';
    }
  }

  Future<void> checkAuthAndRedirect() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = supabase.auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      context.go('/login');
      return;
    }

    final role = await fetchUserRole(user.id);

    if (!mounted) return;

    if (role == 'teacher') {
      context.go('/teacher-dashboard');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(28),
        color: const Color(0xFFF5F0E8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Color(0xFFFFFDF9),
              child: Icon(
                Icons.self_improvement,
                size: 58,
                color: Color(0xFFC76D4B),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Yeniden Kendine',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18202A),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Dönüşüm yolculuğun başlıyor...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF72706B),
                height: 1.35,
              ),
            ),
            SizedBox(height: 34),
            CircularProgressIndicator(
              color: Color(0xFFC76D4B),
            ),
          ],
        ),
      ),
    );
  }
}
