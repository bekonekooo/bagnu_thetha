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

  Widget buildHeaderCard() {
    final imageUrl = imageUrlController.text.trim();
    final hasImage = imageUrl.isNotEmpty;

    return Container(
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
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                child: hasImage
                    ? null
                    : const Icon(
                        Icons.person,
                        size: 52,
                        color: Colors.deepPurple,
                      ),
              ),
              if (isUploadingImage)
                Container(
                  width: 104,
                  height: 104,
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
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fotoğraf yükledikten sonra değişikliği kaydetmeyi unutma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUploadingImage || isLoading ? null : pickAndUploadImage,
              icon: isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image),
              label: Text(
                isUploadingImage ? 'Yükleniyor...' : 'Galeriden Fotoğraf Seç',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !isLoading && !isUploadingImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeaderCard(),

            const SizedBox(height: 28),

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

            const SizedBox(height: 8),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Gelişmiş: Fotoğraf URL',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}