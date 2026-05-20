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
          teacher: teacher.toMap(),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.self_improvement,
              color: Colors.deepPurple,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Öğretmen Bul',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sana uygun uzmanı seçerek kolayca seans oluşturabilirsin.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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

  Widget buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Seç',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'İlgilendiğin alana göre öğretmenleri filtreleyebilirsin.',
          style: TextStyle(
            color: Colors.grey,
            height: 1.35,
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
    );
  }

  Widget buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.deepPurple.shade50,
              child: const Icon(
                Icons.search_off,
                color: Colors.deepPurple,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu kategoride öğretmen bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Farklı bir kategori seçerek tekrar deneyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
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
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Öğretmenler yüklenemedi',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: refreshTeachers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Al'),
      ),
      body: FutureBuilder<List<TeacherModel>>(
        future: teachersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return buildErrorState(snapshot.error);
          }

          final teachers = snapshot.data ?? [];
          final filteredTeachers = getFilteredTeachers(teachers);

          return RefreshIndicator(
            onRefresh: refreshTeachers,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                buildHeader(),
                const SizedBox(height: 26),
                buildCategoryFilters(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Öğretmenler',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${filteredTeachers.length} kişi',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (filteredTeachers.isEmpty)
                  buildEmptyState()
                else
                  ...filteredTeachers.map(
                    (teacher) =>TeacherCard(
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
        },
      ),
    );
  }
}