import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/trainings/data/models/training_model.dart';
import 'package:flutter_application_1/features/trainings/data/services/training_service.dart';

class TrainingDetailPage extends StatefulWidget {
  final TrainingModel training;
  final bool initiallyJoined;

  const TrainingDetailPage({
    super.key,
    required this.training,
    required this.initiallyJoined,
  });

  @override
  State<TrainingDetailPage> createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage> {
  final TrainingService trainingService = TrainingService();

  late bool isJoined;
  bool isLoading = false;

  static const String pageBackground =
      'assets/images/backgrounds/home_bg_5.jpg';

  @override
  void initState() {
    super.initState();
    isJoined = widget.initiallyJoined;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> joinOrLeaveTraining() async {
    if (widget.training.isCompleted) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isJoined) {
        await trainingService.leaveTraining(widget.training.id);

        if (!mounted) return;

        setState(() {
          isJoined = false;
          isLoading = false;
        });

        showMessage('Katılımın iptal edildi.');
      } else {
        await trainingService.joinTraining(widget.training.id);

        if (!mounted) return;

        setState(() {
          isJoined = true;
          isLoading = false;
        });

        showMessage('Eğitime katıldın.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('İşlem yapılamadı: $e');
    }
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
                  Colors.black.withOpacity(0.22),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildImageFallback() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Icon(
          Icons.school_outlined,
          color: Color(0xFF536B4E),
          size: 58,
        ),
      ),
    );
  }

  Widget buildCoverImage() {
    final training = widget.training;

    if (training.imageUrl.trim().isEmpty) {
      return buildImageFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.network(
        training.imageUrl,
        width: double.infinity,
        height: 230,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return buildImageFallback();
        },
      ),
    );
  }

  Widget buildTag(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 15,
              color: const Color(0xFF536B4E),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF536B4E),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }

  Widget buildTeacherInfo() {
    final training = widget.training;

    if (training.teacherName.trim().isEmpty) {
      return const Text(
        'Eğitmen bilgisi belirtilmemiş.',
        style: TextStyle(
          color: Color(0xFF606A61),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFEEF3EA),
          backgroundImage: training.teacherImageUrl.isNotEmpty
              ? NetworkImage(training.teacherImageUrl)
              : null,
          child: training.teacherImageUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  color: Color(0xFF536B4E),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                training.teacherName,
                style: const TextStyle(
                  color: Color(0xFF2F3A32),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              if (training.teacherSpecialty.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  training.teacherSpecialty,
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSessionsList() {
    final training = widget.training;

    if (training.sessions.isEmpty) {
      return const Text(
        'Eğitim günleri henüz belirtilmemiş.',
        style: TextStyle(
          color: Color(0xFF606A61),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: training.sessions.map((session) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3EA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Color(0xFF536B4E),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${session.formattedDate} / ${session.formattedTimeRange}',
                  style: const TextStyle(
                    color: Color(0xFF2F3A32),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildJoinButton() {
    final training = widget.training;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed:
              training.isCompleted || isLoading ? null : joinOrLeaveTraining,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  training.isCompleted
                      ? Icons.lock_outline
                      : isJoined
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                ),
          label: Text(
            training.isCompleted
                ? 'Eğitim Bitmiş'
                : isLoading
                    ? 'İşleniyor...'
                    : isJoined
                        ? 'Katıldın - İptal Et'
                        : 'Eğitime Katıl',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isJoined ? Colors.grey.shade700 : const Color(0xFF536B4E),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.training;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Eğitim Detayı',
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
      bottomNavigationBar: buildJoinButton(),
      body: buildBackgroundBody(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              buildCoverImage(),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.72),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        buildTag(
                          training.statusLabel,
                          icon: Icons.timeline,
                        ),
                        buildTag(
                          training.formattedPrice,
                          icon: Icons.payments_outlined,
                        ),
                        buildTag(
                          training.formattedLocationType,
                          icon: training.locationType == 'online'
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                        ),
                        if (training.category.trim().isNotEmpty)
                          buildTag(
                            training.category,
                            icon: Icons.category_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      training.title,
                      style: const TextStyle(
                        color: Color(0xFF2F3A32),
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'İlk gün: ${training.firstDateText}',
                      style: const TextStyle(
                        color: Color(0xFF536B4E),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              buildInfoCard(
                title: 'Eğitmen',
                child: buildTeacherInfo(),
              ),
              buildInfoCard(
                title: 'Eğitim Açıklaması',
                child: Text(
                  training.description.trim().isEmpty
                      ? 'Açıklama belirtilmemiş.'
                      : training.description,
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              buildInfoCard(
                title: 'Gün ve Saatler',
                child: buildSessionsList(),
              ),
              buildInfoCard(
                title: 'Konum / Bağlantı',
                child: Text(
                  training.locationText.trim().isEmpty
                      ? 'Konum bilgisi belirtilmemiş.'
                      : training.locationText,
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (training.capacity != null)
                buildInfoCard(
                  title: 'Kontenjan',
                  child: Text(
                    '${training.capacity} kişi',
                    style: const TextStyle(
                      color: Color(0xFF606A61),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}