import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_application_1/core/services/supabase_service.dart';

import '../../data/models/workshop_comment_model.dart';
import '../../data/models/workshop_day_model.dart';
import '../../data/models/workshop_model.dart';
import '../../data/services/workshop_service.dart';

class WorkshopDetailPage extends StatefulWidget {
  final WorkshopModel workshop;
  final bool initiallyJoined;

  const WorkshopDetailPage({
    super.key,
    required this.workshop,
    required this.initiallyJoined,
  });

  @override
  State<WorkshopDetailPage> createState() =>
      _WorkshopDetailPageState();
}

class _WorkshopDetailPageState extends State<WorkshopDetailPage> {
  final WorkshopService workshopService = WorkshopService();

  final TextEditingController commentController =
      TextEditingController();

  static const Color primaryColor = Color(0xFF536B4E);
  static const Color textColor = Color(0xFF2F3A32);
  static const Color secondaryTextColor = Color(0xFF606A61);
  static const Color softGreen = Color(0xFFEEF3EA);
  static const Color borderColor = Color(0xFFD7E1D0);
  static const Color dangerColor = Color(0xFFC85C5C);

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_1.jpg';

  bool isJoined = false;
  bool isLiked = false;

  bool isPageLoading = true;
  bool isJoinProcessing = false;
  bool isLikeProcessing = false;
  bool isCommentSending = false;

  int likeCount = 0;
  int commentCount = 0;
  int studentCount = 0;

  List<WorkshopDayModel> workshopDays = [];
  List<WorkshopCommentModel> comments = [];

