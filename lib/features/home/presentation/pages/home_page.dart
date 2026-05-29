import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/notifications/data/presentation/widgets/notification_badge_button.dart';

import '../../data/models/home_daily_message_model.dart';
import '../../data/services/home_daily_message_service.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeDailyMessageService _homeDailyMessageService =
      HomeDailyMessageService();

  Map<String, dynamic>? profile;
  HomeDailyMessageModel? homeDailyMessage;

  bool isLoading = true;
  bool isMessageLoading = true;

  static const String homeBackground =
      'assets/images/backgrounds/home_bg_1.jpg';

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    await Future.wait([
      getProfile(),
      getHomeDailyMessage(),
    ]);
  }

  Future<void> getProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil bilgisi yüklenemedi: $e')),
      );
    }
  }

  Future<void> getHomeDailyMessage() async {
    try {
      final message = await _homeDailyMessageService.getMessageForHome();

      if (!mounted) return;

      setState(() {
        homeDailyMessage = message;
        isMessageLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        homeDailyMessage = HomeDailyMessageModel.fallback;
        isMessageLoading = false;
      });
    }
  }

  Future<void> refreshHome() async {
    await Future.wait([
      getProfile(),
      getHomeDailyMessage(),
    ]);
  }

  void goToPage(String route) {
    context.go(route);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    context.go('/login');
  }

  Future<void> confirmSignOut() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Çıkış yap'),
          content: const Text('Hesabınızdan çıkış yapmak istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(homeBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    final fullName = profile?['full_name']?.toString() ?? '';
    final email = profile?['email']?.toString() ?? '';

    final messageTitle =
        homeDailyMessage?.title ?? HomeDailyMessageModel.fallback.title;
    final messageSubtitle =
        homeDailyMessage?.subtitle ?? HomeDailyMessageModel.fallback.subtitle;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'BagnuTheta',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F3A32),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          const NotificationBadgeButton(),
          IconButton(
            onPressed: confirmSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            color: const Color(0xFF2F3A32),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              homeBackground,
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.05),
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: refreshHome,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeHeader(
                        fullName: fullName,
                        email: email,
                      ),
                      const SizedBox(height: 24),

                      _HomeDailyMessageCard(
                        isLoading: isMessageLoading,
                        title: messageTitle,
                        subtitle: messageSubtitle,
                      ),

                      const SizedBox(height: 20),

                      HomeMenuGrid(
                        onTap: goToPage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDailyMessageCard extends StatelessWidget {
  final bool isLoading;
  final String title;
  final String subtitle;

  const _HomeDailyMessageCard({
    required this.isLoading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 72,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF536B4E),
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3EA).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD7E1D0),
                    ),
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: Color(0xFF536B4E),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bugünün mesajı',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667064),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F3A32),
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF606A61),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}