import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/notifications/data/presentation/widgets/notification_badge_button.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';

import '../../data/models/teacher_model.dart';
import '../../data/services/teacher_service.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final teacherService = TeacherService();

  bool isLoading = true;
  TeacherModel? teacher;

  static const String dashboardBackground =
      'assets/images/backgrounds/home_bg_4.jpg';

  @override
  void initState() {
    super.initState();
    loadTeacher();
  }

  Future<void> loadTeacher() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await teacherService.fetchMyTeacherProfile();

      if (!mounted) return;

      setState(() {
        teacher = response;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğretmen bilgisi yüklenemedi: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    context.go('/login');
  }

  Future<void> confirmSignOut() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Çıkış yap'),
          content: const Text('Hesabınızdan çıkış yapmak istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await signOut();
    }
  }

  Widget buildBackgroundBody({
    required Widget child,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            dashboardBackground,
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

  Widget dashboardButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.76),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.70),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3EA).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD7E1D0),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF536B4E),
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F3A32),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF606A61),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Color(0xFF536B4E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTeacherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFEEF3EA),
            backgroundImage:
                teacher!.imageUrl.isNotEmpty ? NetworkImage(teacher!.imageUrl) : null,
            child: teacher!.imageUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Color(0xFF536B4E),
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher!.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  teacher!.specialty,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF606A61),
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

  Widget buildNoTeacherProfile() {
    return buildBackgroundBody(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.80),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 56,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu hesaba bağlı öğretmen profili bulunamadı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2F3A32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Supabase teachers tablosunda bu kullanıcının user_id alanını bağlaman gerekiyor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF606A61),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loadTeacher,
                    child: const Text('Tekrar Dene'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: confirmSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                  ),
                ],
              ),
            ),
          ),
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
          'Öğretmen Paneli',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          const NotificationBadgeButton(),
          IconButton(
            onPressed: confirmSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            color: const Color(0xFF2F3A32),
          ),
        ],
        backgroundColor: Colors.white.withOpacity(0.18),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
      ),
      body: isLoading
          ? buildBackgroundBody(
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF536B4E),
                ),
              ),
            )
          : teacher == null
              ? buildNoTeacherProfile()
              : buildBackgroundBody(
                  child: SafeArea(
                    child: RefreshIndicator(
                      onRefresh: loadTeacher,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildTeacherCard(),
                            const SizedBox(height: 24),
                            dashboardButton(
                              icon: Icons.event_note,
                              label: 'Seanslarımı Gör',
                              subtitle:
                                  'Yaklaşan, tamamlanan ve iptal edilen seanslarını takip et.',
                              onPressed: () {
                                context.push('/teacher-sessions');
                              },
                            ),
                            dashboardButton(
                              icon: Icons.schedule,
                              label: 'Uygunluklarımı Yönet',
                              subtitle:
                                  'Öğrencilerin randevu alabileceği gün ve saatleri düzenle.',
                              onPressed: () {
                                context.push(
                                  '/teacher-availability',
                                  extra: {
                                    'teacherId': teacher!.id,
                                    'teacherName': teacher!.name,
                                  },
                                );
                              },
                            ),
                            dashboardButton(
                              icon: Icons.self_improvement,
                              label: 'Meditasyon Yönetimi',
                              subtitle:
                                  'Ses, video veya bağlantı olarak meditasyon içerikleri ekle.',
                              onPressed: () {
                                context.push('/teacher-meditations');
                              },
                            ),
                            dashboardButton(
                              icon: Icons.school_outlined,
                              label: 'Eğitim Yönetimi',
                              subtitle:
                                  'Tek günlük veya çok günlü eğitim programları oluştur.',
                              onPressed: () {
                                context.push('/teacher-trainings');
                              },
                            ),
                            dashboardButton(
                              icon: Icons.edit,
                              label: 'Profilimi Düzenle',
                              subtitle:
                                  'Öğretmen profilindeki bilgileri ve görselini güncelle.',
                              onPressed: () async {
                                final result = await context.push(
                                  '/teacher-edit-profile',
                                  extra: teacher,
                                );

                                if (result == true) {
                                  loadTeacher();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}