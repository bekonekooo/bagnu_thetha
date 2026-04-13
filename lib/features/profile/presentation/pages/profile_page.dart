import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          errorMessage = 'Kullanıcı bulunamadı.';
          isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Profil bilgileri alınamadı: $e';
        isLoading = false;
      });
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();

    if (mounted) {
      context.go('/login');
    }
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Tarih yok';

    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  Widget buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profilim'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final fullName = profile?['full_name'] ?? 'İsim yok';
    final email = profile?['email'] ?? 'Email yok';
    final createdAt = formatDate(profile?['created_at']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    child: Icon(Icons.person, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            buildInfoTile(
              icon: Icons.badge_outlined,
              title: 'Ad Soyad',
              value: fullName,
            ),
            buildInfoTile(
              icon: Icons.email_outlined,
              title: 'E-posta',
              value: email,
            ),
            buildInfoTile(
              icon: Icons.calendar_today_outlined,
              title: 'Kayıt Tarihi',
              value: createdAt,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}