  @override
  void initState() {
    super.initState();

    isJoined = widget.initiallyJoined;

    loadPageData();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadPageData() async {
    if (mounted) {
      setState(() {
        isPageLoading = true;
      });
    }

    try {
      final joinedResult =
          await workshopService.hasJoinedWorkshop(
        widget.workshop.id,
      );

      final likedResult =
          await workshopService.fetchIsWorkshopLikedByMe(
        widget.workshop.id,
      );

      final likesResult =
          await workshopService.fetchWorkshopLikeCount(
        widget.workshop.id,
      );

      final commentsResult =
          await workshopService.fetchWorkshopComments(
        widget.workshop.id,
      );

      final studentsResult =
          await workshopService.fetchWorkshopStudentCount(
        widget.workshop.id,
      );

      List<WorkshopDayModel> daysResult = [];

      if (joinedResult) {
        daysResult =
            await workshopService.fetchWorkshopDays(
          widget.workshop.id,
        );
      }

      if (!mounted) return;

      setState(() {
        isJoined = joinedResult;
        isLiked = likedResult;

        likeCount = likesResult;
        comments = commentsResult;
        commentCount = commentsResult.length;
        studentCount = studentsResult;

        workshopDays = daysResult;

        isPageLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isPageLoading = false;
      });

      showMessage(
        'Atölye bilgileri yüklenemedi: $error',
      );
    }
  }

  Future<void> refreshPage() async {
    await loadPageData();
  }

  Future<void> toggleJoin() async {
    if (isJoinProcessing) return;

    setState(() {
      isJoinProcessing = true;
    });

    try {
      if (isJoined) {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Atölyeden ayrıl',
              ),
              content: Text(
                '"${widget.workshop.title}" atölyesinden ayrılmak istiyor musun? Günlük içeriklere erişimin kapanacak.',
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Atölyeden Ayrıl',
                  ),
                ),
              ],
            );
          },
        );

        if (shouldLeave != true) {
          if (mounted) {
            setState(() {
              isJoinProcessing = false;
            });
          }

          return;
        }

        await workshopService.leaveWorkshop(
          widget.workshop.id,
        );

        if (!mounted) return;

        setState(() {
          isJoined = false;
          workshopDays = [];
          studentCount =
              studentCount > 0 ? studentCount - 1 : 0;
          isJoinProcessing = false;
        });

        showMessage(
          'Atölyeden ayrıldın.',
        );

        return;
      }

      await workshopService.joinWorkshop(
        widget.workshop.id,
      );

      final days =
          await workshopService.fetchWorkshopDays(
        widget.workshop.id,
      );

      if (!mounted) return;

      setState(() {
        isJoined = true;
        workshopDays = days;
        studentCount++;
        isJoinProcessing = false;
      });

      showMessage(
        'Atölyeye başarıyla kaydoldun.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isJoinProcessing = false;
      });

      showMessage(
        'İşlem tamamlanamadı: $error',
      );
    }
  }

  Future<void> toggleLike() async {
    if (isLikeProcessing) return;

    setState(() {
      isLikeProcessing = true;
    });

    try {
      final newLikeState =
          await workshopService.toggleWorkshopLike(
        widget.workshop.id,
      );

      if (!mounted) return;

      setState(() {
        isLiked = newLikeState;

        if (newLikeState) {
          likeCount++;
        } else if (likeCount > 0) {
          likeCount--;
        }

        isLikeProcessing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLikeProcessing = false;
      });

      showMessage(
        'Beğeni işlemi tamamlanamadı: $error',
      );
    }
  }

  Future<void> sendComment() async {
    if (isCommentSending) return;

    if (!isJoined) {
      showMessage(
        'Yorum yazmak için atölyeye kayıt olmalısın.',
      );
      return;
    }

    final comment = commentController.text.trim();

    if (comment.isEmpty) {
      showMessage(
        'Yorum boş olamaz.',
      );
      return;
    }

    setState(() {
      isCommentSending = true;
    });

    try {
      await workshopService.addWorkshopComment(
        workshopId: widget.workshop.id,
        commentText: comment,
      );

      final refreshedComments =
          await workshopService.fetchWorkshopComments(
        widget.workshop.id,
      );

      if (!mounted) return;

      commentController.clear();

      setState(() {
        comments = refreshedComments;
        commentCount = refreshedComments.length;
        isCommentSending = false;
      });

      FocusScope.of(context).unfocus();

      showMessage(
        'Yorumun eklendi.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isCommentSending = false;
      });

      showMessage(
        'Yorum eklenemedi: $error',
      );
    }
  }

  Future<void> deleteComment(
    WorkshopCommentModel comment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Yorumu sil',
          ),
          content: const Text(
            'Bu yorumu silmek istediğine emin misin?',
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Sil',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await workshopService.deleteWorkshopComment(
        comment.id,
      );

      if (!mounted) return;

      setState(() {
        comments.removeWhere(
          (item) => item.id == comment.id,
        );

        commentCount = comments.length;
      });

      showMessage(
        'Yorum silindi.',
      );
    } catch (error) {
      showMessage(
        'Yorum silinemedi: $error',
      );
    }
  }

  Future<void> openWorkshopContent(
    WorkshopDayModel day,
  ) async {
    if (!isJoined) {
      showMessage(
        'İçeriği açmak için atölyeye kayıt olmalısın.',
      );
      return;
    }

    final urlText = day.contentUrl.trim();

    if (urlText.isEmpty) {
      showMessage(
        'İçerik bağlantısı bulunamadı.',
      );
      return;
    }

    final uri = Uri.tryParse(urlText);

    if (uri == null) {
      showMessage(
        'İçerik bağlantısı geçersiz.',
      );
      return;
    }

    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) {
      showMessage(
        'Bu içerik açılamadı.',
      );
      return;
    }

    final launchMode = day.isLink
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;

    await launchUrl(
      uri,
      mode: launchMode,
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
            color: Colors.white.withOpacity(0.22),
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
                  Colors.black.withOpacity(0.17),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildCoverSection() {
    final workshop = widget.workshop;
    final hasImage =
        workshop.imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.76),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 26,
            offset: const Offset(0, 12),
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
              top: Radius.circular(29),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 220,
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
            padding: const EdgeInsets.all(19),
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
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    buildJoinedBadge(),
                  ],
                ),
                if (workshop.teacherName
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 14),
                  buildTeacherRow(),
                ],
                const SizedBox(height: 16),
                Text(
                  workshop.description.trim().isEmpty
                      ? 'Bu atölye için açıklama eklenmemiş.'
                      : workshop.description,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 17),
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
                      text: '$studentCount katılımcı',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTeacherRow() {
    final workshop = widget.workshop;
    final hasTeacherImage =
        workshop.teacherImageUrl.trim().isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: softGreen,
          backgroundImage: hasTeacherImage
              ? NetworkImage(
                  workshop.teacherImageUrl,
                )
              : null,
          child: hasTeacherImage
              ? null
              : const Icon(
                  Icons.person_outline,
                  color: primaryColor,
                ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                workshop.teacherName,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (workshop.teacherSpecialty
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  workshop.teacherSpecialty,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildJoinedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isJoined
            ? const Color(0xFFE7F4E8)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isJoined
                ? Icons.check_circle
                : Icons.lock_outline,
            color: isJoined
                ? const Color(0xFF3D7A48)
                : Colors.grey.shade700,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            isJoined ? 'Kayıtlısın' : 'Kayıt Gerekli',
            style: TextStyle(
              color: isJoined
                  ? const Color(0xFF3D7A48)
                  : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.76),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isJoinProcessing
                      ? null
                      : toggleJoin,
                  icon: isJoinProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isJoined
                              ? Icons
                                  .logout_outlined
                              : Icons
                                  .how_to_reg_outlined,
                        ),
                  label: Text(
                    isJoinProcessing
                        ? 'İşleniyor...'
                        : isJoined
                            ? 'Atölyeden Ayrıl'
                            : widget.workshop.price <= 0
                                ? 'Ücretsiz Katıl'
                                : 'Atölyeye Katıl',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJoined
                        ? dangerColor
                        : primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        primaryColor.withOpacity(0.55),
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 58,
                height: 52,
                child: OutlinedButton(
                  onPressed: isLikeProcessing
                      ? null
                      : toggleLike,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isLiked
                        ? dangerColor
                        : primaryColor,
                    side: BorderSide(
                      color: isLiked
                          ? dangerColor
                          : primaryColor,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                  ),
                  child: isLikeProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      : Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              buildSocialCounter(
                icon: isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,
                text: '$likeCount beğeni',
                color:
                    isLiked ? dangerColor : primaryColor,
              ),
              const SizedBox(width: 20),
              buildSocialCounter(
                icon: Icons.chat_bubble_outline,
                text: '$commentCount yorum',
                color: primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildContentsSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        buildSectionTitle(
          icon: Icons.view_day_outlined,
          title: 'Günlük İçerikler',
          subtitle: isJoined
              ? 'Atölyenin günlük çalışmalarını sırayla tamamlayabilirsin.'
              : 'İçerikleri açmak için önce atölyeye kayıt olmalısın.',
        ),
        const SizedBox(height: 14),
        if (!isJoined)
          buildLockedContentBox()
        else if (workshopDays.isEmpty)
          buildEmptyContentBox()
        else
          ...workshopDays.map(
            buildWorkshopDayCard,
          ),
      ],
    );
  }

  Widget buildLockedContentBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.76),
        ),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: softGreen,
            child: Icon(
              Icons.lock_outline,
              color: primaryColor,
              size: 33,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'İçerikler kilitli',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Ses, video ve günlük çalışmalara erişmek için atölyeye katıl.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyContentBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: primaryColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu atölye için henüz günlük içerik bulunamadı.',
              style: TextStyle(
                color: secondaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWorkshopDayCard(
    WorkshopDayModel day,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.76),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: softGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.dayNumber}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${day.dayNumber}. Gün',
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.title,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              buildDayTypeBadge(day),
            ],
          ),
          if (day.description
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              day.description,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          if (day.durationText
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 17,
                  color: primaryColor,
                ),
                const SizedBox(width: 7),
                Text(
                  day.durationText,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                openWorkshopContent(day);
              },
              icon: Icon(
                day.isAudio
                    ? Icons.headphones_outlined
                    : day.isVideo
                        ? Icons
                            .play_circle_outline
                        : Icons.open_in_new,
              ),
              label: Text(
                day.isAudio
                    ? 'Ses Kaydını Aç'
                    : day.isVideo
                        ? 'Videoyu Aç'
                        : 'Video Bağlantısını Aç',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDayTypeBadge(
    WorkshopDayModel day,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
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
            day.isAudio
                ? Icons.headphones_outlined
                : day.isVideo
                    ? Icons.play_circle_outline
                    : Icons.link,
            size: 14,
            color: primaryColor,
          ),
          const SizedBox(width: 5),
          Text(
            day.contentTypeLabel,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCommentsSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        buildSectionTitle(
          icon: Icons.forum_outlined,
          title: 'Yorumlar',
          subtitle: isJoined
              ? 'Atölye deneyimini diğer katılımcılarla paylaş.'
              : 'Yorumları okuyabilirsin. Yorum yazmak için atölyeye katılmalısın.',
        ),
        const SizedBox(height: 14),
        if (isJoined) ...[
          buildCommentInput(),
          const SizedBox(height: 15),
        ] else
          buildCommentLockedMessage(),
        if (!isJoined)
          const SizedBox(height: 15),
        if (comments.isEmpty)
          buildNoCommentsBox()
        else
          ...comments.map(
            buildCommentCard,
          ),
      ],
    );
  }

  Widget buildCommentInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.76),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: commentController,
            enabled: !isCommentSending,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText:
                  'Atölye hakkında yorumunu yaz...',
              filled: true,
              fillColor: softGreen,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCommentSending
                  ? null
                  : sendComment,
              icon: isCommentSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_outlined,
                    ),
              label: Text(
                isCommentSending
                    ? 'Gönderiliyor...'
                    : 'Yorumu Gönder',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCommentLockedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF0D4AA),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Color(0xFF9A621D),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Yorum yazabilmek için bu atölyeye kayıt olmalısın.',
              style: TextStyle(
                color: Color(0xFF9A621D),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNoCommentsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: softGreen,
            child: Icon(
              Icons.chat_bubble_outline,
              color: primaryColor,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Text(
              'Henüz yorum yapılmamış. İlk yorumu sen yazabilirsin.',
              style: TextStyle(
                color: secondaryTextColor,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCommentCard(
    WorkshopCommentModel comment,
  ) {
    final currentUserId =
        supabase.auth.currentUser?.id;

    final isMyComment =
        currentUserId != null &&
            currentUserId == comment.userId;

    final hasImage =
        comment.userImageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.76),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: softGreen,
            backgroundImage: hasImage
                ? NetworkImage(
                    comment.userImageUrl,
                  )
                : null,
            child: hasImage
                ? null
                : const Icon(
                    Icons.person_outline,
                    color: primaryColor,
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName.trim().isEmpty
                            ? 'Kullanıcı'
                            : comment.userName,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isMyComment)
                      IconButton(
                        onPressed: () {
                          deleteComment(comment);
                        },
                        visualDensity:
                            VisualDensity.compact,
                        tooltip: 'Yorumu Sil',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: dangerColor,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment.commentText,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (comment.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    formatCommentDate(
                      comment.createdAt!,
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Icon(
            icon,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget buildSocialCounter({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget buildImagePlaceholder() {
    return Container(
      color: softGreen,
      alignment: Alignment.center,
      child: const Icon(
        Icons.auto_awesome_mosaic_outlined,
        color: primaryColor,
        size: 55,
      ),
    );
  }

  String formatCommentDate(
    DateTime date,
  ) {
    final localDate = date.toLocal();

    final day =
        localDate.day.toString().padLeft(2, '0');

    final month =
        localDate.month.toString().padLeft(2, '0');

    final year = localDate.year.toString();

    final hour =
        localDate.hour.toString().padLeft(2, '0');

    final minute =
        localDate.minute.toString().padLeft(2, '0');

    return '$day.$month.$year • $hour:$minute';
  }

  Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
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
          'Atölye Detayı',
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
      body: buildBackground(
        child: SafeArea(
          child: isPageLoading
              ? buildLoadingState()
              : RefreshIndicator(
                  onRefresh: refreshPage,
                  color: primaryColor,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      32,
                    ),
                    children: [
                      buildCoverSection(),
                      const SizedBox(height: 17),
                      buildActionSection(),
                      const SizedBox(height: 27),
                      buildContentsSection(),
                      const SizedBox(height: 29),
                      buildCommentsSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}