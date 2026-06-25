import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/trainings/data/models/training_model.dart';
import 'package:flutter_application_1/features/trainings/data/services/training_service.dart';

class TrainingsPage extends StatefulWidget {
  const TrainingsPage({super.key});

  @override
  State<TrainingsPage> createState() => _TrainingsPageState();
}

class _TrainingsPageState extends State<TrainingsPage> {
  final TrainingService trainingService = TrainingService();

  late Future<List<TrainingModel>> trainingsFuture;
  Map<String, bool> joinedMap = {};

  int selectedMenuIndex = 0;

  List<TrainingModel> allTrainings = [];
  List<TrainingModel> upcoming = [];
  List<TrainingModel> ongoing = [];
  List<TrainingModel> completed = [];

  static const String pageBackground =
      'assets/images/backgrounds/home_bg_5.jpg';

  @override
  void initState() {
    super.initState();
    trainingsFuture = loadTrainings();
  }

  Future<List<TrainingModel>> loadTrainings() async {
    final trainings = await trainingService.fetchActiveTrainings();

    final ids = trainings.map((item) => item.id).toList();
    final joined = await trainingService.fetchJoinedMap(ids);

    if (mounted) {
      setState(() {
        joinedMap = joined;
        rebuildTrainingBuckets(trainings);
      });
    } else {
      rebuildTrainingBuckets(trainings);
    }

    return trainings;
  }

  void rebuildTrainingBuckets(List<TrainingModel> items) {
    allTrainings = items;
    upcoming = items.where((item) => item.isUpcoming).toList();
    ongoing = items.where((item) => item.isOngoing).toList();
    completed = items.where((item) => item.isCompleted).toList();
  }

  List<TrainingModel> get selectedTrainings {
    if (selectedMenuIndex == 0) {
      return upcoming;
    }

    if (selectedMenuIndex == 1) {
      return ongoing;
    }

    return completed;
  }

  Future<void> refreshTrainings() async {
    setState(() {
      trainingsFuture = loadTrainings();
    });

    await trainingsFuture;
  }

