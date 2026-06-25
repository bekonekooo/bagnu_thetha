import 'package:cached_network_image/cached_network_image.dart';
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

  static const String profileBackground =
      'assets/images/backgrounds/home_bg_3.jpg';

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

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

      if (!mounted) return;

      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Profil bilgileri alınamadı: $e');

      if (!mounted) return;

      setState(() {
        errorMessage =
            'Profil bilgilerin alınamadı. Lütfen tekrar dene.';
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
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC85C5C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await signOut();
    }
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Tarih yok';

    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  String cleanValue(String? value, String fallback) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? fallback : clean;
  }

  Widget buildBackgroundBody({
    required Widget child,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            profileBackground,
            fit: BoxFit.cover,
            cacheWidth: 1290,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.16),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.16),
                  Colors.white.withOpacity(0.05),
                  Colors.black.withOpacity(0.18),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildHeaderCard({
    required String fullName,
    required String email,
    required String imageUrl,
  }) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEEF3EA).withOpacity(0.95),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              backgroundImage: hasImage
                  ? CachedNetworkImageProvider(
                      imageUrl,
                      maxWidth: 150,
                    )
                  : null,
              child: hasImage
                  ? null
                  : const Icon(
                      Icons.person_outline,
                      size: 58,
                      color: Color(0xFF536B4E),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F3A32),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF606A61),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA).withOpacity(0.9),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.spa_outlined,
                  color: Color(0xFF536B4E),
                  size: 17,
                ),
                SizedBox(width: 7),
                Text(
                  'BagnuTheta Alanı',
                  style: TextStyle(
                    color: Color(0xFF536B4E),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool muted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEEF3EA).withOpacity(0.95),
            child: Icon(
              icon,
              color: const Color(0xFF536B4E),
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
                    color: Color(0xFF667064),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: muted
                        ? const Color(0xFF8A9188)
                        : const Color(0xFF2F3A32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingState() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: buildBackgroundBody(
        child: Container(
          color: Colors.white.withOpacity(0.18),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF536B4E),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildErrorState() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Profilim',
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
          child: RefreshIndicator(
            onRefresh: getProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(28),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.70),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFC85C5C),
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Profil yüklenemedi',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F3A32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            errorMessage ?? 'Bilinmeyen hata',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF606A61),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: getProfile,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tekrar Dene'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF536B4E),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return buildLoadingState();
    }

    if (errorMessage != null) {
      return buildErrorState();
    }

    final fullName = cleanValue(
      profile?['full_name']?.toString(),
      'İsim eklenmemiş',
    );
    final email = cleanValue(
      profile?['email']?.toString(),
      'E-posta yok',
    );
    final createdAt = formatDate(profile?['created_at']?.toString());

    final imageUrl = profile?['image_url']?.toString() ?? '';
    final phoneRaw = profile?['phone']?.toString() ?? '';
    final bioRaw = profile?['bio']?.toString() ?? '';

    final phone = cleanValue(phoneRaw, 'Telefon eklenmemiş');
    final bio = cleanValue(bioRaw, 'Hakkında bilgisi eklenmemiş');

    final phoneMissing = phoneRaw.trim().isEmpty;
    final bioMissing = bioRaw.trim().isEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Profilim',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.18),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
        actions: [
          IconButton(
            onPressed: getProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: buildBackgroundBody(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: getProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                children: [
                  buildHeaderCard(
                    fullName: fullName,
                    email: email,
                    imageUrl: imageUrl,
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
                    icon: Icons.phone_outlined,
                    title: 'Telefon',
                    value: phone,
                    muted: phoneMissing,
                  ),
                  buildInfoTile(
                    icon: Icons.info_outline,
                    title: 'Hakkında',
                    value: bio,
                    muted: bioMissing,
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
                      onPressed: () async {
                        final result = await context.push(
                          '/profile-edit',
                          extra: profile,
                        );

                        if (result == true) {
                          getProfile();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Profili Düzenle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF536B4E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: confirmSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC85C5C),
                        side: const BorderSide(
                          color: Color(0xFFC85C5C),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
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