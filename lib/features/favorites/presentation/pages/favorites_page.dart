import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/favorites/data/models/recent_content_model.dart';
import 'package:flutter_application_1/features/favorites/data/services/content_history_service.dart';

import 'package:flutter_application_1/features/guidance/data/services/guidance_service.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

import 'package:flutter_application_1/features/workshops/data/models/workshop_model.dart';
import 'package:flutter_application_1/features/workshops/data/services/workshop_service.dart';

enum FavoriteTab {
  recentlyPlayed,
  liked,
  guidance,
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
  });

  @override
  State<FavoritesPage> createState() =>
      _FavoritesPageState();
}

class _FavoritesPageState
    extends State<FavoritesPage> {
  final ContentHistoryService contentHistoryService =
      ContentHistoryService();

  final MeditationService meditationService =
      MeditationService();

  final WorkshopService workshopService =
      WorkshopService();

  final GuidanceService guidanceService =
      GuidanceService();

  FavoriteTab selectedTab =
      FavoriteTab.recentlyPlayed;

  late Future<List<_FavoriteEntry>>
      entriesFuture;

  static const Color primaryColor =
      Color(0xFF536B4E);

  static const Color textColor =
      Color(0xFF2F3A32);

  static const Color secondaryTextColor =
      Color(0xFF606A61);

  static const Color softGreen =
      Color(0xFFEEF3EA);

  static const Color dangerColor =
      Color(0xFFC85C5C);

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_1.jpg';

  @override
  void initState() {
    super.initState();

    entriesFuture = loadEntries();
  }

  Future<List<_FavoriteEntry>>
      loadEntries() async {
    switch (selectedTab) {
      case FavoriteTab.recentlyPlayed:
        final recentContents =
            await contentHistoryService
                .fetchRecentContents(
          limit: 10,
        );

        return recentContents
            .map(
              (content) =>
                  _FavoriteEntry.recent(
                content,
              ),
            )
            .toList();

      case FavoriteTab.liked:
        final results =
            await Future.wait<dynamic>([
          meditationService
              .fetchMyFavoriteMeditations(),
          workshopService
              .fetchMyFavoriteWorkshops(),
        ]);

        final meditations =
            results[0]
                as List<MeditationModel>;

        final workshops =
            results[1]
                as List<WorkshopModel>;

        return [
          ...meditations.map(
            (meditation) =>
                _FavoriteEntry.meditation(
              meditation,
            ),
          ),
          ...workshops.map(
            (workshop) =>
                _FavoriteEntry.workshop(
              workshop,
            ),
          ),
        ];

      case FavoriteTab.guidance:
        final guidanceItems =
            await guidanceService
                .fetchMyGuidanceHistory();

        return guidanceItems
            .map(
              (guidance) =>
                  _FavoriteEntry.guidance(
                guidance,
              ),
            )
            .toList();
    }
  }

  Future<void> refreshFavorites() async {
    final newFuture = loadEntries();

    setState(() {
      entriesFuture = newFuture;
    });

    await newFuture;
  }

  void changeTab(
    FavoriteTab tab,
  ) {
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
    if (entry.guidance != null) {
      showGuidanceResult(
        entry.guidance!,
      );
      return;
    }

    final recentContent =
        entry.recentContent;

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
            await workshopService
                .hasJoinedWorkshop(
          recentContent.workshop!.id,
        );

        if (!mounted) return;

        await context.push(
          '/workshop-detail',
          extra: {
            'workshop':
                recentContent.workshop!,
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
          await workshopService
              .hasJoinedWorkshop(
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

  void showGuidanceResult(
    GuidanceHistoryModel guidance,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F6F0),
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  34,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            Colors.grey.shade400,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color: softGreen,
                          borderRadius:
                              BorderRadius
                                  .circular(17),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: primaryColor,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              guidance.typeLabel,
                              style:
                                  const TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                            if (guidance
                                .fullName
                                .trim()
                                .isNotEmpty)
                              Text(
                                guidance.fullName,
                                style:
                                    const TextStyle(
                                  color:
                                      secondaryTextColor,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                  if (guidance
                      .formattedDate
                      .isNotEmpty) ...[
                    const SizedBox(height: 14),
                    buildGuidanceInfoTag(
                      icon:
                          Icons.calendar_today,
                      text:
                          guidance.formattedDate,
                    ),
                  ],
                  if (guidance
                      .chartImageUrl
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      child: Image.network(
                        guidance.chartImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Container(
                            height: 180,
                            color: softGreen,
                            alignment:
                                Alignment.center,
                            child: const Icon(
                              Icons
                                  .image_not_supported_outlined,
                              color:
                                  primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: Text(
                      guidance.result,
                      style:
                          const TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        height: 1.55,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Bu yorum kişisel farkındalık ve eğlence amaçlıdır; kesin gelecek tahmini değildir.',
                    style: TextStyle(
                      color:
                          secondaryTextColor,
                      fontSize: 12,
                      height: 1.4,
                      fontStyle:
                          FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildGuidanceInfoTag({
    required IconData icon,
    required String text,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: softGreen,
          borderRadius:
              BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 11.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> clearHistory() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
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
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    dangerColor,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Temizle'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await contentHistoryService
          .clearMyHistory();

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

  void showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String get sectionTitle {
    switch (selectedTab) {
      case FavoriteTab.recentlyPlayed:
        return 'En Son Oynatılan 10 İçerik';

      case FavoriteTab.liked:
        return 'Beğenilenler';

      case FavoriteTab.guidance:
        return 'Rehberlik Geçmişim';
    }
  }

  String get emptyTitle {
    switch (selectedTab) {
      case FavoriteTab.recentlyPlayed:
        return 'Henüz oynatılan içerik yok';

      case FavoriteTab.liked:
        return 'Henüz beğenilen içerik yok';

      case FavoriteTab.guidance:
        return 'Henüz rehberlik sonucu yok';
    }
  }

  String get emptySubtitle {
    switch (selectedTab) {
      case FavoriteTab.recentlyPlayed:
        return 'Meditasyon veya atölye içeriği oynattığında burada görünecek.';

      case FavoriteTab.liked:
        return 'Beğendiğin meditasyonlar ve atölyeler burada görünecek.';

      case FavoriteTab.guidance:
        return 'AI rehberliği oluşturduğunda sonuçların burada saklanacak.';
    }
  }

  Widget buildBackground({
    required Widget child,
  }) {
    return Container(
      color: const Color(0xFFF5F0E8),
      child: child,
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
              fontWeight:
                  FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        if (selectedTab ==
            FavoriteTab.recentlyPlayed)
          IconButton(
            onPressed: clearHistory,
            tooltip:
                'Geçmişi Temizle',
            style:
                IconButton.styleFrom(
              backgroundColor:
                  Colors.white
                      .withOpacity(0.76),
              foregroundColor:
                  dangerColor,
            ),
            icon: const Icon(
              Icons
                  .delete_sweep_outlined,
            ),
          ),
      ],
    );
  }

  Widget buildTabSelector() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.76,
        ),
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.68,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: buildTabButton(
              tab: FavoriteTab
                  .recentlyPlayed,
              icon:
                  Icons.history_rounded,
              title:
                  'Son\nOynatılan',
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: buildTabButton(
              tab: FavoriteTab.liked,
              icon:
                  Icons.favorite_rounded,
              title: 'Beğeniler',
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: buildTabButton(
              tab:
                  FavoriteTab.guidance,
              icon:
                  Icons.auto_awesome,
              title: 'Rehberlik',
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
    final selected =
        selectedTab == tab;

    return InkWell(
      onTap: () {
        changeTab(tab);
      },
      borderRadius:
          BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        height: 82,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(18),
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
              size: 22,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : textColor,
                fontSize: 11,
                height: 1.08,
                fontWeight:
                    FontWeight.w900,
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
    final imageUrl =
        entry.imageUrl.trim();

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.82,
        ),
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.72,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.09,
            ),
            blurRadius: 22,
            offset:
                const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            openEntry(entry);
          },
          borderRadius:
              BorderRadius.circular(26),
          child: Padding(
            padding:
                const EdgeInsets.all(
              14,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius
                          .circular(18),
                  child: SizedBox(
                    width: 82,
                    height: 82,
                    child:
                        imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit:
                                    BoxFit.cover,
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
                const SizedBox(
                  width: 13,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          buildTag(
                            entry
                                .contentKindLabel,
                          ),
                          if (entry
                              .typeLabel
                              .trim()
                              .isNotEmpty)
                            buildTag(
                              entry.typeLabel,
                            ),
                          if (entry
                              .durationText
                              .trim()
                              .isNotEmpty)
                            buildTag(
                              entry
                                  .durationText,
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              textColor,
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w900,
                          height: 1.2,
                        ),
                      ),
                      if (entry
                          .subtitle
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          entry.subtitle,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                secondaryTextColor,
                            fontSize:
                                12.5,
                            height: 1.35,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      softGreen,
                  child: Icon(
                    entry.trailingIcon,
                    color:
                        entry.trailingColor,
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
      alignment:
          Alignment.center,
      child: Icon(
        icon,
        color: primaryColor,
        size: 34,
      ),
    );
  }

  Widget buildTag(
    String text,
  ) {
    if (text.trim().isEmpty) {
      return const SizedBox
          .shrink();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 10.5,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.82,
        ),
        borderRadius:
            BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Icon(
            selectedTab ==
                    FavoriteTab.guidance
                ? Icons.auto_awesome
                : selectedTab ==
                        FavoriteTab
                            .recentlyPlayed
                    ? Icons
                        .history_rounded
                    : Icons
                        .favorite_border_rounded,
            color: primaryColor,
            size: 48,
          ),
          const SizedBox(height: 13),
          Text(
            emptyTitle,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            emptySubtitle,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color:
                  secondaryTextColor,
              height: 1.4,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorState(
    Object error,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.84,
        ),
        borderRadius:
            BorderRadius.circular(24),
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
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color:
                  secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed:
                refreshFavorites,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Tekrar Dene',
            ),
            style: ElevatedButton
                .styleFrom(
              backgroundColor:
                  primaryColor,
              foregroundColor:
                  Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    return RefreshIndicator(
      onRefresh:
          refreshFavorites,
      color: primaryColor,
      child: FutureBuilder<
          List<_FavoriteEntry>>(
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
            padding:
                const EdgeInsets
                    .fromLTRB(
              18,
              18,
              18,
              30,
            ),
            children: [
              buildHeader(),
              const SizedBox(
                height: 18,
              ),
              buildTabSelector(),
              const SizedBox(
                height: 24,
              ),
              Text(
                sectionTitle,
                style:
                    const TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 13,
              ),
              if (snapshot
                      .connectionState ==
                  ConnectionState
                      .waiting)
                const Padding(
                  padding:
                      EdgeInsets.all(
                    35,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          primaryColor,
                    ),
                  ),
                )
              else if (snapshot
                  .hasError)
                buildErrorState(
                  snapshot.error!,
                )
              else if (entries
                  .isEmpty)
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      extendBodyBehindAppBar:
          true,
      backgroundColor:
          Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Favorilerim',
          style: TextStyle(
            color: textColor,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        backgroundColor:
            Colors.white.withOpacity(
          0.14,
        ),
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,
        foregroundColor:
            textColor,
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
  final GuidanceHistoryModel? guidance;

  const _FavoriteEntry._({
    required this.recentContent,
    required this.meditation,
    required this.workshop,
    required this.guidance,
  });

  factory _FavoriteEntry.recent(
    RecentContentModel content,
  ) {
    return _FavoriteEntry._(
      recentContent: content,
      meditation: null,
      workshop: null,
      guidance: null,
    );
  }

  factory _FavoriteEntry.meditation(
    MeditationModel meditation,
  ) {
    return _FavoriteEntry._(
      recentContent: null,
      meditation: meditation,
      workshop: null,
      guidance: null,
    );
  }

  factory _FavoriteEntry.workshop(
    WorkshopModel workshop,
  ) {
    return _FavoriteEntry._(
      recentContent: null,
      meditation: null,
      workshop: workshop,
      guidance: null,
    );
  }

  factory _FavoriteEntry.guidance(
    GuidanceHistoryModel guidance,
  ) {
    return _FavoriteEntry._(
      recentContent: null,
      meditation: null,
      workshop: null,
      guidance: guidance,
    );
  }

  bool get isWorkshop {
    if (recentContent != null) {
      return recentContent!
          .isWorkshopDay;
    }

    return workshop != null;
  }

  String get contentKindLabel {
    if (guidance != null) {
      return 'Rehberlik';
    }

    return isWorkshop
        ? 'Atölye'
        : 'Meditasyon';
  }

  String get title {
    if (guidance != null) {
      return guidance!.title;
    }

    if (recentContent != null) {
      return recentContent!.title;
    }

    if (meditation != null) {
      return meditation!.title;
    }

    return workshop?.title ??
        'İçerik';
  }

  String get subtitle {
    if (guidance != null) {
      return guidance!.subtitle;
    }

    if (recentContent != null) {
      return recentContent!
          .subtitle;
    }

    if (meditation != null) {
      return meditation!
          .description;
    }

    if (workshop != null) {
      final description =
          workshop!.description
              .trim();

      final teacherName =
          workshop!.teacherName
              .trim();

      if (description
              .isNotEmpty &&
          teacherName.isNotEmpty) {
        return '$description • $teacherName';
      }

      if (description
          .isNotEmpty) {
        return description;
      }

      return teacherName;
    }

    return '';
  }

  String get imageUrl {
    if (guidance != null) {
      return guidance!
          .chartImageUrl;
    }

    if (recentContent != null) {
      return recentContent!
          .imageUrl;
    }

    if (meditation != null) {
      return meditation!
          .thumbnailUrl;
    }

    return workshop?.imageUrl ??
        '';
  }

  String get typeLabel {
    if (guidance != null) {
      return guidance!.typeLabel;
    }

    if (recentContent != null) {
      return recentContent!
          .typeLabel;
    }

    if (meditation != null) {
      return meditation!
          .typeLabel;
    }

    return 'Atölye';
  }

  String get durationText {
    if (guidance != null) {
      return guidance!
          .formattedDate;
    }

    if (recentContent != null) {
      return recentContent!
          .durationText;
    }

    if (meditation != null) {
      return meditation!
          .durationText;
    }

    return workshop
            ?.durationLabel ??
        '';
  }

  IconData get icon {
    if (guidance != null) {
      return Icons.auto_awesome;
    }

    if (recentContent != null) {
      if (recentContent!
          .isWorkshopDay) {
        return Icons
            .auto_awesome_mosaic_outlined;
      }

      if (recentContent!
              .meditation
              ?.isVideo ==
          true) {
        return Icons
            .play_circle_outline;
      }

      if (recentContent!
              .meditation
              ?.isLink ==
          true) {
        return Icons.link;
      }

      return Icons.headphones;
    }

    if (meditation != null) {
      if (meditation!.isVideo) {
        return Icons
            .play_circle_outline;
      }

      if (meditation!.isLink) {
        return Icons.link;
      }

      return Icons.headphones;
    }

    return Icons
        .auto_awesome_mosaic_outlined;
  }

  IconData get trailingIcon {
    if (guidance != null) {
      return Icons.auto_awesome;
    }

    if (recentContent != null) {
      return Icons.history_rounded;
    }

    return Icons.favorite_rounded;
  }

  Color get trailingColor {
    if (guidance != null) {
      return const Color(0xFF8A6AAE);
    }

    if (recentContent != null) {
      return const Color(0xFF536B4E);
    }

    return const Color(0xFFC85C5C);
  }
}
