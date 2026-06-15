import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';

class MeditationDetailPage extends StatefulWidget {
  final MeditationModel meditation;

  const MeditationDetailPage({
    super.key,
    required this.meditation,
  });

  @override
  State<MeditationDetailPage> createState() => _MeditationDetailPageState();
}

class _MeditationDetailPageState extends State<MeditationDetailPage> {
  final AudioPlayer audioPlayer = AudioPlayer();

  bool isPlaying = false;
  bool isPaused = false;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_6.jpg';

  @override
  void initState() {
    super.initState();

    audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;

      setState(() {
        totalDuration = duration;
      });
    });

    audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;

      setState(() {
        currentPosition = position;
      });
    });

    audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;

      setState(() {
        isPlaying = false;
        isPaused = false;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progressValue {
    if (totalDuration.inMilliseconds <= 0) return 0;

    final value =
        currentPosition.inMilliseconds / totalDuration.inMilliseconds;

    if (value.isNaN || value.isInfinite) return 0;

    return value.clamp(0, 1);
  }

  Future<void> playOrPauseAudio() async {
    try {
      if (widget.meditation.mediaUrl.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses bağlantısı bulunamadı.'),
          ),
        );
        return;
      }

      if (isPlaying && !isPaused) {
        await audioPlayer.pause();

        if (!mounted) return;

        setState(() {
          isPaused = true;
        });

        return;
      }

      if (isPlaying && isPaused) {
        await audioPlayer.resume();

        if (!mounted) return;

        setState(() {
          isPaused = false;
        });

        return;
      }

      await audioPlayer.stop();

      if (!mounted) return;

      setState(() {
        isPlaying = true;
        isPaused = false;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      });

      await audioPlayer.play(UrlSource(widget.meditation.mediaUrl));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ses oynatılamadı: $e'),
        ),
      );
    }
  }

  Future<void> openLink() async {
    final uri = Uri.tryParse(widget.meditation.mediaUrl);

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

  Future<void> openVideo() async {
    if (widget.meditation.mediaUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video bağlantısı bulunamadı.'),
        ),
      );
      return;
    }

    await audioPlayer.stop();

    if (!mounted) return;

    setState(() {
      isPlaying = false;
      isPaused = false;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return MeditationDetailVideoPlayerPage(
            meditation: widget.meditation,
          );
        },
      ),
    );
  }

  Future<void> handleMainAction() async {
    if (widget.meditation.isAudio) {
      await playOrPauseAudio();
      return;
    }

    if (widget.meditation.isVideo) {
      await openVideo();
      return;
    }

    if (widget.meditation.isLink) {
      await openLink();
      return;
    }
  }

  IconData get mediaIcon {
    if (widget.meditation.isVideo) {
      return Icons.play_circle_outline_rounded;
    }

    if (widget.meditation.isLink) {
      return Icons.open_in_new_rounded;
    }

    if (isPlaying && !isPaused) {
      return Icons.pause_rounded;
    }

    return Icons.play_arrow_rounded;
  }

  String get actionText {
    if (widget.meditation.isVideo) {
      return 'Videoyu Aç';
    }

    if (widget.meditation.isLink) {
      return 'Bağlantıyı Aç';
    }

    if (isPlaying && !isPaused) {
      return 'Duraklat';
    }

    if (isPlaying && isPaused) {
      return 'Devam Et';
    }

    return 'Meditasyonu Başlat';
  }

  List<String> get categories {
    return widget.meditation.category
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Widget buildBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundImage,
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
            color: Colors.white.withOpacity(0.14),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.20),
                  Colors.white.withOpacity(0.04),
                  Colors.black.withOpacity(0.28),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildCoverImage() {
    final hasThumbnail = widget.meditation.thumbnailUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: hasThumbnail
                ? Image.network(
                    widget.meditation.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _DetailEmptyCover();
                    },
                  )
                : const _DetailEmptyCover(),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.04),
                    Colors.black.withOpacity(0.34),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.meditation.isVideo
                        ? Icons.videocam_rounded
                        : widget.meditation.isLink
                            ? Icons.link_rounded
                            : Icons.graphic_eq_rounded,
                    color: const Color(0xFF536B4E),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.meditation.typeLabel,
                    style: const TextStyle(
                      color: Color(0xFF536B4E),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailTag(text: widget.meditation.typeLabel),
              if (widget.meditation.durationText.trim().isNotEmpty)
                _DetailTag(text: widget.meditation.durationText),
              ...categories.map((category) {
                return _DetailTag(text: category);
              }),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.meditation.title,
            style: const TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: -0.8,
            ),
          ),
          if (widget.meditation.description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              widget.meditation.description,
              style: const TextStyle(
                color: Color(0xFF4F5A51),
                fontSize: 15.5,
                height: 1.48,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildAudioProgressCard() {
    if (!widget.meditation.isAudio || !isPlaying) {
      return const SizedBox.shrink();
    }

    final remaining = totalDuration > Duration.zero
        ? totalDuration - currentPosition
        : Duration.zero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.86),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF536B4E),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                formatDuration(currentPosition),
                style: const TextStyle(
                  color: Color(0xFF2F3A32),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                totalDuration > Duration.zero
                    ? 'Kalan: ${formatDuration(remaining.isNegative ? Duration.zero : remaining)}'
                    : 'Süre hazırlanıyor',
                style: const TextStyle(
                  color: Color(0xFF536B4E),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: handleMainAction,
        icon: Icon(
          mediaIcon,
          size: 28,
        ),
        label: Text(
          actionText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF536B4E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
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
          'Meditasyon Detayı',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.16),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
      ),
      body: buildBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              children: [
                buildCoverImage(),
                const SizedBox(height: 18),
                buildInfoCard(),
                const SizedBox(height: 16),
                buildAudioProgressCard(),
                if (widget.meditation.isAudio && isPlaying)
                  const SizedBox(height: 16),
                buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MeditationDetailVideoPlayerPage extends StatefulWidget {
  final MeditationModel meditation;

  const MeditationDetailVideoPlayerPage({
    super.key,
    required this.meditation,
  });

  @override
  State<MeditationDetailVideoPlayerPage> createState() =>
      _MeditationDetailVideoPlayerPageState();
}

class _MeditationDetailVideoPlayerPageState
    extends State<MeditationDetailVideoPlayerPage> {
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

    final current = videoController.value.position;
    final duration = videoController.value.duration;

    var next = current + offset;

    if (next < Duration.zero) {
      next = Duration.zero;
    }

    if (next > duration) {
      next = duration;
    }

    await videoController.seekTo(next);

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
                    onPressed: () {
                      seekRelative(const Duration(seconds: -10));
                    },
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
                    onPressed: () {
                      seekRelative(const Duration(seconds: 10));
                    },
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
      body: buildVideoBody(),
    );
  }
}

class _DetailEmptyCover extends StatelessWidget {
  const _DetailEmptyCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF3EA),
      child: const Center(
        child: Icon(
          Icons.self_improvement_rounded,
          color: Color(0xFF536B4E),
          size: 58,
        ),
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  final String text;

  const _DetailTag({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF536B4E),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}