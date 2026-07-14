import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/workshop_model.dart';
import '../../data/services/workshop_service.dart';

class TeacherWorkshopsPage extends StatefulWidget {
  const TeacherWorkshopsPage({super.key});

  @override
  State<TeacherWorkshopsPage> createState() =>
      _TeacherWorkshopsPageState();
}

class _TeacherWorkshopsPageState
    extends State<TeacherWorkshopsPage> {
  final WorkshopService workshopService =
      WorkshopService();

  late Future<List<WorkshopModel>>
      workshopsFuture;

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_7.jpg';

  static const Color primaryColor =
      Color(0xFF536B4E);

  static const Color textColor =
      Color(0xFF2F3A32);

  static const Color secondaryTextColor =
      Color(0xFF606A61);

  static const Color softGreen =
      Color(0xFFEEF3EA);

  @override
  void initState() {
    super.initState();

    workshopsFuture =
        workshopService.fetchMyTeacherWorkshops();
  }

  Future<void> reloadWorkshops() async {
    setState(() {
      workshopsFuture =
          workshopService.fetchMyTeacherWorkshops();
    });

    await workshopsFuture;
  }

  Future<void> openCreateWorkshop() async {
    final result = await context.push(
      '/create-workshop',
    );

    if (result == true) {
      await reloadWorkshops();
    }
  }

  Future<void> toggleWorkshopActive(
    WorkshopModel workshop,
  ) async {
    final newValue = !workshop.isActive;

    if (newValue &&
        workshop.days.length !=
            workshop.durationDays) {
      showMessage(
        'Atölyeyi aktif etmek için tüm günlerin içerikleri eksiksiz olmalı.',
      );
      return;
    }

    try {
      await workshopService.toggleWorkshopActive(
        workshopId: workshop.id,
        isActive: newValue,
      );

      await reloadWorkshops();

      showMessage(
        newValue
            ? 'Atölye öğrenciler için aktif edildi.'
            : 'Atölye pasif hale getirildi.',
      );
    } catch (error) {
      showMessage(
        'Atölye durumu güncellenemedi: $error',
      );
    }
  }

  Future<void> deleteWorkshop(
    WorkshopModel workshop,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Atölyeyi sil',
          ),
          content: Text(
            '"${workshop.title}" atölyesini ve tüm günlük içeriklerini silmek istiyor musun?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Vazgeç',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'Sil',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFC85C5C),
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    try {
      await workshopService.deleteWorkshop(
        workshop.id,
      );

      await reloadWorkshops();

      showMessage(
        'Atölye silindi.',
      );
    } catch (error) {
      showMessage(
        'Atölye silinemedi: $error',
      );
    }
  }

  void showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
            color: Colors.white.withOpacity(
              0.18,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(
                    0.18,
                  ),
                  Colors.white.withOpacity(
                    0.05,
                  ),
                  Colors.black.withOpacity(
                    0.20,
                  ),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.78,
        ),
        borderRadius: BorderRadius.circular(
          28,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(
            0.72,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.08,
            ),
            blurRadius: 24,
            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius:
                  BorderRadius.circular(
                19,
              ),
              border: Border.all(
                color:
                    const Color(0xFFD7E1D0),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_mosaic_outlined,
              color: primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(
            width: 15,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Atölye Yönetimi',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Text(
                  'Kayıtlı ses, video ve bağlantılardan oluşan çok günlük atölyeler oluştur.',
                  style: TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: openCreateWorkshop,
        icon: const Icon(
          Icons.add_circle_outline,
        ),
        label: const Text(
          'Yeni Atölye Oluştur',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildWorkshopCard(
    WorkshopModel workshop,
  ) {
    final hasImage =
        workshop.imageUrl.trim().isNotEmpty;

    final contentCount =
        workshop.days.length;

    final isComplete =
        contentCount ==
            workshop.durationDays;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.80,
        ),
        borderRadius: BorderRadius.circular(
          26,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(
            0.72,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.07,
            ),
            blurRadius: 22,
            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(
                25,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 170,
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
          Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        workshop.title,
                        style:
                            const TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    buildStatusBadge(
                      workshop,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  workshop.description
                          .trim()
                          .isEmpty
                      ? 'Açıklama eklenmemiş.'
                      : workshop.description,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        secondaryTextColor,
                    height: 1.45,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    buildInfoBadge(
                      icon:
                          Icons.calendar_view_day_outlined,
                      text:
                          workshop.durationLabel,
                    ),
                    buildInfoBadge(
                      icon:
                          Icons.library_music_outlined,
                      text:
                          '$contentCount/${workshop.durationDays} içerik',
                      success: isComplete,
                    ),
                    buildInfoBadge(
                      icon:
                          Icons.payments_outlined,
                      text:
                          workshop.formattedPrice,
                    ),
                    buildInfoBadge(
                      icon:
                          Icons.people_outline,
                      text:
                          workshop.capacityLabel,
                    ),
                    if (workshop
                        .category
                        .trim()
                        .isNotEmpty)
                      buildInfoBadge(
                        icon:
                            Icons.category_outlined,
                        text:
                            workshop.category,
                      ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    13,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(
                            0xFFE7F4E8,
                          )
                        : const Color(
                            0xFFFFF3E5,
                          ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isComplete
                            ? Icons
                                .check_circle_outline
                            : Icons
                                .warning_amber_rounded,
                        color: isComplete
                            ? const Color(
                                0xFF3D7A48,
                              )
                            : const Color(
                                0xFFB87824,
                              ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          isComplete
                              ? 'Tüm günlük içerikler hazır.'
                              : 'Bazı günlük içerikler eksik.',
                          style: TextStyle(
                            color: isComplete
                                ? const Color(
                                    0xFF3D7A48,
                                  )
                                : const Color(
                                    0xFF9A621D,
                                  ),
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          toggleWorkshopActive(
                            workshop,
                          );
                        },
                        icon: Icon(
                          workshop.isActive
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                        ),
                        label: Text(
                          workshop.isActive
                              ? 'Pasif Yap'
                              : 'Aktif Et',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              primaryColor,
                          side:
                              const BorderSide(
                            color:
                                primaryColor,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          deleteWorkshop(
                            workshop,
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                        label: const Text(
                          'Sil',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(
                            0xFFC85C5C,
                          ),
                          side:
                              const BorderSide(
                            color:
                                Color(
                              0xFFC85C5C,
                            ),
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
        size: 48,
      ),
    );
  }

  Widget buildStatusBadge(
    WorkshopModel workshop,
  ) {
    final isActive =
        workshop.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE7F4E8)
            : Colors.grey.shade200,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle
                : Icons.edit_note_outlined,
            size: 15,
            color: isActive
                ? const Color(
                    0xFF3D7A48,
                  )
                : Colors.grey.shade700,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            isActive
                ? 'Aktif'
                : 'Taslak',
            style: TextStyle(
              color: isActive
                  ? const Color(
                      0xFF3D7A48,
                    )
                  : Colors.grey.shade700,
              fontSize: 11,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoBadge({
    required IconData icon,
    required String text,
    bool success = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: success
            ? const Color(0xFFE7F4E8)
            : softGreen,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        border: Border.all(
          color: success
              ? const Color(
                  0xFFC8E2CB,
                )
              : const Color(
                  0xFFD7E1D0,
                ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: success
                ? const Color(
                    0xFF3D7A48,
                  )
                : primaryColor,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            text,
            style: TextStyle(
              color: success
                  ? const Color(
                      0xFF3D7A48,
                    )
                  : primaryColor,
              fontSize: 11.5,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.80,
        ),
        borderRadius: BorderRadius.circular(
          28,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(
            0.72,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration:
                const BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_mosaic_outlined,
              color: primaryColor,
              size: 38,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          const Text(
            'Henüz atölye oluşturmadın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Ses, video veya bağlantılardan oluşan 1–20 günlük bir atölye oluşturabilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              height: 1.4,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  openCreateWorkshop,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'İlk Atölyeyi Oluştur',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.82,
        ),
        borderRadius: BorderRadius.circular(
          26,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFC85C5C),
            size: 48,
          ),
          const SizedBox(
            height: 13,
          ),
          const Text(
            'Atölyeler yüklenemedi',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton.icon(
            onPressed: reloadWorkshops,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Tekrar Dene',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWorkshopList() {
    return FutureBuilder<
        List<WorkshopModel>>(
      future: workshopsFuture,
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(
              32,
            ),
            child: Center(
              child:
                  CircularProgressIndicator(
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

        final workshops =
            snapshot.data ?? [];

        if (workshops.isEmpty) {
          return buildEmptyState();
        }

        return Column(
          children: workshops
              .map(
                buildWorkshopCard,
              )
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Atölye Yönetimi',
          style: TextStyle(
            color: textColor,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        backgroundColor:
            Colors.white.withOpacity(
          0.18,
        ),
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,
        foregroundColor:
            textColor,
      ),
      body: buildBackgroundBody(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: reloadWorkshops,
            color: primaryColor,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),
              children: [
                buildHeaderCard(),
                const SizedBox(
                  height: 18,
                ),
                buildCreateButton(),
                const SizedBox(
                  height: 24,
                ),
                buildWorkshopList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}