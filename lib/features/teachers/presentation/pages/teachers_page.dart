import 'package:flutter/material.dart';

import '../../data/models/teacher_model.dart';
import '../../data/services/teacher_service.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_filter_chip.dart';
import 'teacher_detail_page.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  String selectedCategory = 'Tümü';

  final teacherService = TeacherService();

  late Future<List<TeacherModel>> teachersFuture;

  static const String teachersBackground =
      'assets/images/backgrounds/home_bg_4.jpg';

  final List<String> categories = [
    'Tümü',
    'Bolluk',
    'İlişkiler',
    'Spiritüel',
    'Yaşam',
  ];

  @override
  void initState() {
    super.initState();
    teachersFuture = teacherService.fetchTeachers();
  }

  Future<void> refreshTeachers() async {
    setState(() {
      teachersFuture = teacherService.fetchTeachers();
    });

    await teachersFuture;
  }

  List<TeacherModel> getFilteredTeachers(List<TeacherModel> teachers) {
    if (selectedCategory == 'Tümü') {
      return teachers;
    }

    return teachers
        .where((teacher) => teacher.category == selectedCategory)
        .toList();
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

void goToTeacherDetail(TeacherModel teacher) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TeacherDetailPage(
        teacher: teacher,
      ),
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
            teachersBackground,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.04),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
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
        color: Colors.white.withOpacity(0.54),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA).withOpacity(0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: const Icon(
              Icons.self_improvement,
              color: Color(0xFF536B4E),
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Öğretmen Bul',
                  style: TextStyle(
                    color: Color(0xFF2F3A32),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Sana uygun uzmanı seçerek kolayca seans oluşturabilirsin.',
                  style: TextStyle(
                    color: Color(0xFF606A61),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategoryFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.54),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Seç',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F3A32),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'İlgilendiğin alana göre öğretmenleri filtreleyebilirsin.',
            style: TextStyle(
              color: Color(0xFF606A61),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: categories.map((category) {
              return TeacherFilterChip(
                label: category,
                isSelected: selectedCategory == category,
                onTap: () => selectCategory(category),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildTeachersTitle(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.54),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.42),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Öğretmenler',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F3A32),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA).withOpacity(0.90),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: Text(
              '$count kişi',
              style: const TextStyle(
                color: Color(0xFF536B4E),
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.56),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFEEF3EA).withOpacity(0.95),
              child: const Icon(
                Icons.search_off,
                color: Color(0xFF536B4E),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu kategoride öğretmen bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F3A32),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Farklı bir kategori seçerek tekrar deneyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF606A61),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF536B4E),
      ),
    );
  }

  Widget buildErrorState(Object? error) {
    return RefreshIndicator(
      onRefresh: refreshTeachers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.58),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFC85C5C),
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Öğretmenler yüklenemedi',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F3A32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF606A61),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: refreshTeachers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF536B4E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTeachersList(List<TeacherModel> filteredTeachers) {
    return RefreshIndicator(
      onRefresh: refreshTeachers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          buildHeader(),

          const SizedBox(height: 22),

          buildCategoryFilters(),

          const SizedBox(height: 22),

          buildTeachersTitle(filteredTeachers.length),

          const SizedBox(height: 14),

          if (filteredTeachers.isEmpty)
            buildEmptyState()
          else
            ...filteredTeachers.map(
              (teacher) => TeacherCard(
                name: teacher.name,
                specialty: teacher.specialty,
                category: teacher.category,
                experience: teacher.experience,
                rating: teacher.rating,
                bio: teacher.bio,
                imageUrl: teacher.imageUrl,
                sessionPrice: teacher.sessionPrice,
                currency: teacher.currency,
                onTap: () => goToTeacherDetail(teacher),
              ),
            ),
        ],
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
          'Randevu Al',
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
          child: FutureBuilder<List<TeacherModel>>(
            future: teachersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return buildLoadingState();
              }

              if (snapshot.hasError) {
                return buildErrorState(snapshot.error);
              }

              final teachers = snapshot.data ?? [];
              final filteredTeachers = getFilteredTeachers(teachers);

              return buildTeachersList(filteredTeachers);
            },
          ),
        ),
      ),
    );
  }
}