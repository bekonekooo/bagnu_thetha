import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/notifications/data/presentation/widgets/notification_badge_button.dart';

import '../../data/models/home_daily_message_model.dart';
import '../../data/services/home_daily_message_service.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';
import '../widgets/home_meditation_spotlight_section.dart';

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

  static bool introShownThisAppSession = false;

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

    if (!mounted) return;

    showIntroIfReady();
  }

  void showIntroIfReady() {
    if (introShownThisAppSession) return;
    if (isLoading) return;
    if (isMessageLoading) return;

    introShownThisAppSession = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final messageTitle =
          homeDailyMessage?.title ?? HomeDailyMessageModel.fallback.title;
      final messageSubtitle =
          homeDailyMessage?.subtitle ?? HomeDailyMessageModel.fallback.subtitle;

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Günün mesajı',
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenDailyMessageDialog(
            title: messageTitle,
            subtitle: messageSubtitle,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 1.03,
                end: 1,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      );
    });
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
              child: CircularProgressIndicator(
                color: Color(0xFF536B4E),
              ),
            ),
          ),
        ),
      );
    }

    final fullName = profile?['full_name']?.toString() ?? '';
    final email = profile?['email']?.toString() ?? '';

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
                      HomeMenuGrid(
                        onTap: goToPage,
                      ),
                      const SizedBox(height: 32),
                      HomeMeditationSpotlightSection(
                        onSeeAllTap: () {
                          context.go('/meditations');
                        },
                      ),
                      const SizedBox(height: 32),
                      _HomeDailyMessageCard(
                        title: homeDailyMessage?.title ??
                            HomeDailyMessageModel.fallback.title,
                        subtitle: homeDailyMessage?.subtitle ??
                            HomeDailyMessageModel.fallback.subtitle,
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
  final String title;
  final String subtitle;

  const _HomeDailyMessageCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.68),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3EA).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(17),
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
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Bugünün Mesajı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F3A32),
              height: 1.12,
              letterSpacing: -0.55,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.45,
              color: Color(0xFF4F5A51),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenDailyMessageDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const _FullScreenDailyMessageDialog({
    required this.title,
    required this.subtitle,
  });

  @override
  State<_FullScreenDailyMessageDialog> createState() =>
      _FullScreenDailyMessageDialogState();
}

class _FullScreenDailyMessageDialogState
    extends State<_FullScreenDailyMessageDialog> {
  Timer? timer;
  bool isClosing = false;

  @override
  void initState() {
    super.initState();

    timer = Timer(
      const Duration(seconds: 4),
      closeDialog,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> closeDialog() async {
    if (!mounted) return;
    if (isClosing) return;

    timer?.cancel();

    setState(() {
      isClosing = true;
    });

    await Future.delayed(const Duration(milliseconds: 520));

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: closeDialog,
      child: Material(
        color: Colors.black,
        child: AnimatedOpacity(
          opacity: isClosing ? 0 : 1,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                child: Column(
                  children: [
                    const Spacer(),
                    AnimatedSlide(
                      offset: isClosing
                          ? const Offset(0, 0.06)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeInOutCubic,
                      child: AnimatedScale(
                        scale: isClosing ? 0.96 : 1,
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeInOutCubic,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.75),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.08),
                                blurRadius: 36,
                                offset: const Offset(0, 0),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFEEF3EA).withOpacity(0.95),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD7E1D0),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.spa_outlined,
                                  color: Color(0xFF536B4E),
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Bugünün mesajı',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF667064),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2F3A32),
                                  height: 1.12,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF4F5A51),
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF3EA),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Devam etmek için dokun',
                                  style: TextStyle(
                                    color: Color(0xFF536B4E),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}