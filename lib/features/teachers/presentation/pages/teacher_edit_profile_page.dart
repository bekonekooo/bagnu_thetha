import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/services/image_upload_service.dart';
import '../../data/models/teacher_model.dart';
import '../../data/services/teacher_service.dart';

class TeacherEditProfilePage extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherEditProfilePage({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherEditProfilePage> createState() => _TeacherEditProfilePageState();
}

class _TeacherEditProfilePageState extends State<TeacherEditProfilePage> {
  final TeacherService teacherService = TeacherService();
  final ImageUploadService imageUploadService = ImageUploadService();

  late TextEditingController nameController;
  late TextEditingController specialtyController;
  late TextEditingController categoryController;
  late TextEditingController experienceController;
  late TextEditingController bioController;
  late TextEditingController imageUrlController;

  bool isActive = true;
  bool isLoading = false;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.teacher.name);
    specialtyController =
        TextEditingController(text: widget.teacher.specialty);
    categoryController =
        TextEditingController(text: widget.teacher.category);
    experienceController =
        TextEditingController(text: widget.teacher.experience);
    bioController = TextEditingController(text: widget.teacher.bio);
    imageUrlController =
        TextEditingController(text: widget.teacher.imageUrl);

    isActive = widget.teacher.isActive;
  }

  @override
  void dispose() {
    nameController.dispose();
    specialtyController.dispose();
    categoryController.dispose();
    experienceController.dispose();
    bioController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> pickAndUploadImage() async {
    setState(() {
      isUploadingImage = true;
    });

    try {
      final uploadedUrl = await imageUploadService.pickAndUploadAvatar(
        folderName: 'teachers',
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
    setState(() {
      isLoading = true;
    });

    try {
      await teacherService.updateMyTeacherProfile(
        teacherId: widget.teacher.id,
        name: nameController.text.trim(),
        specialty: specialtyController.text.trim(),
        category: categoryController.text.trim(),
        experience: experienceController.text.trim(),
        bio: bioController.text.trim(),
        imageUrl: imageUrlController.text.trim(),
        isActive: isActive,
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

  Widget buildImagePreview() {
    final imageUrl = imageUrlController.text.trim();

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  size: 44,
                )
              : null,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isUploadingImage ? null : pickAndUploadImage,
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
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
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
            buildImagePreview(),
            const SizedBox(height: 24),
            buildTextField(
              label: 'İsim',
              controller: nameController,
            ),
            buildTextField(
              label: 'Uzmanlık',
              controller: specialtyController,
            ),
            buildTextField(
              label: 'Kategori',
              controller: categoryController,
            ),
            buildTextField(
              label: 'Deneyim',
              controller: experienceController,
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
            SwitchListTile(
              value: isActive,
              onChanged: (value) {
                setState(() {
                  isActive = value;
                });
              },
              title: const Text('Aktif Profil'),
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
                  isLoading ? 'Kaydediliyor...' : 'Kaydet',
                ),
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