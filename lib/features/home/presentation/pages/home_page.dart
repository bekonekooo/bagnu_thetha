import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';

import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .single();

    setState(() {
      profile = data;
      isLoading = false;
    });
  }

  void goToPage(String route) {
    context.go(route);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final fullName = profile?['full_name'] ?? '';
    final email = profile?['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BagnuTheta'),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                fullName: fullName,
                email: email,
              ),
              const SizedBox(height: 24),
              HomeMenuGrid(
                onTap: goToPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}