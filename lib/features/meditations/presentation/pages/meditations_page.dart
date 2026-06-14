import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

class MeditationsPage extends StatefulWidget {
  const MeditationsPage({super.key});

  @override
  State<MeditationsPage> createState() => _MeditationsPageState();
}

class _MeditationsPageState extends State<MeditationsPage> {
  final MeditationService meditationService = MeditationService();
  final AudioPlayer audioPlayer = AudioPlayer();

  late Future<List<MeditationModel>> meditationsFuture;

  String selectedFilter = 'all';
  String? playingMeditationId;

  bool isAudioPaused = false;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  StreamSubscription<Duration>? durationSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<void>? completeSubscription;

  static const String meditationsBackground =
      'assets/images/backgrounds/home_bg_6.jpg';

  static const String meditationCardBackground =
      'assets/images/backgrounds/home_bg_6.jpg';

  @override
  void initState() {
    super.initState();

    meditationsFuture = meditationService.fetchActiveMeditations();

    durationSubscription = audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;

      setState(() {
        totalDuration = duration;
      });
    });

    positionSubscription = audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;

      setState(() {
        currentPosition = position;
      });
    });

    completeSubscription = audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;

      setState(() {
        playingMeditationId = null;
        isAudioPaused = false;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    durationSubscription?.cancel();
    positionSubscription?.cancel();
    completeSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> refreshMeditations() async {
    setState(() {
      meditationsFuture = meditationService.fetchActiveMeditations();
    });

    await meditationsFuture;
  }

  List<String> categoriesForMeditation(MeditationModel meditation) {
    return meditation.category
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<MeditationModel> filterMeditations(List<MeditationModel> items) {
    if (selectedFilter == 'all') return items;

    return items.where((item) {
      final categories = categoriesForMeditation(item);

      return categories.any(
        (category) => category.toLowerCase() == selectedFilter.toLowerCase(),
      );
    }).toList();
  }

  String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Duration? parseDurationText(String value) {
    final text = value.toLowerCase().trim();

    if (text.isEmpty) return null;

    final minuteMatch =
        RegExp(r'(\d+)\s*(dk|dakika|min|minute)').firstMatch(text);

    if (minuteMatch != null) {
      final minutes = int.tryParse(minuteMatch.group(1) ?? '');

      if (minutes != null && minutes > 0) {
        return Duration(minutes: minutes);
      }
    }

    final secondMatch =
        RegExp(r'(\d+)\s*(sn|saniye|sec|second)').firstMatch(text);

    if (secondMatch != null) {
      final seconds = int.tryParse(secondMatch.group(1) ?? '');

      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds);
      }
    }

    final plainNumber = int.tryParse(text);

    if (plainNumber != null && plainNumber > 0) {
      return Duration(minutes: plainNumber);
    }

    return null;
  }

  Duration visibleTotalDuration(MeditationModel meditation) {
    if (totalDuration > Duration.zero) {
      return totalDuration;
    }

    return parseDurationText(meditation.durationText) ?? Duration.zero;
  }

  Duration visibleRemainingDuration(MeditationModel meditation) {
    final visibleTotal = visibleTotalDuration(meditation);

    if (visibleTotal == Duration.zero) {
      return Duration.zero;
    }

    final remaining = visibleTotal - currentPosition;

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  double progressValueForMeditation(MeditationModel meditation) {
    final visibleTotal = visibleTotalDuration(meditation);

    if (visibleTotal.inMilliseconds <= 0) return 0;

    final progress =
        currentPosition.inMilliseconds / visibleTotal.inMilliseconds;

    if (progress.isNaN || progress.isInfinite) return 0;

    return progress.clamp(0, 1);
  }

  Future<void> loadAudioDurationManually() async {
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      final duration = await audioPlayer.getDuration();

      if (duration != null && duration > Duration.zero) {
        setState(() {
          totalDuration = duration;
        });

        return;
      }
    }
  }

  Future<void> playOrPauseAudio(MeditationModel meditation) async {
    try {
      final isCurrentAudio = playingMeditationId == meditation.id;

      if (isCurrentAudio && !isAudioPaused) {
        await audioPlayer.pause();

        if (!mounted) return;

        setState(() {
          isAudioPaused = true;
        });

        return;
      }

      if (isCurrentAudio && isAudioPaused) {
        await audioPlayer.resume();

        if (!mounted) return;

        setState(() {
          isAudioPaused = false;
        });

        return;
      }

      await audioPlayer.stop();

      if (!mounted) return;

      setState(() {
        playingMeditationId = meditation.id;
        isAudioPaused = false;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      });

      await audioPlayer.play(UrlSource(meditation.mediaUrl));
      await loadAudioDurationManually();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ses oynatılamadı: $e'),
        ),
      );
    }
  }

  Future<void> stopAudioIfPlaying() async {
    await audioPlayer.stop();

    if (!mounted) return;

    setState(() {
      playingMeditationId = null;
      isAudioPaused = false;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });
  }

  Future<void> openVideoInApp(MeditationModel meditation) async {
    if (meditation.mediaUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video bağlantısı bulunamadı.'),
        ),
      );
      return;
    }

    await stopAudioIfPlaying();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return MeditationVideoPlayerPage(
            meditation: meditation,
          );
        },
      ),
    );
  }

  Future<void> openMediaUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçersiz bağlantı.'),
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı açılamadı.'),
        ),
      );
    }
  }

  Future<void> handleMeditationTap(MeditationModel meditation) async {
    if (meditation.isAudio) {
      await playOrPauseAudio(meditation);
      return;
    }

    if (meditation.isVideo) {
      await openVideoInApp(meditation);
      return;
    }

    if (meditation.isLink) {
      await openMediaUrl(meditation.mediaUrl);
      return;
    }
  }

  IconData iconForType(String type) {
    switch (type) {
      case 'audio':
        return Icons.headphones;
      case 'video':
        return Icons.play_circle_outline;
      case 'link':
        return Icons.link;
      default:
        return Icons.spa_outlined;
    }
  }

  String labelForFilter(String filter) {
    switch (filter) {
      case 'all':
        return 'Tümü';
      case 'Sabah':
        return 'Sabah';
      case 'Akşam':
        return 'Akşam';
      case 'Şükür':
        return 'Şükür';
      case 'Aşk':
        return 'Aşk';
      case 'Bereket':
        return 'Bereket';
      case 'Sağlık':
        return 'Sağlık';
      default:
        return filter;
    }
  }

  Widget buildBackgroundBody({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            meditationsBackground,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFEEF3EA),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.16),
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
                  Colors.white.withOpacity(0.04),
                  Colors.black.withOpacity(0.22),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildFilterChip(String filter) {
    final isSelected = selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(
          labelForFilter(filter),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2F3A32),
            fontWeight: FontWeight.w800,
          ),
        ),
        selectedColor: const Color(0xFF536B4E),
        backgroundColor: Colors.white.withOpacity(0.72),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF536B4E)
              : Colors.white.withOpacity(0.70),
        ),
        onSelected: (_) {
          setState(() {
            selectedFilter = filter;
          });
        },
      ),
    );
  }

  Widget buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Color(0xFFEEF3EA),
            child: Icon(
              Icons.self_improvement,
              color: Color(0xFF536B4E),
              size: 32,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meditasyonlar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ses kayıtları, video çalışmaları ve özel bağlantılarla içsel alanına dön.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Color(0xFF606A61),
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

  Widget buildAudioProgress(MeditationModel meditation) {
    final isCurrentAudio = playingMeditationId == meditation.id;

    if (!meditation.isAudio || !isCurrentAudio) {
      return const SizedBox.shrink();
    }

    final visibleTotal = visibleTotalDuration(meditation);
    final remaining = visibleRemainingDuration(meditation);
    final hasDuration = visibleTotal > Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.70),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progressValueForMeditation(meditation),
                minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF536B4E),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(
                  isAudioPaused
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 16,
                  color: const Color(0xFF536B4E),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    isAudioPaused ? 'Duraklatıldı' : 'Çalıyor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF536B4E),
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              hasDuration
                  ? 'Kalan süre: ${formatDuration(remaining)}'
                  : 'Kalan süre hesaplanamadı',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2F3A32),
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMeditationCard(MeditationModel meditation) {
    final isPlaying = playingMeditationId == meditation.id;
    final isPaused = isPlaying && isAudioPaused;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                meditationCardBackground,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFEEF3EA),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.50),
                      Colors.white.withOpacity(0.34),
                      const Color(0xFF536B4E).withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => handleMeditationTap(meditation),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meditation.thumbnailUrl.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            meditation.thumbnailUrl,
                            width: 66,
                            height: 66,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _MeditationIconBox(
                                icon: iconForType(meditation.type),
                              );
                            },
                          ),
                        )
                      else
                        _MeditationIconBox(
                          icon: iconForType(meditation.type),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _MiniTag(text: meditation.typeLabel),
                                ...categoriesForMeditation(meditation).map(
                                  (category) => _MiniTag(text: category),
                                ),
                                if (meditation.durationText.trim().isNotEmpty)
                                  _MiniTag(text: meditation.durationText),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              meditation.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2F3A32),
                              ),
                            ),
                            if (meditation.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                meditation.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.8,
                                  height: 1.35,
                                  color: Color(0xFF3F4A40),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            buildAudioProgress(meditation),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: Colors.white.withOpacity(0.82),
                        child: Icon(
                          meditation.isAudio
                              ? isPlaying
                                  ? isPaused
                                      ? Icons.play_arrow
                                      : Icons.pause
                                  : Icons.play_arrow
                              : meditation.isVideo
                                  ? Icons.play_circle_outline
                                  : Icons.open_in_new,
                          color: const Color(0xFF536B4E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.spa_outlined,
            color: Color(0xFF536B4E),
            size: 44,
          ),
          SizedBox(height: 12),
          Text(
            'Henüz meditasyon içeriği yok.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2F3A32),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Öğretmenler içerik eklediğinde burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF606A61),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Meditasyonlar',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.18),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
      ),
      body: buildBackgroundBody(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: refreshMeditations,
            child: FutureBuilder<List<MeditationModel>>(
              future: meditationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF536B4E),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      buildHeroCard(),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.80),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Meditasyonlar yüklenemedi: ${snapshot.error}',
                          style: const TextStyle(
                            color: Color(0xFF2F3A32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final allMeditations = snapshot.data ?? [];
                final visibleMeditations = filterMeditations(allMeditations);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    buildHeroCard(),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildFilterChip('all'),
                          buildFilterChip('Sabah'),
                          buildFilterChip('Akşam'),
                          buildFilterChip('Şükür'),
                          buildFilterChip('Aşk'),
                          buildFilterChip('Bereket'),
                          buildFilterChip('Sağlık'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (visibleMeditations.isEmpty)
                      buildEmptyState()
                    else
                      ...visibleMeditations.map(buildMeditationCard),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MeditationVideoPlayerPage extends StatefulWidget {
  final MeditationModel meditation;

  const MeditationVideoPlayerPage({
    super.key,
    required this.meditation,
  });

  @override
  State<MeditationVideoPlayerPage> createState() =>
      _MeditationVideoPlayerPageState();
}

class _MeditationVideoPlayerPageState extends State<MeditationVideoPlayerPage> {
  VideoPlayerController? controller;

  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> initializeVideo() async {
    try {
      final uri = Uri.parse(widget.meditation.mediaUrl);

      final videoController = VideoPlayerController.networkUrl(uri);

      await videoController.initialize();
      await videoController.setLooping(false);
      await videoController.play();

      if (!mounted) return;

      setState(() {
        controller = videoController;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  String formatVideoDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> togglePlayPause() async {
    final videoController = controller;

    if (videoController == null) return;

    if (videoController.value.isPlaying) {
      await videoController.pause();
    } else {
      await videoController.play();
    }

    if (!mounted) return;

    setState(() {});
  }

  Future<void> seekRelative(Duration offset) async {
    final videoController = controller;

    if (videoController == null) return;

    final currentPosition = videoController.value.position;
    final duration = videoController.value.duration;

    var newPosition = currentPosition + offset;

    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }

    if (newPosition > duration) {
      newPosition = duration;
    }

    await videoController.seekTo(newPosition);

    if (!mounted) return;

    setState(() {});
  }

  Widget buildVideoBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF536B4E),
        ),
      );
    }

    if (hasError || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.86),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFC85C5C),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Video oynatılamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2F3A32),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF606A61),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final videoController = controller!;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                videoController,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF536B4E),
                  bufferedColor: Color(0xFFD7E1D0),
                  backgroundColor: Color(0xFFE7E7E7),
                ),
              ),
              Row(
                children: [
                  Text(
                    formatVideoDuration(videoController.value.position),
                    style: const TextStyle(
                      color: Color(0xFF2F3A32),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatVideoDuration(videoController.value.duration),
                    style: const TextStyle(
                      color: Color(0xFF606A61),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => seekRelative(
                      const Duration(seconds: -10),
                    ),
                    icon: const Icon(Icons.replay_10),
                    color: const Color(0xFF536B4E),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF536B4E),
                    child: IconButton(
                      onPressed: togglePlayPause,
                      icon: Icon(
                        videoController.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      color: Colors.white,
                      iconSize: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => seekRelative(
                      const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.forward_10),
                    color: const Color(0xFF536B4E),
                    iconSize: 32,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: const Color(0xFF101510),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101510),
      appBar: AppBar(
        title: Text(
          widget.meditation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF101510),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: buildBackground(
        child: buildVideoBody(),
      ),
    );
  }
}

class _MeditationIconBox extends StatelessWidget {
  final IconData icon;

  const _MeditationIconBox({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.75),
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF536B4E),
        size: 30,
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;

  const _MiniTag({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF536B4E),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}