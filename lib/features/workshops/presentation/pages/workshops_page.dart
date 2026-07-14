import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/workshop_model.dart';
import '../../data/services/workshop_service.dart';

class WorkshopsPage extends StatefulWidget {
  const WorkshopsPage({super.key});

  @override
  State<WorkshopsPage> createState() => _WorkshopsPageState();
}

class _WorkshopsPageState extends State<WorkshopsPage> {
  final WorkshopService workshopService = WorkshopService();

  late Future<List<WorkshopModel>> workshopsFuture;

  Map<String, bool> joinedMap = {};

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_1.jpg';

  static const Color primaryColor = Color(0xFF536B4E);
  static const Color textColor = Color(0xFF2F3A32);
  static const Color secondaryTextColor = Color(0xFF606A61);
  static const Color softGreen = Color(0xFFEEF3EA);
  static const Color borderColor = Color(0xFFD7E1D0);

  @override
  void initState() {
    super.initState();
    workshopsFuture = loadWorkshops();
  }

  Future<List<WorkshopModel>> loadWorkshops() async {
    final workshops = await workshopService.fetchActiveWorkshops();

    final ids = workshops
        .map((workshop) => workshop.id)
        .where((id) => id.trim().isNotEmpty)
        .toList();

    final fetchedJoinedMap =
        await workshopService.fetchJoinedMap(ids);

    if (mounted) {
      setState(() {
        joinedMap = fetchedJoinedMap;
      });
    }

    return workshops;
  }

  Future<void> refreshWorkshops() async {
    setState(() {
      workshopsFuture = loadWorkshops();
    });

    await workshopsFuture;
  }

  Future<void> openWorkshopDetail(
    WorkshopModel workshop,
  ) async {
    final result = await context.push(
      '/workshop-detail',
      extra: {
        'workshop': workshop,
        'isJoined': joinedMap[workshop.id] == true,
      },
    );

    if (result == true) {
      await refreshWorkshops();
    }
  }

  Widget buildBackgroundBody({
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
            color: Colors.white.withOpacity(0.20),
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
                  Colors.white.withOpacity(0.08),
                  Colors.black.withOpacity(0.16),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_mosaic_outlined,
              color: primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Atölyeler',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Ses, video ve rehberlik içeriklerinden oluşan kayıtlı atölyelere katıl.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(
    int count,
  ) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Aktif Atölyeler',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Text(
            '$count atölye',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildWorkshopCard(
    WorkshopModel workshop,
  ) {
    final hasImage =
        workshop.imageUrl.trim().isNotEmpty;

    final isJoined =
        joinedMap[workshop.id] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            openWorkshopDetail(workshop);
          },
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(27),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 190,
                        child: hasImage
                            ? Image.network(
                                workshop.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return buildImagePlaceholder();
                                },
                              )
                            : buildImagePlaceholder(),
                      ),
                    ),
                    Positioned(
                      top: 13,
                      right: 13,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isJoined
                              ? const Color(0xFFE7F4E8)
                              : Colors.white.withOpacity(0.92),
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isJoined
                                  ? Icons.check_circle
                                  : Icons.lock_open_outlined,
                              size: 16,
                              color: isJoined
                                  ? const Color(0xFF3D7A48)
                                  : primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isJoined
                                  ? 'Kayıtlısın'
                                  : 'Katılıma Açık',
                              style: TextStyle(
                                color: isJoined
                                    ? const Color(
                                        0xFF3D7A48,
                                      )
                                    : primaryColor,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        workshop.title,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      if (workshop.teacherName
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: softGreen,
                              backgroundImage: workshop
                                      .teacherImageUrl
                                      .trim()
                                      .isNotEmpty
                                  ? NetworkImage(
                                      workshop
                                          .teacherImageUrl,
                                    )
                                  : null,
                              child: workshop
                                      .teacherImageUrl
                                      .trim()
                                      .isEmpty
                                  ? const Icon(
                                      Icons.person_outline,
                                      size: 17,
                                      color: primaryColor,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                workshop.teacherName,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color:
                                      secondaryTextColor,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        workshop.description.trim().isEmpty
                            ? 'Atölye açıklaması eklenmemiş.'
                            : workshop.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          buildInfoBadge(
                            icon: Icons
                                .calendar_view_day_outlined,
                            text: workshop.durationLabel,
                          ),
                          buildInfoBadge(
                            icon: Icons.payments_outlined,
                            text: workshop.formattedPrice,
                          ),
                          buildInfoBadge(
                            icon: Icons.people_outline,
                            text: workshop.capacityLabel,
                          ),
                          if (workshop.category
                              .trim()
                              .isNotEmpty)
                            buildInfoBadge(
                              icon: Icons.category_outlined,
                              text: workshop.category,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: softGreen,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isJoined
                                  ? Icons
                                      .play_circle_outline
                                  : Icons
                                      .arrow_forward_rounded,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isJoined
                                    ? 'İçeriklere devam et'
                                    : 'Atölyeyi incele',
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              color: primaryColor,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoBadge({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImagePlaceholder() {
    return Container(
      color: softGreen,
      alignment: Alignment.center,
      child: const Icon(
        Icons.auto_awesome_mosaic_outlined,
        color: primaryColor,
        size: 52,
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.75),
        ),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: softGreen,
            child: Icon(
              Icons.auto_awesome_mosaic_outlined,
              color: primaryColor,
              size: 36,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aktif atölye bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Öğretmenler yeni bir atölye yayınladığında burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              height: 1.4,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFC85C5C),
            size: 48,
          ),
          const SizedBox(height: 13),
          const Text(
            'Atölyeler yüklenemedi',
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: refreshWorkshops,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
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
    return FutureBuilder<List<WorkshopModel>>(
      future: workshopsFuture,
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return buildErrorState(
            snapshot.error!,
          );
        }

        final workshops = snapshot.data ?? [];

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            buildSectionTitle(
              workshops.length,
            ),
            const SizedBox(height: 15),
            if (workshops.isEmpty)
              buildEmptyState()
            else
              ...workshops.map(
                buildWorkshopCard,
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Atölyeler',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor:
            Colors.white.withOpacity(0.16),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      body: buildBackgroundBody(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: refreshWorkshops,
            color: primaryColor,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),
              children: [
                buildHeader(),
                const SizedBox(height: 24),
                buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}