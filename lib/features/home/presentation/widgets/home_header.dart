import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../data/services/greeting_card_service.dart';

class HomeHeader extends StatefulWidget {
  final String fullName;
  final String email;

  const HomeHeader({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GreetingCardService _greetingCardService = GreetingCardService();

  String? greetingMessage;
  bool isGreetingLoading = true;
  int currentPage = 0;
  int previousPage = 0;

  int messageAnimationKey = 0;

  @override
  void initState() {
    super.initState();
    loadGreetingCard();
  }

  Future<void> playCardSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/card_flip.mp3'));
      debugPrint('✅ Card sound played successfully');
    } catch (e) {
      debugPrint('❌ Card sound could not be played: $e');

      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('sounds/card_flip.wav'));
        debugPrint('✅ .wav ile çalındı');
      } catch (secondError) {
        debugPrint('❌ Wav sound also failed: $secondError');
      }
    }
  }

  Future<void> loadGreetingCard() async {
    try {
      final message = await _greetingCardService.fetchNextGreetingMessage();

      if (!mounted) return;

      setState(() {
        greetingMessage = message;
        isGreetingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        greetingMessage = null;
        isGreetingLoading = false;
      });

      debugPrint('Greeting card could not be loaded: $e');
    }
  }

  Future<void> changePage(int targetPage) async {
    if (targetPage == currentPage) return;

    await playCardSound();

    if (!mounted) return;

    setState(() {
      previousPage = currentPage;
      currentPage = targetPage;

      if (targetPage == 1) {
        messageAnimationKey++;
      }
    });
  }

  Future<void> togglePage() async {
    if (currentPage == 0) {
      await changePage(1);
    } else {
      await changePage(0);
    }
  }

  void handleVerticalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity < -250 && currentPage == 0) {
      changePage(1);
    } else if (velocity > 250 && currentPage == 1) {
      changePage(0);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.fullName.trim().isEmpty
        ? 'BagnuTheta öğrencisi'
        : widget.fullName;

    final isGoingToGreeting = currentPage == 1 && previousPage == 0;

    return Column(
      children: [
        GestureDetector(
          onVerticalDragEnd: handleVerticalSwipe,
          child: SizedBox(
            height: 245,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              reverseDuration: const Duration(milliseconds: 1300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final isIncoming = child.key == ValueKey('page-$currentPage');

                final incomingYOffset = isGoingToGreeting ? 0.28 : -0.28;
                final outgoingYOffset = isGoingToGreeting ? -0.22 : 0.22;

                final offsetAnimation = Tween<Offset>(
                  begin: Offset(
                    0,
                    isIncoming ? incomingYOffset : 0,
                  ),
                  end: Offset(
                    0,
                    isIncoming ? 0 : outgoingYOffset,
                  ),
                ).animate(animation);

                final scaleAnimation = Tween<double>(
                  begin: isIncoming ? 0.92 : 1,
                  end: isIncoming ? 1 : 0.92,
                ).animate(animation);

                final rotateAnimation = Tween<double>(
                  begin: isIncoming
                      ? (isGoingToGreeting ? -0.55 : 0.55)
                      : 0,
                  end: isIncoming
                      ? 0
                      : (isGoingToGreeting ? 0.42 : -0.42),
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: AnimatedBuilder(
                      animation: rotateAnimation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        child: child,
                      ),
                      builder: (context, animatedChild) {
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0016)
                            ..rotateX(rotateAnimation.value),
                          child: animatedChild,
                        );
                      },
                    ),
                  ),
                );
              },
              child: currentPage == 0
                  ? _ProfileWelcomeCard(
                      key: const ValueKey('page-0'),
                      displayName: displayName,
                      email: widget.email,
                      onTap: togglePage,
                    )
                  : _GreetingMessageCard(
                      key: const ValueKey('page-1'),
                      isLoading: isGreetingLoading,
                      message: greetingMessage,
                      messageAnimationKey: messageAnimationKey,
                      onCardTap: togglePage,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = currentPage == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF536B4E)
                    : const Color(0xFF536B4E).withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ProfileWelcomeCard extends StatelessWidget {
  final String displayName;
  final String email;
  final Future<void> Function() onTap;

  const _ProfileWelcomeCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassHeaderCard(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -28,
            child: _SoftCircle(
              size: 116,
              color: const Color(0xFFE5EDDE).withOpacity(0.9),
            ),
          ),
          Positioned(
            right: 38,
            bottom: -36,
            child: _SoftCircle(
              size: 94,
              color: const Color(0xFFD5E2CE).withOpacity(0.55),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -30,
            child: _SoftCircle(
              size: 82,
              color: const Color(0xFFF3EFE3).withOpacity(0.8),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3EA).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFD7E1D0),
                      ),
                    ),
                    child: const Icon(
                      Icons.self_improvement,
                      color: Color(0xFF536B4E),
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.60),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: Color(0xFF536B4E),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Dokun',
                          style: TextStyle(
                            color: Color(0xFF536B4E),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Hoş geldin,',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF667064),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F3A32),
                  letterSpacing: -0.2,
                ),
              ),
              if (email.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B736A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3EA).withOpacity(0.86),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFFD7E1D0),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF536B4E),
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Günlük yazını görmek için tıkla',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF536B4E),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreetingMessageCard extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final int messageAnimationKey;
  final Future<void> Function() onCardTap;

  const _GreetingMessageCard({
    super.key,
    required this.isLoading,
    required this.message,
    required this.messageAnimationKey,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMessage = message != null && message!.trim().isNotEmpty;
    final displayMessage = hasMessage
        ? message!
        : 'Bugün kendine nazik davranmayı seç.';

    return _GlassHeaderCard(
      onTap: onCardTap,
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -24,
            child: _SoftCircle(
              size: 120,
              color: const Color(0xFFEDE8F5).withOpacity(0.75),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -34,
            child: _SoftCircle(
              size: 94,
              color: const Color(0xFFEAF1E2).withOpacity(0.8),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF536B4E),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3EA).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFD7E1D0),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF536B4E),
                        size: 29,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.60),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF536B4E),
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Geri dön',
                            style: TextStyle(
                              color: Color(0xFF536B4E),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Bugünün yazısı',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF667064),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(
                      'message-$messageAnimationKey-$displayMessage',
                    ),
                    tween: Tween<double>(
                      begin: 0.05,
                      end: 1,
                    ),
                    duration: const Duration(seconds: 3),
                    curve: Curves.easeInOut,
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: child,
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 310,
                        ),
                        child: Text(
                          displayMessage,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2F3A32),
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tekrar dokunarak hoş geldin kartına dönebilirsin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B736A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GlassHeaderCard extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onTap;

  const _GlassHeaderCard({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.76),
            border: Border.all(
              color: Colors.white.withOpacity(0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.09),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 8,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}