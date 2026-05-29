import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/services/image_upload_service.dart';
import '../../data/services/profile_service.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileEditPage({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final ProfileService profileService = ProfileService();
  final ImageUploadService imageUploadService = ImageUploadService();

  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController bioController;
  late TextEditingController imageUrlController;

  bool isLoading = false;
  bool isUploadingImage = false;

  static const String profileBackground =
      'assets/images/backgrounds/home_bg_3.jpg';

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: widget.profile['full_name'] ?? '',
    );

    phoneController = TextEditingController(
      text: widget.profile['phone'] ?? '',
    );

    bioController = TextEditingController(
      text: widget.profile['bio'] ?? '',
    );

    imageUrlController = TextEditingController(
      text: widget.profile['image_url'] ?? '',
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> pickAndUploadImage() async {
    if (isUploadingImage || isLoading) return;

    setState(() {
      isUploadingImage = true;
    });

    try {
      final uploadedUrl = await imageUploadService.pickAndUploadAvatar(
        folderName: 'profiles',
      );

      if (!mounted) return;

      if (uploadedUrl == null) {
        return;
      }

      setState(() {
        imageUrlController.text = uploadedUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf yüklendi. Kaydetmeyi unutma.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf yüklenemedi: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isUploadingImage = false;
      });
    }
  }

  Future<void> saveProfile() async {
    if (isLoading || isUploadingImage) return;

    final fullName = fullNameController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad Soyad boş bırakılamaz'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await profileService.updateMyProfile(
        fullName: fullName,
        phone: phoneController.text.trim(),
        bio: bioController.text.trim(),
        imageUrl: imageUrlController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil güncellendi'),
        ),
      );

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme başarısız: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
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

  Widget buildHeaderCard() {
    final imageUrl = imageUrlController.text.trim();
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
          Stack(
            alignment: Alignment.center,
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
                  backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                  child: hasImage
                      ? null
                      : const Icon(
                          Icons.person_outline,
                          size: 58,
                          color: Color(0xFF536B4E),
                        ),
                ),
              ),
              if (isUploadingImage)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Profil Fotoğrafı',
            style: TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fotoğraf yükledikten sonra değişikliği kaydetmeyi unutma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF606A61),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  isUploadingImage || isLoading ? null : pickAndUploadImage,
              icon: isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(
                isUploadingImage ? 'Yükleniyor...' : 'Galeriden Fotoğraf Seç',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF536B4E),
                side: const BorderSide(
                  color: Color(0xFF536B4E),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: !isLoading,
        cursorColor: const Color(0xFF536B4E),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: const TextStyle(
            color: Color(0xFF667064),
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9AA09A),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.76),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFF536B4E),
              width: 1.4,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.50),
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(24),
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA).withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: const Icon(
              Icons.edit_note_outlined,
              color: Color(0xFF536B4E),
              size: 28,
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAdvancedPhotoUrlTile() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          iconColor: const Color(0xFF536B4E),
          collapsedIconColor: const Color(0xFF536B4E),
          title: const Text(
            'Gelişmiş: Fotoğraf URL',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F3A32),
            ),
          ),
          subtitle: const Text(
            'Gerekirse bağlantıyı manuel düzenleyebilirsin.',
            style: TextStyle(
              color: Color(0xFF606A61),
              fontSize: 12.5,
            ),
          ),
          children: [
            buildTextField(
              label: 'Fotoğraf URL',
              controller: imageUrlController,
              hintText: 'Fotoğraf bağlantısı',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !isLoading && !isUploadingImage;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Profili Düzenle',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeaderCard(),

                const SizedBox(height: 24),

                buildSectionTitle(
                  'Kişisel Bilgiler',
                  'Profilinde görünecek bilgileri buradan güncelleyebilirsin.',
                ),

                const SizedBox(height: 16),

                buildTextField(
                  label: 'Ad Soyad',
                  controller: fullNameController,
                  hintText: 'Adını ve soyadını yaz',
                ),
                buildTextField(
                  label: 'Telefon',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: '+90 5xx xxx xx xx',
                ),
                buildTextField(
                  label: 'Hakkında',
                  controller: bioController,
                  maxLines: 5,
                  hintText: 'Kendin hakkında kısa bir bilgi yazabilirsin...',
                ),

                buildAdvancedPhotoUrlTile(),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canSave ? saveProfile : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      isLoading ? 'Kaydediliyor...' : 'Kaydet',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF536B4E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}