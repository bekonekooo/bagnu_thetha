import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

class HomeMeditationSpotlightSection extends StatefulWidget {
  final VoidCallback onSeeAllTap;

  const HomeMeditationSpotlightSection({
    super.key,
    required this.onSeeAllTap,
  });

  @override
  State<HomeMeditationSpotlightSection> createState() =>
      _HomeMeditationSpotlightSectionState();
}

class _HomeMeditationSpotlightSectionState
    extends State<HomeMeditationSpotlightSection> {
  final MeditationService _meditationService = MeditationService();

  late Future<List<MeditationModel>> _futureMeditations;

  @override
  void initState() {
    super.initState();
    _futureMeditations = _meditationService.fetchActiveMeditations();
  }

  void openMeditationDetail(MeditationModel meditation) {
    context.push(
      '/meditation-detail',
      extra: meditation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MeditationModel>>(
      future: _futureMeditations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SpotlightLoadingCard();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final meditations = snapshot.data ?? [];

        if (meditations.isEmpty) {
          return const SizedBox.shrink();
        }

        final visibleMeditations = meditations.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Meditasyon Öne Çıkanlar',
              onSeeAllTap: widget.onSeeAllTap,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 292,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 4),
                itemCount: visibleMeditations.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 16);
                },
                itemBuilder: (context, index) {
                  final meditation = visibleMeditations[index];

                  return _SpotlightMeditationCard(
                    meditation: meditation,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAllTap;

  const _SectionHeader({
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
            padding: EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 6,
            ),
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

class _SpotlightMeditationCard extends StatelessWidget {
  final MeditationModel meditation;
  final VoidCallback onTap;

  const _SpotlightMeditationCard({
    required this.meditation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = meditation.thumbnailUrl.trim().isNotEmpty;

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
                    child: hasThumbnail
                        ? Image.network(
                            meditation.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const _EmptyThumbnail();
                            },
                          )
                        : const _EmptyThumbnail(),
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
                  if (meditation.isPlusOnly)
                    const Positioned(
                      top: 13,
                      right: 13,
                      child: _PlusBadge(),
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
                        imageUrl: meditation.teacherImageUrl,
                        fallbackIcon: _mediaIcon,
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
              meditation.title,
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
            GestureDetector(
              onTap: _categories.length > 2
                  ? () => _showAllCategories(context)
                  : null,
              child: Text(
                _categoryPreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF2F3A32).withOpacity(0.55),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _categories {
    return meditation.category
        .split(RegExp(r'[,•\n]'))
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toList();
  }

  String get _categoryPreview {
    if (_categories.isEmpty) {
      return 'Yeniden Kendine';
    }

    final visibleCategories = _categories.take(2).join(', ');

    return _categories.length > 2
        ? '$visibleCategories, ...'
        : visibleCategories;
  }

  Future<void> _showAllCategories(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5F0E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meditasyon Kategorileri',
                  style: TextStyle(
                    color: Color(0xFF2F3A32),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map((category) => _CategoryPill(text: category))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData get _mediaIcon {
    if (meditation.isVideo) {
      return Icons.videocam_rounded;
    }

    if (meditation.isLink) {
      return Icons.link_rounded;
    }

    return Icons.graphic_eq_rounded;
  }

  String get _metaText {
    final duration = meditation.durationText.trim();

    if (duration.isEmpty) {
      return 'Yeni • ${meditation.typeLabel}';
    }

    return 'Yeni • ${meditation.typeLabel} • $duration';
  }
}

class _EmptyThumbnail extends StatelessWidget {
  const _EmptyThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF3EA),
      child: const Center(
        child: Icon(
          Icons.self_improvement_rounded,
          color: Color(0xFF536B4E),
          size: 46,
        ),
      ),
    );
  }
}

class _PlusBadge extends StatelessWidget {
  const _PlusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1B8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5B84B),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
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

class _TeacherAvatar extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;

  const _TeacherAvatar({
    required this.imageUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cleanImageUrl = imageUrl.trim();

    if (cleanImageUrl.isEmpty) {
      return Icon(
        fallbackIcon,
        color: const Color(0xFF536B4E),
        size: 24,
      );
    }

    return ClipOval(
      child: Image.network(
        cleanImageUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            fallbackIcon,
            color: const Color(0xFF536B4E),
            size: 24,
          );
        },
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String text;

  const _CategoryPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF536B4E),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SpotlightLoadingCard extends StatelessWidget {
  const _SpotlightLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeaderPlaceholder(),
        const SizedBox(height: 14),
        SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (context, index) {
              return const SizedBox(width: 16);
            },
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderPlaceholder extends StatelessWidget {
  const _SectionHeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 210,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const Spacer(),
        Container(
          width: 72,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
