import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/notifications/data/presentation/widgets/notification_badge_button.dart';

import '../../data/models/home_daily_message_model.dart';
import '../../data/services/home_daily_message_service.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';
import '../widgets/home_recently_played_section.dart';
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
          backgroundColor: const Color(0xFFFFFCF6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Çıkış yap',
            style: TextStyle(
              color: Color(0xFF2F3A32),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Hesabınızdan çıkış yapmak istiyor musunuz?',
            style: TextStyle(
              color: Color(0xFF4F5A51),
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Vazgeç',
                style: TextStyle(
                  color: Color(0xFF536B4E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536B4E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await signOut();
    }
  }

  Widget buildSoftBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: const Color(0xFFF7F4EC),
          ),
        ),
        Positioned(
          top: -90,
          right: -90,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD7E1D0).withOpacity(0.75),
            ),
          ),
        ),
        Positioned(
          top: 190,
          left: -120,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEEF3EA).withOpacity(0.95),
            ),
          ),
        ),
        Positioned(
          bottom: -130,
          right: -80,
          child: Container(
            width: 290,
            height: 290,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE9DFC8).withOpacity(0.70),
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
                  Colors.white.withOpacity(0.32),
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.20),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4EC),
        body: buildSoftBackground(
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF536B4E),
            ),
          ),
        ),
      );
    }

    final fullName = profile?['full_name']?.toString() ?? '';
    final email = profile?['email']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EC),
      appBar: AppBar(
        title: const Text(
          'BagnuTheta',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF2F3A32),
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: const Color(0xFFF7F4EC).withOpacity(0.96),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
        actions: [
          const NotificationBadgeButton(),
          IconButton(
            onPressed: confirmSignOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            color: const Color(0xFF2F3A32),
          ),
        ],
      ),
      body: buildSoftBackground(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: refreshHome,
            color: const Color(0xFF536B4E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(
                      fullName: fullName,
                      email: email,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Bugün ne yapmak istersin?',
                      subtitle: 'Seanslar, meditasyonlar ve özel alanların.',
                    ),
                    const SizedBox(height: 14),
                    HomeMenuGrid(
                      onTap: goToPage,
                    ),
                    const SizedBox(height: 30),
                    const HomeRecentlyPlayedSection(),
                    const SizedBox(height: 30),
                    HomeMeditationSpotlightSection(
                      onSeeAllTap: () {
                        context.go('/meditations');
                      },
                    ),
                    const SizedBox(height: 30),
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
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6D766B),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
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
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE8DDC9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF536B4E).withOpacity(0.10),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3EA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFD7E1D0),
                  ),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Color(0xFF536B4E),
                  size: 27,
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