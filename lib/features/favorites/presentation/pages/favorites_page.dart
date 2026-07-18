import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/favorites/data/models/recent_content_model.dart';
import 'package:flutter_application_1/features/favorites/data/services/content_history_service.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

import 'package:flutter_application_1/features/workshops/data/models/workshop_model.dart';
import 'package:flutter_application_1/features/workshops/data/services/workshop_service.dart';

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
  final ContentHistoryService contentHistoryService =
      ContentHistoryService();

  final MeditationService meditationService =
      MeditationService();

  final WorkshopService workshopService =
      WorkshopService();

  FavoriteTab selectedTab = FavoriteTab.recentlyPlayed;

  late Future<List<_FavoriteEntry>> entriesFuture;

  static const Color primaryColor = Color(0xFF536B4E);
  static const Color textColor = Color(0xFF2F3A32);
  static const Color secondaryTextColor = Color(0xFF606A61);
  static const Color softGreen = Color(0xFFEEF3EA);
  static const Color dangerColor = Color(0xFFC85C5C);

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_1.jpg';

  @override
  void initState() {
    super.initState();
    entriesFuture = loadEntries();
  }

  Future<List<_FavoriteEntry>> loadEntries() async {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      final recentContents =
          await contentHistoryService.fetchRecentContents(
        limit: 10,
      );

      return recentContents
          .map(
            (content) => _FavoriteEntry.recent(content),
          )
          .toList();
    }

    final results = await Future.wait<dynamic>([
      meditationService.fetchMyFavoriteMeditations(),
      workshopService.fetchMyFavoriteWorkshops(),
    ]);

    final meditations =
        results[0] as List<MeditationModel>;

    final workshops =
        results[1] as List<WorkshopModel>;

    return [
      ...meditations.map(
        (meditation) =>
            _FavoriteEntry.meditation(meditation),
      ),
      ...workshops.map(
        (workshop) =>
            _FavoriteEntry.workshop(workshop),
      ),
    ];
  }

  Future<void> refreshFavorites() async {
    final newFuture = loadEntries();

    setState(() {
      entriesFuture = newFuture;
    });

    await newFuture;
  }

  void changeTab(FavoriteTab tab) {
    if (selectedTab == tab) {
      return;
    }

    setState(() {
      selectedTab = tab;
      entriesFuture = loadEntries();
    });
  }

  Future<void> openEntry(
    _FavoriteEntry entry,
  ) async {
    final recentContent = entry.recentContent;

    if (recentContent != null) {
      if (recentContent.isMeditation &&
          recentContent.meditation != null) {
        await context.push(
          '/meditation-detail',
          extra: recentContent.meditation!,
        );
      } else if (recentContent.isWorkshopDay &&
          recentContent.workshop != null) {
        final joined =
            await workshopService.hasJoinedWorkshop(
          recentContent.workshop!.id,
        );

        if (!mounted) return;

        await context.push(
          '/workshop-detail',
          extra: {
            'workshop': recentContent.workshop!,
            'isJoined': joined,
          },
        );
      }

      if (!mounted) return;

      await refreshFavorites();
      return;
    }

    if (entry.meditation != null) {
      await context.push(
        '/meditation-detail',
        extra: entry.meditation!,
      );

      if (!mounted) return;

      await refreshFavorites();
      return;
    }

    if (entry.workshop != null) {
      final joined =
          await workshopService.hasJoinedWorkshop(
        entry.workshop!.id,
      );

      if (!mounted) return;

      await context.push(
        '/workshop-detail',
        extra: {
          'workshop': entry.workshop!,
          'isJoined': joined,
        },
      );

      if (!mounted) return;

      await refreshFavorites();
    }
  }

  Future<void> clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Geçmişi temizle',
          ),
          content: const Text(
            'Son oynatılan içeriklerin tamamı silinecek. Devam etmek istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Vazgeç',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Temizle',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await contentHistoryService.clearMyHistory();

      if (!mounted) return;

      await refreshFavorites();

      showMessage(
        'Son oynatılanlar temizlendi.',
      );
    } catch (error) {
      showMessage(
        'Geçmiş temizlenemedi: $error',
      );
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String get sectionTitle {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      return 'En Son Oynatılan 10 İçerik';
    }

    return 'Beğenilenler';
  }

  String get emptyTitle {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      return 'Henüz oynatılan içerik yok';
    }

    return 'Henüz beğenilen içerik yok';
  }

  String get emptySubtitle {
    if (selectedTab == FavoriteTab.recentlyPlayed) {
      return 'Meditasyon veya atölye içeriği oynattığında burada görünecek.';
    }

    return 'Beğendiğin meditasyonlar ve atölyeler burada görünecek.';
  }

  Widget buildBackground({
    required Widget child,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                color: softGreen,
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

  Widget buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Favorilerim',
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        if (selectedTab ==
            FavoriteTab.recentlyPlayed)
          IconButton(
            onPressed: clearHistory,
            tooltip: 'Geçmişi Temizle',
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.white.withOpacity(0.76),
              foregroundColor: dangerColor,
            ),
            icon: const Icon(
              Icons.delete_sweep_outlined,
            ),
          ),
      ],
    );
  }

  Widget buildTabSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withOpacity(0.68),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: buildTabButton(
              tab: FavoriteTab.recentlyPlayed,
              icon: Icons.history_rounded,
              title: 'Son Oynatılan',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: buildTabButton(
              tab: FavoriteTab.liked,
              icon: Icons.favorite_rounded,
              title: 'Beğenilenler',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabButton({
    required FavoriteTab tab,
    required IconData icon,
    required String title,
  }) {
    final selected = selectedTab == tab;

    return InkWell(
      onTap: () {
        changeTab(tab);
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        height: 78,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? Colors.white
                  : primaryColor,
              size: 23,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : textColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEntryCard(
    _FavoriteEntry entry,
  ) {
    final imageUrl = entry.imageUrl.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            openEntry(entry);
          },
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(18),
                  child: SizedBox(
                    width: 82,
                    height: 82,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return buildPlaceholder(
                                entry.icon,
                              );
                            },
                          )
                        : buildPlaceholder(
                            entry.icon,
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          buildTag(
                            entry.contentKindLabel,
                          ),
                          buildTag(
                            entry.typeLabel,
                          ),
                          if (entry.durationText
                              .trim()
                              .isNotEmpty)
                            buildTag(
                              entry.durationText,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      if (entry.subtitle
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          entry.subtitle,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                                secondaryTextColor,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: softGreen,
                  child: Icon(
                    selectedTab ==
                            FavoriteTab.recentlyPlayed
                        ? Icons.history_rounded
                        : Icons.favorite_rounded,
                    color: selectedTab ==
                            FavoriteTab.recentlyPlayed
                        ? primaryColor
                        : dangerColor,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlaceholder(
    IconData icon,
  ) {
    return Container(
      color: softGreen,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: primaryColor,
        size: 34,
      ),
    );
  }

  Widget buildTag(String text) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
      ),
      child: Column(
        children: [
          Icon(
            selectedTab ==
                    FavoriteTab.recentlyPlayed
                ? Icons.history_rounded
                : Icons.favorite_border_rounded,
            color: primaryColor,
            size: 48,
          ),
          const SizedBox(height: 13),
          Text(
            emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              height: 1.4,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: dangerColor,
            size: 42,
          ),
          const SizedBox(height: 11),
          const Text(
            'İçerikler yüklenemedi',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: refreshFavorites,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Tekrar Dene',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    return RefreshIndicator(
      onRefresh: refreshFavorites,
      color: primaryColor,
      child: FutureBuilder<List<_FavoriteEntry>>(
        future: entriesFuture,
        builder: (
          context,
          snapshot,
        ) {
          final entries =
              snapshot.data ??
                  <_FavoriteEntry>[];

          return ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              30,
            ),
            children: [
              buildHeader(),
              const SizedBox(height: 18),
              buildTabSelector(),
              const SizedBox(height: 24),
              Text(
                sectionTitle,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 13),
              if (snapshot.connectionState ==
                  ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                )
              else if (snapshot.hasError)
                buildErrorState(
                  snapshot.error!,
                )
              else if (entries.isEmpty)
                buildEmptyState()
              else
                ...entries.map(
                  buildEntryCard,
                ),
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
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor:
            Colors.white.withOpacity(0.14),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      body: buildBackground(
        child: SafeArea(
          child: buildContent(),
        ),
      ),
    );
  }
}

class _FavoriteEntry {
  final RecentContentModel? recentContent;
  final MeditationModel? meditation;
  final WorkshopModel? workshop;

  const _FavoriteEntry._({
    required this.recentContent,
    required this.meditation,
    required this.workshop,
  });

  factory _FavoriteEntry.recent(
    RecentContentModel content,
  ) {
    return _FavoriteEntry._(
      recentContent: content,
      meditation: null,
      workshop: null,
    );
  }

  factory _FavoriteEntry.meditation(
    MeditationModel meditation,
  ) {
    return _FavoriteEntry._(
      recentContent: null,
      meditation: meditation,
      workshop: null,
    );
  }

  factory _FavoriteEntry.workshop(
    WorkshopModel workshop,
  ) {
    return _FavoriteEntry._(
      recentContent: null,
      meditation: null,
      workshop: workshop,
    );
  }

  bool get isWorkshop {
    if (recentContent != null) {
      return recentContent!.isWorkshopDay;
    }

    return workshop != null;
  }

  String get contentKindLabel {
    return isWorkshop
        ? 'Atölye'
        : 'Meditasyon';
  }

  String get title {
    if (recentContent != null) {
      return recentContent!.title;
    }

    if (meditation != null) {
      return meditation!.title;
    }

    return workshop?.title ?? 'İçerik';
  }

  String get subtitle {
    if (recentContent != null) {
      return recentContent!.subtitle;
    }

    if (meditation != null) {
      return meditation!.description;
    }

    if (workshop != null) {
      final description =
          workshop!.description.trim();

      final teacherName =
          workshop!.teacherName.trim();

      if (description.isNotEmpty &&
          teacherName.isNotEmpty) {
        return '$description • $teacherName';
      }

      if (description.isNotEmpty) {
        return description;
      }

      return teacherName;
    }

    return '';
  }

  String get imageUrl {
    if (recentContent != null) {
      return recentContent!.imageUrl;
    }

    if (meditation != null) {
      return meditation!.thumbnailUrl;
    }

    return workshop?.imageUrl ?? '';
  }

  String get typeLabel {
    if (recentContent != null) {
      return recentContent!.typeLabel;
    }

    if (meditation != null) {
      return meditation!.typeLabel;
    }

    return 'Atölye';
  }

  String get durationText {
    if (recentContent != null) {
      return recentContent!.durationText;
    }

    if (meditation != null) {
      return meditation!.durationText;
    }

    return workshop?.durationLabel ?? '';
  }

  IconData get icon {
    if (recentContent != null) {
      if (recentContent!.isWorkshopDay) {
        return Icons.auto_awesome_mosaic_outlined;
      }

      if (recentContent!.meditation?.isVideo ==
          true) {
        return Icons.play_circle_outline;
      }

      if (recentContent!.meditation?.isLink ==
          true) {
        return Icons.link;
      }

      return Icons.headphones;
    }

    if (meditation != null) {
      if (meditation!.isVideo) {
        return Icons.play_circle_outline;
      }

      if (meditation!.isLink) {
        return Icons.link;
      }

      return Icons.headphones;
    }

    return Icons.auto_awesome_mosaic_outlined;
  }
}