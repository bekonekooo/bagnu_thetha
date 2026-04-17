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

  final List<String> categories = [
    'Tümü',
    'Bolluk',
    'İlişkiler',
    'Spiritüel',
    'Yaşam',
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğretmen Bul'),
      ),
      body: FutureBuilder<List<TeacherModel>>(
        future: teacherService.fetchTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          final teachers = snapshot.data ?? [];
          final filteredTeachers = getFilteredTeachers(teachers);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Öğretmenler',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Uzmanlık alanlarına göre öğretmenleri inceleyebilir ve sana uygun kişiyi seçebilirsin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return TeacherFilterChip(
                        label: category,
                        isSelected: selectedCategory == category,
                        onTap: () => selectCategory(category),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                if (filteredTeachers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        'Bu kategoride öğretmen bulunamadı.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                else
                  ...filteredTeachers.map(
  (teacher) => TeacherCard(
    name: teacher.name,
    specialty: teacher.specialty,
    experience: teacher.experience,
    rating: teacher.rating,
    bio: teacher.bio,
    imageUrl: teacher.imageUrl,
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