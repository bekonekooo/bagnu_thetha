import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/meditation_model.dart';
import '../../data/services/meditation_service.dart';

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

  static const String meditationsBackground =
      'assets/images/backgrounds/home_bg_7.jpg';

  @override
  void initState() {
    super.initState();
    meditationsFuture = meditationService.fetchActiveMeditations();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> refreshMeditations() async {
    setState(() {
      meditationsFuture = meditationService.fetchActiveMeditations();
    });

    await meditationsFuture;
  }

  List<MeditationModel> filterMeditations(List<MeditationModel> items) {
    if (selectedFilter == 'all') return items;

    return items.where((item) => item.type == selectedFilter).toList();
  }

  Future<void> playOrStopAudio(MeditationModel meditation) async {
    try {
      if (playingMeditationId == meditation.id) {
        await audioPlayer.stop();

        if (!mounted) return;

        setState(() {
          playingMeditationId = null;
        });

        return;
      }

      await audioPlayer.stop();
      await audioPlayer.play(UrlSource(meditation.mediaUrl));

      if (!mounted) return;

      setState(() {
        playingMeditationId = meditation.id;
      });

      audioPlayer.onPlayerComplete.listen((event) {
        if (!mounted) return;

        setState(() {
          playingMeditationId = null;
        });
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ses oynatılamadı: $e'),
        ),
      );
    }
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
      case 'audio':
        return 'Sesler';
      case 'video':
        return 'Videolar';
      case 'link':
        return 'Linkler';
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

  Widget buildMeditationCard(MeditationModel meditation) {
    final isPlaying = playingMeditationId == meditation.id;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          if (meditation.isAudio) {
            playOrStopAudio(meditation);
          } else {
            openMediaUrl(meditation.mediaUrl);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                        if (meditation.category.trim().isNotEmpty)
                          _MiniTag(text: meditation.category),
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
                          color: Color(0xFF606A61),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFEEF3EA),
                child: Icon(
                  meditation.isAudio
                      ? isPlaying
                          ? Icons.stop
                          : Icons.play_arrow
                      : Icons.open_in_new,
                  color: const Color(0xFF536B4E),
                ),
              ),
            ],
          ),
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
                          buildFilterChip('audio'),
                          buildFilterChip('video'),
                          buildFilterChip('link'),
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
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD7E1D0),
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
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(999),
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