  Future<void> joinOrLeaveTraining(TrainingModel training) async {
    final isJoined = joinedMap[training.id] == true;

    try {
      if (isJoined) {
        await trainingService.leaveTraining(training.id);
        showMessage('Katılımın iptal edildi.');
      } else {
        await trainingService.joinTraining(training.id);
        showMessage('Eğitime katıldın.');
      }

      await refreshTrainings();
    } catch (e) {
      showMessage('İşlem yapılamadı: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String get selectedTitle {
    if (selectedMenuIndex == 0) {
      return 'Yaklaşan Eğitimler';
    }

    if (selectedMenuIndex == 1) {
      return 'Devam Eden Eğitimler';
    }

    return 'Bitmiş Eğitimler';
  }

  String get selectedEmptyText {
    if (selectedMenuIndex == 0) {
      return 'Yaklaşan eğitim bulunmuyor.';
    }

    if (selectedMenuIndex == 1) {
      return 'Şu anda devam eden eğitim bulunmuyor.';
    }

    return 'Bitmiş eğitim bulunmuyor.';
  }

  Widget buildBackgroundBody({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            pageBackground,
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
                  Colors.black.withOpacity(0.20),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
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
              Icons.school_outlined,
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
                  'Eğitimler',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Eğitimleri durumlarına göre ayrı sekmelerden takip edebilirsin.',
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

  Widget buildTopMenu({
    required int upcomingCount,
    required int ongoingCount,
    required int completedCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          buildTopMenuItem(
            index: 0,
            title: 'Yaklaşan',
            count: upcomingCount,
            icon: Icons.event_available_outlined,
          ),
          buildTopMenuItem(
            index: 1,
            title: 'Devam Eden',
            count: ongoingCount,
            icon: Icons.play_circle_outline,
          ),
          buildTopMenuItem(
            index: 2,
            title: 'Bitmiş',
            count: completedCount,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget buildTopMenuItem({
    required int index,
    required String title,
    required int count,
    required IconData icon,
  }) {
    final isSelected = selectedMenuIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () {
          setState(() {
            selectedMenuIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF536B4E)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF536B4E),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF2F3A32),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.20)
                      : const Color(0xFFEEF3EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF536B4E),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F3A32),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFF536B4E),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImageFallback() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(
          Icons.school_outlined,
          color: Color(0xFF536B4E),
          size: 46,
        ),
      ),
    );
  }

  Widget buildTrainingCard(TrainingModel training) {
    final isJoined = joinedMap[training.id] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () async {
        await context.push(
          '/training-detail',
          extra: {
            'training': training,
            'isJoined': isJoined,
          },
        );

        await refreshTrainings();
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (training.imageUrl.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: training.imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    placeholder: (context, url) => buildImageFallback(),
                    errorWidget: (context, url, error) {
                      return buildImageFallback();
                    },
                  ),
                )
              else
                buildImageFallback(),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _MiniTag(text: training.statusLabel),
                  _MiniTag(text: training.formattedPrice),
                  _MiniTag(text: training.formattedLocationType),
                  if (training.category.trim().isNotEmpty)
                    _MiniTag(text: training.category),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                training.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F3A32),
                ),
              ),
              if (training.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  training.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF606A61),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (training.teacherName.trim().isNotEmpty)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFEEF3EA),
                      backgroundImage: training.teacherImageUrl.isNotEmpty
                          ? NetworkImage(training.teacherImageUrl)
                          : null,
                      child: training.teacherImageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFF536B4E),
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        training.teacherName,
                        style: const TextStyle(
                          color: Color(0xFF2F3A32),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              if (training.sessions.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...training.sessions.take(3).map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 18,
                          color: Color(0xFF536B4E),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${session.formattedDate} / ${session.formattedTimeRange}',
                            style: const TextStyle(
                              color: Color(0xFF606A61),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (training.sessions.length > 3)
                  Text(
                    '+${training.sessions.length - 3} oturum daha',
                    style: const TextStyle(
                      color: Color(0xFF536B4E),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: training.isCompleted
                      ? null
                      : () => joinOrLeaveTraining(training),
                  icon: Icon(
                    isJoined ? Icons.check_circle : Icons.add_circle_outline,
                  ),
                  label: Text(
                    training.isCompleted
                        ? 'Eğitim Bitmiş'
                        : isJoined
                            ? 'Katıldın - İptal Et'
                            : 'Eğitime Katıl',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJoined
                        ? Colors.grey.shade700
                        : const Color(0xFF536B4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Detayları görmek için karta dokun',
                  style: TextStyle(
                    color: Color(0xFF606A61),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSelectedEmptyCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        selectedEmptyText,
        style: const TextStyle(
          color: Color(0xFF606A61),
          fontWeight: FontWeight.w700,
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
          'Eğitimler',
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
            onRefresh: refreshTrainings,
            child: FutureBuilder<List<TrainingModel>>(
              future: trainingsFuture,
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
                          'Eğitimler yüklenemedi: ${snapshot.error}',
                          style: const TextStyle(
                            color: Color(0xFF2F3A32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final selectedItems = selectedTrainings;

                final headerWidgets = <Widget>[
                  buildHeroCard(),
                  const SizedBox(height: 16),
                  buildTopMenu(
                    upcomingCount: upcoming.length,
                    ongoingCount: ongoing.length,
                    completedCount: completed.length,
                  ),
                  const SizedBox(height: 18),
                  buildSectionTitle(selectedTitle, selectedItems.length),
                  if (selectedItems.isEmpty) buildSelectedEmptyCard(),
                ];

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  itemCount: headerWidgets.length + selectedItems.length,
                  itemBuilder: (context, index) {
                    if (index < headerWidgets.length) {
                      return headerWidgets[index];
                    }

                    final training = selectedItems[index - headerWidgets.length];
                    return buildTrainingCard(training);
                  },
                );
              },
            ),
          ),
        ),
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