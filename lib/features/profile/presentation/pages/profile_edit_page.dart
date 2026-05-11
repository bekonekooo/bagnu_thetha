import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/profile_service.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileEditPage({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileEditPage> createState() =>
      _ProfileEditPageState();
}

class _ProfileEditPageState
    extends State<ProfileEditPage> {
  final ProfileService profileService = ProfileService();

  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController bioController;
  late TextEditingController imageUrlController;

  bool isLoading = false;

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

  Future<void> saveProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      await profileService.updateMyProfile(
        fullName: fullNameController.text.trim(),
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

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(
              label: 'Ad Soyad',
              controller: fullNameController,
            ),
            buildTextField(
              label: 'Telefon',
              controller: phoneController,
            ),
            buildTextField(
              label: 'Fotoğraf URL',
              controller: imageUrlController,
            ),
            buildTextField(
              label: 'Hakkında',
              controller: bioController,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : saveProfile,
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
                  isLoading
                      ? 'Kaydediliyor...'
                      : 'Kaydet',
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}