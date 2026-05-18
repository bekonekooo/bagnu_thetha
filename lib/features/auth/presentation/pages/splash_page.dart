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
    await Future.delayed(const Duration(milliseconds: 500));

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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.self_improvement,
              size: 72,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 20),
            Text(
              'BagnuTheta',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 28),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}