import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/meditations/data/services/meditation_service.dart';

import 'package:flutter_application_1/features/teachers/data/models/teacher_model.dart';

import 'package:flutter_application_1/features/trainings/data/models/training_model.dart';
import 'package:flutter_application_1/features/trainings/data/services/training_service.dart';

class TeacherDetailPage extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherDetailPage({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  static const Color _backgroundColor = Color(0xFFF8F5EF);
  static const Color _textColor = Color(0xFF2F3A32);
  static const Color _secondaryTextColor = Color(0xFF667068);
  static const Color _primaryColor = Color(0xFF536B4E);
  static const Color _softGreen = Color(0xFFEEF3EA);
  static const Color _borderColor = Color(0xFFDCE4D8);

  final MeditationService _meditationService = MeditationService();
  final TrainingService _trainingService = TrainingService();

  late Future<List<MeditationModel>> _meditationsFuture;
  late Future<List<TrainingModel>> _trainingsFuture;

  @override
  void initState() {
    super.initState();
    _loadTeacherContents();
  }

  void _loadTeacherContents() {
    final teacherUserId = widget.teacher.userId ?? '';

    _meditationsFuture =
        _meditationService.fetchMeditationsByTeacherUserId(
      teacherUserId,
    );

    _trainingsFuture =
        _trainingService.fetchActiveTrainingsByTeacherId(
      widget.teacher.id,
    );
  }

  Future<void> _refreshPage() async {
    setState(() {
      _loadTeacherContents();
    });

    await Future.wait([
      _meditationsFuture,
      _trainingsFuture,
    ]);
  }

  void _goToBooking() {
    final teacher = widget.teacher;

    if (!teacher.isActive) {
      _showMessage(
        'Bu öğretmen şu anda seans kabul etmiyor.',
      );
      return;
    }

    if (teacher.sessionPrice <= 0) {
      _showMessage(
        'Bu öğretmen için seans ücreti henüz belirlenmemiş.',
      );
      return;
    }

    context.push(
      '/booking',
      extra: {
        'teacherId': teacher.id,
        'teacherName': teacher.name,
        'sessionPrice': teacher.sessionPrice,
        'currency': teacher.currency,
      },
    );
  }

  void _openMeditation(MeditationModel meditation) {
    context.push(
      '/meditation-detail',
      extra: meditation,
    );
  }

  void _openTraining(TrainingModel training) {
    context.push(
      '/training-detail',
      extra: {
        'training': training,
        'isJoined': false,
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Öğretmen Profili',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        color: _primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          children: [
            _buildProfileSection(),
            const SizedBox(height: 18),
            _buildBookingButton(),
            const SizedBox(height: 24),
            _buildAboutSection(),
            const SizedBox(height: 28),
            _buildMeditationsSection(),
            const SizedBox(height: 30),
            _buildTrainingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final teacher = widget.teacher;
    final hasImage = teacher.imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: _softGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _borderColor,
                    width: 2,
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(
                            teacher.imageUrl,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : const Icon(
                        Icons.person_outline,
                        size: 46,
                        color: _primaryColor,
                      ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name.trim().isEmpty
                          ? 'Öğretmen'
                          : teacher.name,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      teacher.specialty.trim().isEmpty
                          ? 'Uzmanlık bilgisi eklenmemiş'
                          : teacher.specialty,
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActiveStatus(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProfileStat(
                  icon: Icons.star_rounded,
                  title: 'Puan',
                  value: widget.teacher.rating.toStringAsFixed(1),
                  iconColor: const Color(0xFFD49B2E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildProfileStat(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Deneyim',
                  value: widget.teacher.experience.trim().isEmpty
                      ? 'Belirtilmemiş'
                      : widget.teacher.experience,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildProfileStat(
                  icon: Icons.payments_outlined,
                  title: 'Seans',
                  value: widget.teacher.formattedPrice,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatus() {
    final isActive = widget.teacher.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE7F4E8)
            : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle
                : Icons.cancel,
            size: 16,
            color: isActive
                ? const Color(0xFF3D7A48)
                : const Color(0xFFB54B4B),
          ),
          const SizedBox(width: 6),
          Text(
            isActive
                ? 'Seans kabul ediyor'
                : 'Şu anda aktif değil',
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF3D7A48)
                  : const Color(0xFFB54B4B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = _primaryColor,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 94,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    final canBook = widget.teacher.isActive &&
        widget.teacher.sessionPrice > 0;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: canBook ? _goToBooking : null,
        icon: const Icon(
          Icons.calendar_month_outlined,
        ),
        label: Text(
          canBook
              ? 'Randevu Al • ${widget.teacher.formattedPrice}'
              : 'Şu Anda Randevu Alınamıyor',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade600,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    final teacher = widget.teacher;

    return _buildWhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_outline,
                color: _primaryColor,
              ),
              SizedBox(width: 9),
              Text(
                'Öğretmen Hakkında',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (teacher.category.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _softGreen,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _borderColor,
                ),
              ),
              child: Text(
                teacher.category,
                style: const TextStyle(
                  color: _primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            teacher.bio.trim().isEmpty
                ? 'Bu öğretmen hakkında henüz açıklama eklenmemiş.'
                : teacher.bio,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationsSection() {
    return FutureBuilder<List<MeditationModel>>(
      future: _meditationsFuture,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              title: 'Meditasyonları',
              icon: Icons.self_improvement,
              count: snapshot.data?.length,
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState ==
                ConnectionState.waiting)
              _buildLoadingBox()
            else if (snapshot.hasError)
              _buildErrorBox(
                message: 'Meditasyonlar yüklenemedi.',
              )
            else if ((snapshot.data ?? []).isEmpty)
              _buildEmptyBox(
                icon: Icons.headphones_outlined,
                title: 'Henüz meditasyon yok',
                description:
                    'Bu öğretmen henüz aktif bir meditasyon paylaşmamış.',
              )
            else
              SizedBox(
                height: 232,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(width: 12);
                  },
                  itemBuilder: (context, index) {
                    final meditation = snapshot.data![index];

                    return _buildMeditationCard(
                      meditation,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMeditationCard(
    MeditationModel meditation,
  ) {
    final hasImage =
        meditation.thumbnailUrl.trim().isNotEmpty;

    return InkWell(
      onTap: () => _openMeditation(meditation),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 178,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 126,
                child: hasImage
                    ? Image.network(
                        meditation.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _buildMediaPlaceholder(
                            Icons.self_improvement,
                          );
                        },
                      )
                    : _buildMediaPlaceholder(
                        Icons.self_improvement,
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          meditation.isVideo
                              ? Icons.play_circle_outline
                              : Icons.headphones_outlined,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            meditation.durationText
                                    .trim()
                                    .isEmpty
                                ? meditation.typeLabel
                                : meditation.durationText,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                                  _secondaryTextColor,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingsSection() {
    return FutureBuilder<List<TrainingModel>>(
      future: _trainingsFuture,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              title: 'Eğitimleri',
              icon: Icons.school_outlined,
              count: snapshot.data?.length,
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState ==
                ConnectionState.waiting)
              _buildLoadingBox()
            else if (snapshot.hasError)
              _buildErrorBox(
                message: 'Eğitimler yüklenemedi.',
              )
            else if ((snapshot.data ?? []).isEmpty)
              _buildEmptyBox(
                icon: Icons.school_outlined,
                title: 'Henüz eğitim yok',
                description:
                    'Bu öğretmen henüz aktif bir eğitim paylaşmamış.',
              )
            else
              ...snapshot.data!.map(
                _buildTrainingCard,
              ),
          ],
        );
      },
    );
  }

  Widget _buildTrainingCard(
    TrainingModel training,
  ) {
    final hasImage = training.imageUrl.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openTraining(training),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: hasImage
                      ? Image.network(
                          training.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _buildMediaPlaceholder(
                              Icons.school_outlined,
                            );
                          },
                        )
                      : _buildMediaPlaceholder(
                          Icons.school_outlined,
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      training.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          training.firstDateText,
                          style: const TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            training.locationText.trim().isEmpty
                                ? training.formattedLocationType
                                : training.locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    training.formattedPrice,
                    style: const TextStyle(
                      color: _primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _secondaryTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    int? count,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _softGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Icon(
            icon,
            color: _primaryColor,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _softGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$count içerik',
              style: const TextStyle(
                color: _primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWhiteSection({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMediaPlaceholder(
    IconData icon,
  ) {
    return Container(
      color: _softGreen,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: _primaryColor,
        size: 36,
      ),
    );
  }

  Widget _buildLoadingBox() {
    return Container(
      width: double.infinity,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: const CircularProgressIndicator(
        color: _primaryColor,
      ),
    );
  }

  Widget _buildErrorBox({
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF2CCCC),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFB54B4B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8E3D3D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: _softGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}