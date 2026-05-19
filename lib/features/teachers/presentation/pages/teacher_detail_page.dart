import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherDetailPage extends StatelessWidget {
  final Map<String, dynamic> teacher;

  const TeacherDetailPage({
    super.key,
    required this.teacher,
  });

  @override
  Widget build(BuildContext context) {
    final id = teacher['id']?.toString() ?? '';
    final name = teacher['name']?.toString() ?? '';
    final specialty = teacher['specialty']?.toString() ?? '';
    final experience = teacher['experience']?.toString() ?? '';
    final rating = teacher['rating']?.toString() ?? '0';
    final bio = teacher['bio']?.toString() ?? '';
    final category = teacher['category']?.toString() ?? '';
    final imageUrl = teacher['image_url']?.toString() ?? '';
    final isActive = teacher['is_active'] == true;

    final hasImage = imageUrl.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğretmen Detayı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                    child: hasImage
                        ? null
                        : const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.deepPurple,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name.isEmpty ? 'Öğretmen' : name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialty.isEmpty ? 'Uzmanlık bilgisi yok' : specialty,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _HeaderBadge(
                        icon: Icons.category_outlined,
                        text: category.isEmpty ? 'Kategori' : category,
                      ),
                      _HeaderBadge(
                        icon: Icons.workspace_premium_outlined,
                        text: experience.isEmpty ? 'Deneyim' : experience,
                      ),
                      _HeaderBadge(
                        icon: Icons.star,
                        text: rating,
                        iconColor: Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildInfoCard(
              icon: Icons.category_outlined,
              title: 'Kategori',
              value: category.isEmpty ? 'Belirtilmemiş' : category,
            ),
            _buildInfoCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Deneyim',
              value: experience.isEmpty ? 'Belirtilmemiş' : experience,
            ),
            _buildInfoCard(
              icon: Icons.star_outline,
              title: 'Puan',
              value: rating,
            ),
            _buildInfoCard(
              icon: Icons.menu_book_outlined,
              title: 'Hakkında',
              value: bio.isEmpty
                  ? 'Bu öğretmen hakkında henüz açıklama eklenmemiş.'
                  : bio,
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isActive ? Colors.green.shade100 : Colors.red.shade100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isActive
                          ? 'Bu öğretmen şu anda seans kabul ediyor.'
                          : 'Bu öğretmen şu anda aktif değil.',
                      style: TextStyle(
                        color: isActive ? Colors.green.shade800 : Colors.red,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isActive && id.isNotEmpty
                    ? () {
                        context.push(
                          '/booking',
                          extra: {
                            'teacherId': id,
                            'teacherName': name,
                          },
                        );
                      }
                    : null,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Randevu Al'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Öğretmenlere Dön'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.shade50,
            child: Icon(
              icon,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _HeaderBadge({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}