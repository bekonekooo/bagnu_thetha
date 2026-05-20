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
  late TextEditingController sessionPriceController;

  bool isActive = true;
  bool isLoading = false;
  bool isUploadingImage = false;

  String currency = 'try';

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.teacher.name);
    specialtyController = TextEditingController(text: widget.teacher.specialty);
    categoryController = TextEditingController(text: widget.teacher.category);
    experienceController = TextEditingController(text: widget.teacher.experience);
    bioController = TextEditingController(text: widget.teacher.bio);
    imageUrlController = TextEditingController(text: widget.teacher.imageUrl);

    sessionPriceController = TextEditingController(
      text: widget.teacher.sessionPrice <= 0
          ? ''
          : widget.teacher.sessionPrice.toStringAsFixed(0),
    );

    isActive = widget.teacher.isActive;
    currency = widget.teacher.currency.isEmpty ? 'try' : widget.teacher.currency;
  }

  @override
  void dispose() {
    nameController.dispose();
    specialtyController.dispose();
    categoryController.dispose();
    experienceController.dispose();
    bioController.dispose();
    imageUrlController.dispose();
    sessionPriceController.dispose();
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

  bool validateForm() {
    final name = nameController.text.trim();
    final priceText = sessionPriceController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İsim alanı boş olamaz.'),
        ),
      );
      return false;
    }

    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seans ücretini girmelisin.'),
        ),
      );
      return false;
    }

    final price = double.tryParse(priceText.replaceAll(',', '.'));

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir seans ücreti gir.'),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> saveProfile() async {
    if (isLoading || isUploadingImage) return;

    if (!validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final sessionPrice = double.parse(
        sessionPriceController.text.trim().replaceAll(',', '.'),
      );

      await teacherService.updateMyTeacherProfile(
        teacherId: widget.teacher.id,
        name: nameController.text.trim(),
        specialty: specialtyController.text.trim(),
        category: categoryController.text.trim(),
        experience: experienceController.text.trim(),
        bio: bioController.text.trim(),
        imageUrl: imageUrlController.text.trim(),
        isActive: isActive,
        sessionPrice: sessionPrice,
        currency: currency,
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
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget buildImagePreview() {
    final imageUrl = imageUrlController.text.trim();

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
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.deepPurple,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          const Text(
            'Öğretmen Profilini Düzenle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bilgilerini ve seans ücretini buradan güncelleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
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
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPriceSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: Colors.deepPurple,
              ),
              SizedBox(width: 8),
              Text(
                'Seans Ücreti',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: sessionPriceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Ücret',
              hintText: 'Örn: 1500',
              prefixIcon: const Icon(Icons.currency_lira),
              suffixText: currency.toUpperCase(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: currency,
            decoration: InputDecoration(
              labelText: 'Para Birimi',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'try',
                child: Text('TRY - Türk Lirası'),
              ),
              DropdownMenuItem(
                value: 'usd',
                child: Text('USD - Dolar'),
              ),
              DropdownMenuItem(
                value: 'eur',
                child: Text('EUR - Euro'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                currency = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildStatusSwitch() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ),
      child: SwitchListTile(
        value: isActive,
        onChanged: (value) {
          setState(() {
            isActive = value;
          });
        },
        title: const Text(
          'Aktif Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isActive
              ? 'Öğrenciler seni öğretmen listesinde görebilir.'
              : 'Profilin öğrencilere kapalı olur.',
        ),
      ),
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
          children: [
            buildImagePreview(),
            const SizedBox(height: 24),

            buildTextField(
              label: 'İsim',
              controller: nameController,
              icon: Icons.person_outline,
            ),
            buildTextField(
              label: 'Uzmanlık',
              controller: specialtyController,
              icon: Icons.auto_awesome_outlined,
            ),
            buildTextField(
              label: 'Kategori',
              controller: categoryController,
              icon: Icons.category_outlined,
              helperText: 'Örn: Bolluk, İlişkiler, Spiritüel, Yaşam',
            ),
            buildTextField(
              label: 'Deneyim',
              controller: experienceController,
              icon: Icons.workspace_premium_outlined,
              helperText: 'Örn: 5 yıl deneyim',
            ),

            buildPriceSection(),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Fotoğraf URL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                buildTextField(
                  label: 'Fotoğraf URL',
                  controller: imageUrlController,
                  icon: Icons.link,
                ),
              ],
            ),

            const SizedBox(height: 10),

            buildTextField(
              label: 'Hakkında',
              controller: bioController,
              maxLines: 5,
              icon: Icons.menu_book_outlined,
            ),

            buildStatusSwitch(),

            const SizedBox(height: 12),

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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}