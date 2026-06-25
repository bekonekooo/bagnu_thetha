import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/theme.dart';

import 'package:flutter_application_1/features/social/data/models/social_target.dart';
import 'package:flutter_application_1/features/social/data/services/favorite_service.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

import 'package:flutter_application_1/features/teachers/data/models/teacher_model.dart';
import 'package:flutter_application_1/features/teachers/data/services/teacher_service.dart';
import 'package:flutter_application_1/features/teachers/presentation/widgets/teacher_card.dart';
import 'package:flutter_application_1/features/teachers/presentation/pages/teacher_detail_page.dart';

import 'package:flutter_application_1/features/trainings/data/models/training_model.dart';
import 'package:flutter_application_1/features/trainings/data/services/training_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softCream,
      appBar: AppBar(
        title: const Text('Favorilerim'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textSoft,
          indicatorColor: AppTheme.primaryPurple,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Meditasyonlar'),
            Tab(text: 'Öğretmenler'),
            Tab(text: 'Eğitimler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MeditationFavoritesTab(),
          _TeacherFavoritesTab(),
          _TrainingFavoritesTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI helpers
// ---------------------------------------------------------------------------

class _FavoritesStates {
  static Widget loading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryPurple,
      ),
    );
  }

  static Widget empty({
    required IconData icon,
    required Future<void> Function() onRetry,
  }) {
    return RefreshIndicator(
      color: AppTheme.primaryPurple,
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: 80),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.softPurple,
              child: Icon(
                icon,
                size: 42,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Henüz favori eklemedin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Beğendiğin içerikleri kalp ikonuna dokunarak buraya ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSoft,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

}

class RefreshIndicatorErrorView extends StatelessWidget {
  final Object? error;
  final Future<void> Function() onRetry;

  const RefreshIndicatorErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryPurple,
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Center(
            child: Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Favoriler yüklenemedi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bağlantını kontrol edip tekrar dene.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSoft,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meditations tab
// ---------------------------------------------------------------------------

class _MeditationFavoritesTab extends StatefulWidget {
  const _MeditationFavoritesTab();

  @override
  State<_MeditationFavoritesTab> createState() =>
      _MeditationFavoritesTabState();
}

class _MeditationFavoritesTabState extends State<_MeditationFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  final _favoriteService = FavoriteService();
  final _meditationService = MeditationService();

  late Future<List<MeditationModel>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MeditationModel>> _load() async {
    final favorites = await _favoriteService.fetchMyFavorites(
      type: SocialTarget.meditation,
    );

    if (favorites.isEmpty) {
      return <MeditationModel>[];
    }

    final favoriteIds = favorites.map((f) => f.targetId).toSet();

    final all = await _meditationService.fetchActiveMeditations();

    final result = all.where((m) => favoriteIds.contains(m.id)).toList();

    // Preserve favorite order (most recent first).
    final orderIndex = <String, int>{};
    for (var i = 0; i < favorites.length; i++) {
      orderIndex[favorites[i].targetId] = i;
    }
    result.sort(
      (a, b) =>
          (orderIndex[a.id] ?? 1 << 30).compareTo(orderIndex[b.id] ?? 1 << 30),
    );

    return result;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _remove(MeditationModel meditation) async {
    try {
      await _favoriteService.removeFavorite(
        SocialTarget.meditation,
        meditation.id,
      );

      if (!mounted) return;

      setState(() {
        _future = _future.then(
          (list) => list.where((m) => m.id != meditation.id).toList(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilerden çıkarıldı.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favori kaldırılamadı. Lütfen tekrar dene.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<MeditationModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _FavoritesStates.loading();
        }

        if (snapshot.hasError) {
          return RefreshIndicatorErrorView(
            error: snapshot.error,
            onRetry: _refresh,
          );
        }

        final meditations = snapshot.data ?? const <MeditationModel>[];

        if (meditations.isEmpty) {
          return _FavoritesStates.empty(
            icon: Icons.self_improvement,
            onRetry: _refresh,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: meditations.length,
            itemBuilder: (context, index) {
              final meditation = meditations[index];

              return _MeditationFavoriteCard(
                meditation: meditation,
                onTap: () => context.push(
                  '/meditation-detail',
                  extra: meditation,
                ),
                onRemove: () => _remove(meditation),
              );
            },
          ),
        );
      },
    );
  }
}

class _MeditationFavoriteCard extends StatelessWidget {
  final MeditationModel meditation;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MeditationFavoriteCard({
    required this.meditation,
    required this.onTap,
    required this.onRemove,
  });

  IconData _iconForType(String type) {
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

  @override
  Widget build(BuildContext context) {
    final hasThumb = meditation.thumbnailUrl.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: hasThumb
                      ? CachedNetworkImage(
                          imageUrl: meditation.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.softPurple,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.softPurple,
                            child: Icon(
                              _iconForType(meditation.type),
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.softPurple,
                          child: Icon(
                            _iconForType(meditation.type),
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _iconForType(meditation.type),
                          size: 14,
                          color: AppTheme.textSoft,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            [
                              meditation.typeLabel,
                              if (meditation.durationText.trim().isNotEmpty)
                                meditation.durationText,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _FavoriteHeartButton(onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Teachers tab
// ---------------------------------------------------------------------------

class _TeacherFavoritesTab extends StatefulWidget {
  const _TeacherFavoritesTab();

  @override
  State<_TeacherFavoritesTab> createState() => _TeacherFavoritesTabState();
}

class _TeacherFavoritesTabState extends State<_TeacherFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  final _favoriteService = FavoriteService();
  final _teacherService = TeacherService();

  late Future<List<TeacherModel>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TeacherModel>> _load() async {
    final favorites = await _favoriteService.fetchMyFavorites(
      type: SocialTarget.teacher,
    );

    if (favorites.isEmpty) {
      return <TeacherModel>[];
    }

    final favoriteIds = favorites.map((f) => f.targetId).toSet();

    final all = await _teacherService.fetchTeachers();

    final result = all.where((t) => favoriteIds.contains(t.id)).toList();

    final orderIndex = <String, int>{};
    for (var i = 0; i < favorites.length; i++) {
      orderIndex[favorites[i].targetId] = i;
    }
    result.sort(
      (a, b) =>
          (orderIndex[a.id] ?? 1 << 30).compareTo(orderIndex[b.id] ?? 1 << 30),
    );

    return result;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _remove(TeacherModel teacher) async {
    try {
      await _favoriteService.removeFavorite(
        SocialTarget.teacher,
        teacher.id,
      );

      if (!mounted) return;

      setState(() {
        _future = _future.then(
          (list) => list.where((t) => t.id != teacher.id).toList(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilerden çıkarıldı.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favori kaldırılamadı. Lütfen tekrar dene.'),
        ),
      );
    }
  }

  void _openDetail(TeacherModel teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherDetailPage(
          teacher: teacher.toMap(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<TeacherModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _FavoritesStates.loading();
        }

        if (snapshot.hasError) {
          return RefreshIndicatorErrorView(
            error: snapshot.error,
            onRetry: _refresh,
          );
        }

        final teachers = snapshot.data ?? const <TeacherModel>[];

        if (teachers.isEmpty) {
          return _FavoritesStates.empty(
            icon: Icons.person_outline,
            onRetry: _refresh,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];

              return Stack(
                children: [
                  TeacherCard(
                    name: teacher.name,
                    specialty: teacher.specialty,
                    category: teacher.category,
                    experience: teacher.experience,
                    rating: teacher.rating,
                    bio: teacher.bio,
                    imageUrl: teacher.imageUrl,
                    sessionPrice: teacher.sessionPrice,
                    currency: teacher.currency,
                    onTap: () => _openDetail(teacher),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavoriteHeartButton(
                      onPressed: () => _remove(teacher),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Trainings tab
// ---------------------------------------------------------------------------

class _TrainingFavoritesTab extends StatefulWidget {
  const _TrainingFavoritesTab();

  @override
  State<_TrainingFavoritesTab> createState() => _TrainingFavoritesTabState();
}

class _TrainingFavoritesTabState extends State<_TrainingFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  final _favoriteService = FavoriteService();
  final _trainingService = TrainingService();

  late Future<List<TrainingModel>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TrainingModel>> _load() async {
    final favorites = await _favoriteService.fetchMyFavorites(
      type: SocialTarget.training,
    );

    if (favorites.isEmpty) {
      return <TrainingModel>[];
    }

    final favoriteIds = favorites.map((f) => f.targetId).toSet();

    final all = await _trainingService.fetchActiveTrainings();

    final result = all.where((t) => favoriteIds.contains(t.id)).toList();

    final orderIndex = <String, int>{};
    for (var i = 0; i < favorites.length; i++) {
      orderIndex[favorites[i].targetId] = i;
    }
    result.sort(
      (a, b) =>
          (orderIndex[a.id] ?? 1 << 30).compareTo(orderIndex[b.id] ?? 1 << 30),
    );

    return result;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _remove(TrainingModel training) async {
    try {
      await _favoriteService.removeFavorite(
        SocialTarget.training,
        training.id,
      );

      if (!mounted) return;

      setState(() {
        _future = _future.then(
          (list) => list.where((t) => t.id != training.id).toList(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilerden çıkarıldı.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favori kaldırılamadı. Lütfen tekrar dene.'),
        ),
      );
    }
  }

  String _formatPrice(TrainingModel training) {
    if (training.price <= 0) {
      return 'Ücretsiz';
    }

    final clean = training.price % 1 == 0
        ? training.price.toInt().toString()
        : training.price.toStringAsFixed(2);

    if (training.currency.toLowerCase() == 'try') {
      return '₺$clean';
    }

    return '$clean ${training.currency.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<TrainingModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _FavoritesStates.loading();
        }

        if (snapshot.hasError) {
          return RefreshIndicatorErrorView(
            error: snapshot.error,
            onRetry: _refresh,
          );
        }

        final trainings = snapshot.data ?? const <TrainingModel>[];

        if (trainings.isEmpty) {
          return _FavoritesStates.empty(
            icon: Icons.school_outlined,
            onRetry: _refresh,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: trainings.length,
            itemBuilder: (context, index) {
              final training = trainings[index];

              return _TrainingFavoriteCard(
                training: training,
                priceLabel: _formatPrice(training),
                onTap: () => context.push(
                  '/training-detail',
                  extra: {
                    'training': training,
                  },
                ),
                onRemove: () => _remove(training),
              );
            },
          ),
        );
      },
    );
  }
}

class _TrainingFavoriteCard extends StatelessWidget {
  final TrainingModel training;
  final String priceLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _TrainingFavoriteCard({
    required this.training,
    required this.priceLabel,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = training.imageUrl.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: training.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.softPurple,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.softPurple,
                            child: const Icon(
                              Icons.school_outlined,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.softPurple,
                          child: const Icon(
                            Icons.school_outlined,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      training.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: AppTheme.textSoft,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            [
                              priceLabel,
                              if (training.teacherName.trim().isNotEmpty)
                                training.teacherName,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _FavoriteHeartButton(onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heart button
// ---------------------------------------------------------------------------

class _FavoriteHeartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FavoriteHeartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Favorilerden çıkar',
      icon: const Icon(
        Icons.favorite,
        color: AppTheme.primaryPurple,
      ),
    );
  }
}
