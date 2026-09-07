import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/workshops/data/models/workshop_model.dart';
import 'package:flutter_application_1/features/workshops/data/services/workshop_service.dart';

class HomeWorkshopSpotlightSection extends StatefulWidget {
  final VoidCallback onSeeAllTap;

  const HomeWorkshopSpotlightSection({
    super.key,
    required this.onSeeAllTap,
  });

  @override
  State<HomeWorkshopSpotlightSection> createState() =>
      _HomeWorkshopSpotlightSectionState();
}

class _HomeWorkshopSpotlightSectionState
    extends State<HomeWorkshopSpotlightSection> {
  final WorkshopService _workshopService = WorkshopService();

  late Future<List<WorkshopModel>> _futureWorkshops;

  @override
  void initState() {
    super.initState();
    _futureWorkshops = _workshopService.fetchActiveWorkshops();
  }

  Future<void> openWorkshopDetail(WorkshopModel workshop) async {
    final isJoined = await _workshopService.hasJoinedWorkshop(workshop.id);

    if (!mounted) return;

    await context.push(
      '/workshop-detail',
      extra: {
        'workshop': workshop,
        'isJoined': isJoined,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkshopModel>>(
      future: _futureWorkshops,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WorkshopSpotlightLoadingCard();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final workshops = snapshot.data ?? [];

        if (workshops.isEmpty) {
          return const SizedBox.shrink();
        }

        final visibleWorkshops = workshops.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkshopSectionHeader(
              title: 'Önerilen Atölyeler',
              onSeeAllTap: widget.onSeeAllTap,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 292,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 4),
                itemCount: visibleWorkshops.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 16);
                },
                itemBuilder: (context, index) {
                  final workshop = visibleWorkshops[index];

                  return _SpotlightWorkshopCard(
                    workshop: workshop,
                    onTap: () => openWorkshopDetail(workshop),
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

class _WorkshopSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAllTap;

  const _WorkshopSectionHeader({
    required this.title,
    required this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onSeeAllTap,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Text(
              'Tümünü Gör',
              style: TextStyle(
                color: Color(0xFF536B4E),
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightWorkshopCard extends StatelessWidget {
  final WorkshopModel workshop;
  final VoidCallback onTap;

  const _SpotlightWorkshopCard({
    required this.workshop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = workshop.imageUrl.trim().isNotEmpty;

    return SizedBox(
      width: 280,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 158,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.74),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasCover
                        ? Image.network(
                            workshop.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const _WorkshopCoverPlaceholder();
                            },
                          )
                        : const _WorkshopCoverPlaceholder(),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.03),
                            Colors.black.withOpacity(0.24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (workshop.isPlusOnly)
                    const Positioned(
                      top: 13,
                      right: 13,
                      child: _WorkshopPlusBadge(),
                    ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                      ),
                      child: _TeacherAvatar(
                        imageUrl: workshop.teacherImageUrl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Text(
              _metaText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF2F3A32).withOpacity(0.68),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              workshop.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2F3A32),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.12,
                letterSpacing: -0.55,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              workshop.category.trim().isEmpty
                  ? workshop.teacherName
                  : workshop.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF2F3A32).withOpacity(0.55),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _metaText {
    final price = workshop.formattedPrice;
    return 'Yeni • ${workshop.durationLabel} • $price';
  }
}

class _TeacherAvatar extends StatelessWidget {
  final String imageUrl;

  const _TeacherAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final cleanImageUrl = imageUrl.trim();

    if (cleanImageUrl.isEmpty) {
      return const Icon(
        Icons.auto_awesome_mosaic_rounded,
        color: Color(0xFF536B4E),
        size: 23,
      );
    }

    return ClipOval(
      child: Image.network(
        cleanImageUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.auto_awesome_mosaic_rounded,
            color: Color(0xFF536B4E),
            size: 23,
          );
        },
      ),
    );
  }
}

class _WorkshopCoverPlaceholder extends StatelessWidget {
  const _WorkshopCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE6ECE3),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_mosaic_rounded,
          color: Color(0xFF536B4E),
          size: 46,
        ),
      ),
    );
  }
}

class _WorkshopPlusBadge extends StatelessWidget {
  const _WorkshopPlusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1B8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5B84B),
          width: 1.2,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 15,
            color: Color(0xFF8A6200),
          ),
          SizedBox(width: 4),
          Text(
            'PLUS',
            style: TextStyle(
              color: Color(0xFF8A6200),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopSpotlightLoadingCard extends StatelessWidget {
  const _WorkshopSpotlightLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 292,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.34),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF536B4E),
        ),
      ),
    );
  }
}
