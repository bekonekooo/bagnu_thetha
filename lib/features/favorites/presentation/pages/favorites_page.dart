import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

enum FavoriteTab {
  recentlyPlayed,
  liked,
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final MeditationService meditationService = MeditationService();

  FavoriteTab selectedTab = FavoriteTab.recentlyPlayed;

  late Future<List<MeditationModel>> selectedMeditationsFuture;

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_1.jpg';

  @override
  void initState() {
    super.initState();

    selectedMeditationsFuture = loadSelectedMeditations();
  }

  Future<List<MeditationModel>> loadSelectedMeditations() {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      return meditationService.fetchRecentlyPlayedMeditations();
    }

    return meditationService.fetchMyFavoriteMeditations();
  }

  Future<void> refreshFavorites() async {
    setState(() {
      selectedMeditationsFuture = loadSelectedMeditations();
    });

    await selectedMeditationsFuture;
  }

  void changeTab(FavoriteTab tab) {
    if (selectedTab == tab) return;

    setState(() {
      selectedTab = tab;
      selectedMeditationsFuture = loadSelectedMeditations();
    });
  }

  Future<void> openMeditationDetail(MeditationModel meditation) async {
    await context.push(
      '/meditation-detail',
      extra: meditation,
    );

    if (!mounted) return;

    await refreshFavorites();
  }

  String get selectedTitle {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      return 'En Son Oynatılanlar';
    }

    return 'Beğenilenler';
  }

  String get emptyTitle {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      return 'Henüz oynatılan meditasyon yok.';
    }

    return 'Henüz beğenilen meditasyon yok.';
  }

  String get emptySubtitle {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      return 'Meditasyon detayında başlatınca burada görünecek.';
    }

    return 'Meditasyon detayında kalbe bastığında burada görünecek.';
  }

  List<String> categoriesForMeditation(MeditationModel meditation) {
    return meditation.category
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  IconData iconForType(String type) {
    switch (type) {
      case 'audio':
        return Icons.headphones_rounded;
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'link':
        return Icons.link_rounded;
      default:
        return Icons.spa_outlined;
    }
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
            color: Colors.white.withOpacity(0.18),
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
        child,
      ],
    );
  }

  Widget buildTopTitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 4, right: 4, bottom: 18),
      child: Text(
        'Favorilerim',
        style: TextStyle(
          color: Color(0xFF2F3A32),
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
          height: 1,
        ),
      ),
    );
  }

  Widget buildTabCards() {
    return Row(
      children: [
        Expanded(
          child: _FavoriteCollectionCard(
            title: 'En Son\nOynatılan',
            icon: Icons.history_rounded,
            isSelected: selectedTab == FavoriteTab.recentlyPlayed,
            onTap: () => changeTab(FavoriteTab.recentlyPlayed),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _FavoriteCollectionCard(
            title: 'Beğenilen',
            icon: Icons.favorite_rounded,
            isSelected: selectedTab == FavoriteTab.liked,
            onTap: () => changeTab(FavoriteTab.liked),
          ),
        ),
      ],
    );
  }

  Widget buildMeditationCard(MeditationModel meditation) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
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
                color: Colors.white.withOpacity(0.46),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.52),
                      Colors.white.withOpacity(0.35),
                      const Color(0xFF536B4E).withOpacity(0.11),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openMeditationDetail(meditation),
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
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _FavoriteIconBox(
                                icon: iconForType(meditation.type),
                              );
                            },
                          ),
                        )
                      else
                        _FavoriteIconBox(
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
                                _FavoriteTag(text: meditation.typeLabel),
                                ...categoriesForMeditation(meditation).map(
                                  (category) => _FavoriteTag(text: category),
                                ),
                                if (meditation.durationText.trim().isNotEmpty)
                                  _FavoriteTag(text: meditation.durationText),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              meditation.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF2F3A32),
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              ),
                            ),
                            if (meditation.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                meditation.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF3F4A40),
                                  fontSize: 12.8,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: Colors.white.withOpacity(0.84),
                        child: Icon(
                          selectedTab == FavoriteTab.recentlyPlayed
                              ? Icons.history_rounded
                              : Icons.favorite_rounded,
                          color: selectedTab == FavoriteTab.recentlyPlayed
                              ? const Color(0xFF536B4E)
                              : const Color(0xFFC85C5C),
                          size: 21,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.66),
        ),
      ),
      child: Column(
        children: [
          Icon(
            selectedTab == FavoriteTab.recentlyPlayed
                ? Icons.history_rounded
                : Icons.favorite_border_rounded,
            color: const Color(0xFF536B4E),
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF606A61),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorState(Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.66),
        ),
      ),
      child: Text(
        'İçerikler yüklenemedi: $error',
        style: const TextStyle(
          color: Color(0xFF2F3A32),
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      ),
    );
  }

  Widget buildContent() {
    return RefreshIndicator(
      onRefresh: refreshFavorites,
      child: FutureBuilder<List<MeditationModel>>(
        future: selectedMeditationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                buildTopTitle(),
                buildTabCards(),
                const SizedBox(height: 34),
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF536B4E),
                  ),
                ),
              ],
            );
          }

          final meditations = snapshot.data ?? [];

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              buildTopTitle(),
              buildTabCards(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  selectedTitle,
                  style: const TextStyle(
                    color: Color(0xFF2F3A32),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (snapshot.hasError)
                buildErrorState(snapshot.error!)
              else if (meditations.isEmpty)
                buildEmptyState()
              else
                ...meditations.map(buildMeditationCard),
            ],
          );
        },
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
          'Favorilerim',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.14),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
      ),
      body: buildBackground(
        child: SafeArea(
          child: buildContent(),
        ),
      ),
    );
  }
}

class _FavoriteCollectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FavoriteCollectionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 154,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF536B4E)
                : Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF536B4E)
                  : Colors.white.withOpacity(0.68),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.16 : 0.10),
                blurRadius: 22,
                offset: const Offset(0, 11),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -26,
                top: -30,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(
                      isSelected ? 0.10 : 0.42,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF536B4E),
                  size: 34,
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF2F3A32),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteIconBox extends StatelessWidget {
  final IconData icon;

  const _FavoriteIconBox({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.74),
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF536B4E),
        size: 31,
      ),
    );
  }
}

class _FavoriteTag extends StatelessWidget {
  final String text;

  const _FavoriteTag({
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