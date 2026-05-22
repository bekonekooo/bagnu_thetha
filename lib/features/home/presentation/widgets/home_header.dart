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

  // 2. karta her gelişte mesaj opacity animasyonunu yeniden başlatmak için
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
      // Yukarı kaydırınca günlük karta geç
      changePage(1);
    } else if (velocity > 250 && currentPage == 1) {
      // Aşağı kaydırınca hoş geldin kartına dön
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
            height: 250,
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
                    ? Colors.deepPurple
                    : Colors.deepPurple.withOpacity(0.25),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade400,
                Colors.deepPurple.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.self_improvement,
                color: Colors.white,
                size: 34,
              ),
              const Spacer(),
              Text(
                'Hoş geldin,',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (email.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.82),
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
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.24),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Günlük yazını görmek için tıkla',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onCardTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade300,
                Colors.indigo.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 34,
                    ),
                    const Spacer(),
                    Text(
                      'Bugünün yazısı',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.85),
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
        fontSize: 19,
        height: 1.18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tekrar dokunarak geri dönebilirsin.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}