import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

class HomeRecentlyPlayedSection extends StatefulWidget {
  const HomeRecentlyPlayedSection({super.key});

  @override
  State<HomeRecentlyPlayedSection> createState() =>
      _HomeRecentlyPlayedSectionState();
}

class _HomeRecentlyPlayedSectionState extends State<HomeRecentlyPlayedSection> {
  final MeditationService meditationService = MeditationService();

  late Future<List<MeditationModel>> recentlyPlayedFuture;

  @override
  void initState() {
    super.initState();

    recentlyPlayedFuture = meditationService.fetchRecentlyPlayedMeditations();
  }

  Future<void> refreshRecentlyPlayed() async {
    setState(() {
      recentlyPlayedFuture = meditationService.fetchRecentlyPlayedMeditations();
    });
  }

  Future<void> openMeditationDetail(MeditationModel meditation) async {
    await context.push(
      '/meditation-detail',
      extra: meditation,
    );

    if (!mounted) return;

    await refreshRecentlyPlayed();
  }

  IconData iconForType(MeditationModel meditation) {
    if (meditation.isVideo) {
      return Icons.videocam_rounded;
    }

    if (meditation.isLink) {
      return Icons.link_rounded;
    }

    return Icons.graphic_eq_rounded;
  }

  String metaText(MeditationModel meditation) {
    final type = meditation.typeLabel;
    final duration = meditation.durationText.trim();

    if (duration.isEmpty) {
      return type;
    }

    return '$type · $duration';
  }

  Widget buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'En Son Oynatılanlar',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.05,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            context.go('/favorites');
          },
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 6,
            ),
            child: Text(
              'Tümünü Gör',
              style: TextStyle(
                color: Color(0xFF536B4E),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 134,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE8DDC9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF536B4E).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF536B4E),
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Henüz oynatılan meditasyon yok.',
                  style: TextStyle(
                    color: Color(0xFF2F3A32),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Bir meditasyonu açınca burada görünecek.',
                  style: TextStyle(
                    color: Color(0xFF6D766B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorState() {
    return Container(
      width: double.infinity,
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8DDC9),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC85C5C),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'En son oynatılanlar yüklenemedi.',
              style: TextStyle(
                color: Color(0xFF2F3A32),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MeditationModel>>(
      future: recentlyPlayedFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final visibleItems = items.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const _RecentlyPlayedLoading()
            else if (snapshot.hasError)
              buildErrorState()
            else if (visibleItems.isEmpty)
              buildEmptyState()
            else
              SizedBox(
                height: 238,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 4),
                  itemCount: visibleItems.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 14);
                  },
                  itemBuilder: (context, index) {
                    final meditation = visibleItems[index];

                    return _RecentlyPlayedCard(
                      meditation: meditation,
                      icon: iconForType(meditation),
                      metaText: metaText(meditation),
                      onTap: () {
                        openMeditationDetail(meditation);
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentlyPlayedCard extends StatelessWidget {
  final MeditationModel meditation;
  final IconData icon;
  final String metaText;
  final VoidCallback onTap;

  const _RecentlyPlayedCard({
    required this.meditation,
    required this.icon,
    required this.metaText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = meditation.thumbnailUrl.trim().isNotEmpty;

    return SizedBox(
      width: 190,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 122,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE8DDC9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF536B4E).withOpacity(0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 11),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasThumbnail
                        ? Image.network(
                            meditation.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const _EmptyRecentlyPlayedThumb();
                            },
                          )
                        : const _EmptyRecentlyPlayedThumb(),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.02),
                            Colors.black.withOpacity(0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF536B4E),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              meditation.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2F3A32),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.10,
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              metaText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6D766B),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              meditation.category.trim().isEmpty
                  ? 'BagnuTheta'
                  : meditation.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9A8B72),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecentlyPlayedThumb extends StatelessWidget {
  const _EmptyRecentlyPlayedThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF3EA),
      child: const Center(
        child: Icon(
          Icons.self_improvement_rounded,
          color: Color(0xFF536B4E),
          size: 42,
        ),
      ),
    );
  }
}

class _RecentlyPlayedLoading extends StatelessWidget {
  const _RecentlyPlayedLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 14);
        },
        itemBuilder: (context, index) {
          return Container(
            width: 190,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.44),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          );
        },
      ),
    );
  }
}