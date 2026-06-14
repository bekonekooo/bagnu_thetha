import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/models/meditation_model.dart';
import '../../data/services/meditation_service.dart';

class TeacherMeditationsPage extends StatefulWidget {
  const TeacherMeditationsPage({super.key});

  @override
  State<TeacherMeditationsPage> createState() => _TeacherMeditationsPageState();
}

class _TeacherMeditationsPageState extends State<TeacherMeditationsPage> {
  final MeditationService meditationService = MeditationService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();
  final mediaUrlController = TextEditingController();
  final thumbnailUrlController = TextEditingController();

  late Future<List<MeditationModel>> meditationsFuture;

  String selectedType = 'audio';
  bool isActive = true;
  bool isSaving = false;

  PlatformFile? selectedMediaFile;
  PlatformFile? selectedThumbnailFile;

  final Set<String> selectedCategories = {};

  static const List<String> meditationCategories = [
    'Sabah',
    'Akşam',
    'Şükür',
    'Aşk',
    'Bereket',
    'Sağlık',
  ];

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_7.jpg';

  @override
  void initState() {
    super.initState();
    meditationsFuture = meditationService.fetchMyTeacherMeditations();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    mediaUrlController.dispose();
    thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> reloadMeditations() async {
    setState(() {
      meditationsFuture = meditationService.fetchMyTeacherMeditations();
    });

    await meditationsFuture;
  }

  String typeLabel(String type) {
    switch (type) {
      case 'audio':
        return 'Ses Kaydı';
      case 'video':
        return 'Video Dosyası';
      case 'link':
        return 'Video Linki';
      default:
        return type;
    }
  }

  String mediaHelpText() {
    switch (selectedType) {
      case 'audio':
        return 'MP3, WAV, M4A, AAC veya OGG ses dosyası seç.';
      case 'video':
        return 'MP4, MOV veya WEBM video dosyası seç.';
      case 'link':
        return 'YouTube, Vimeo veya başka bir video bağlantısı gir.';
      default:
        return '';
    }
  }

  List<String> allowedMediaExtensions() {
    if (selectedType == 'audio') {
      return ['mp3', 'wav', 'm4a', 'aac', 'ogg'];
    }

    if (selectedType == 'video') {
      return ['mp4', 'mov', 'webm'];
    }

    return [];
  }

  Future<void> pickMediaFile() async {
    final allowedExtensions = allowedMediaExtensions();

    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      selectedMediaFile = result.files.first;
      mediaUrlController.clear();
    });
  }

  Future<void> pickThumbnailFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      selectedThumbnailFile = result.files.first;
      thumbnailUrlController.clear();
    });
  }

  void clearMediaFile() {
    setState(() {
      selectedMediaFile = null;
    });
  }

  void clearThumbnailFile() {
    setState(() {
      selectedThumbnailFile = null;
    });
  }

  bool isValidUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool isValidDurationText(String value) {
    final text = value.toLowerCase().trim();

    if (text.isEmpty) return true;

    final minuteMatch =
        RegExp(r'^\d+\s*(dk|dakika|min|minute)$').hasMatch(text);
    final secondMatch =
        RegExp(r'^\d+\s*(sn|saniye|sec|second)$').hasMatch(text);
    final plainNumber = RegExp(r'^\d+$').hasMatch(text);

    return minuteMatch || secondMatch || plainNumber;
  }

  String selectedCategoryText() {
    return selectedCategories.join(', ');
  }

  Future<void> createMeditation() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final durationText = durationController.text.trim();
    final linkUrl = mediaUrlController.text.trim();
    final thumbnailUrlInput = thumbnailUrlController.text.trim();
    final category = selectedCategoryText();

    if (title.isEmpty) {
      showMessage('Başlık zorunlu.');
      return;
    }

    if (selectedCategories.isEmpty) {
      showMessage('En az bir kategori seçmelisin.');
      return;
    }

    if (!isValidDurationText(durationText)) {
      showMessage('Süre formatı geçersiz. Örn: 12 dk, 90 sn veya 15');
      return;
    }

    if (selectedType == 'link') {
      if (linkUrl.isEmpty) {
        showMessage('Video linki zorunlu.');
        return;
      }

      if (!isValidUrl(linkUrl)) {
        showMessage('Video linki http veya https ile başlamalı.');
        return;
      }
    } else {
      if (selectedMediaFile == null) {
        showMessage('${typeLabel(selectedType)} için dosya seçmelisin.');
        return;
      }
    }

    if (thumbnailUrlInput.isNotEmpty && !isValidUrl(thumbnailUrlInput)) {
      showMessage('Kapak görseli URL http veya https ile başlamalı.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      String finalMediaUrl = linkUrl;
      String finalThumbnailUrl = thumbnailUrlInput;

      if (selectedType != 'link' && selectedMediaFile != null) {
        finalMediaUrl = await meditationService.uploadMeditationMedia(
          file: selectedMediaFile!,
          type: selectedType,
        );
      }

      if (selectedThumbnailFile != null) {
        finalThumbnailUrl = await meditationService.uploadThumbnail(
          file: selectedThumbnailFile!,
        );
      }

      await meditationService.createMeditation(
        title: title,
        description: description,
        type: selectedType,
        category: category,
        durationText: durationText,
        mediaUrl: finalMediaUrl,
        thumbnailUrl: finalThumbnailUrl,
        isActive: isActive,
      );

      titleController.clear();
      descriptionController.clear();
      durationController.clear();
      mediaUrlController.clear();
      thumbnailUrlController.clear();

      if (!mounted) return;

      setState(() {
        selectedType = 'audio';
        isActive = true;
        isSaving = false;
        selectedMediaFile = null;
        selectedThumbnailFile = null;
        selectedCategories.clear();
      });

      await reloadMeditations();

      showMessage('Meditasyon içeriği eklendi.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('İçerik eklenemedi: $e');
    }
  }

  Future<void> toggleActive(MeditationModel meditation) async {
    try {
      await meditationService.toggleMeditationActive(
        meditationId: meditation.id,
        isActive: !meditation.isActive,
      );

      await reloadMeditations();
    } catch (e) {
      showMessage('Durum güncellenemedi: $e');
    }
  }

  Future<void> deleteMeditation(MeditationModel meditation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İçeriği sil'),
          content: Text('"${meditation.title}" silinsin mi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      await meditationService.deleteMeditation(meditation.id);
      await reloadMeditations();
      showMessage('İçerik silindi.');
    } catch (e) {
      showMessage('İçerik silinemedi: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget buildBackgroundBody({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundImage,
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

  Widget buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: const Color(0xFF536B4E),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white.withOpacity(0.78),
          labelStyle: const TextStyle(
            color: Color(0xFF667064),
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9AA09A),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(
              color: Color(0xFF536B4E),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCategorySelector() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFEEF3EA),
                child: Icon(
                  Icons.category_outlined,
                  color: Color(0xFF536B4E),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Alt Kategoriler',
                  style: TextStyle(
                    color: Color(0xFF2F3A32),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Birden fazla kategori seçebilirsin.',
            style: TextStyle(
              color: Color(0xFF606A61),
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meditationCategories.map((category) {
              final isSelected = selectedCategories.contains(category);

              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: isSaving
                    ? null
                    : (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.remove(category);
                          }
                        });
                      },
                selectedColor: const Color(0xFFD7E1D0),
                checkmarkColor: const Color(0xFF536B4E),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF2F3A32)
                      : const Color(0xFF606A61),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildFileBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required PlatformFile? file,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEEF3EA),
                child: Icon(
                  icon,
                  color: const Color(0xFF536B4E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF2F3A32),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF606A61),
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (file != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    color: Color(0xFF536B4E),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2F3A32),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFFC85C5C),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onPick,
              icon: const Icon(Icons.upload_file),
              label: Text(file == null ? 'Dosya Seç' : 'Dosyayı Değiştir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF536B4E),
                side: const BorderSide(
                  color: Color(0xFF536B4E),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF536B4E),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Meditasyon İçeriği Ekle',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: InputDecoration(
              labelText: 'İçerik türü',
              filled: true,
              fillColor: Colors.white.withOpacity(0.78),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'audio',
                child: Text('Ses Kaydı Yükle'),
              ),
              DropdownMenuItem(
                value: 'video',
                child: Text('Video Dosyası Yükle'),
              ),
              DropdownMenuItem(
                value: 'link',
                child: Text('Video Linki Ekle'),
              ),
            ],
            onChanged: isSaving
                ? null
                : (value) {
                    if (value == null) return;

                    setState(() {
                      selectedType = value;
                      selectedMediaFile = null;
                      mediaUrlController.clear();
                    });
                  },
          ),
          const SizedBox(height: 12),
          buildInput(
            controller: titleController,
            label: 'Başlık',
            hint: 'Örn: Sabah Sakinliği Meditasyonu',
          ),
          buildInput(
            controller: descriptionController,
            label: 'Açıklama',
            hint: 'Kısa açıklama yaz',
            maxLines: 3,
          ),
          buildCategorySelector(),
          buildInput(
            controller: durationController,
            label: 'Süre',
            hint: 'Örn: 12 dk veya 90 sn',
          ),
          if (selectedType == 'link')
            buildInput(
              controller: mediaUrlController,
              label: 'Video Linki',
              hint: 'Örn: https://www.youtube.com/...',
            )
          else
            buildFileBox(
              title: typeLabel(selectedType),
              subtitle: mediaHelpText(),
              icon: selectedType == 'audio'
                  ? Icons.headphones
                  : Icons.video_file_outlined,
              file: selectedMediaFile,
              onPick: pickMediaFile,
              onClear: clearMediaFile,
            ),
          buildFileBox(
            title: 'Kapak Görseli',
            subtitle:
                'Opsiyonel. JPG, PNG veya WEBP görsel seçebilirsin. Seçmezsen URL girebilirsin.',
            icon: Icons.image_outlined,
            file: selectedThumbnailFile,
            onPick: pickThumbnailFile,
            onClear: clearThumbnailFile,
          ),
          if (selectedThumbnailFile == null)
            buildInput(
              controller: thumbnailUrlController,
              label: 'Kapak görseli URL',
              hint: 'Opsiyonel görsel URL',
            ),
          SwitchListTile(
            value: isActive,
            onChanged: isSaving
                ? null
                : (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF536B4E),
            title: const Text(
              'Öğrencilere açık olsun',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F3A32),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : createMeditation,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Yükleniyor...' : 'İçeriği Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536B4E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
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

  Widget buildTeacherItem(MeditationModel meditation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: meditation.isActive
                ? const Color(0xFFEEF3EA)
                : Colors.grey.shade200,
            child: Icon(
              meditation.isAudio
                  ? Icons.headphones
                  : meditation.isVideo
                      ? Icons.play_circle_outline
                      : Icons.link,
              color: meditation.isActive
                  ? const Color(0xFF536B4E)
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meditation.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${typeLabel(meditation.type)} • ${meditation.isActive ? "Aktif" : "Pasif"}',
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (meditation.category.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    meditation.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF536B4E),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => toggleActive(meditation),
            icon: Icon(
              meditation.isActive ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF536B4E),
            ),
          ),
          IconButton(
            onPressed: () => deleteMeditation(meditation),
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFC85C5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMyContentsCard() {
    return FutureBuilder<List<MeditationModel>>(
      future: meditationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF536B4E),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'İçerikler yüklenemedi: ${snapshot.error}',
              style: const TextStyle(
                color: Color(0xFF2F3A32),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final items = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eklediğim İçerikler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F3A32),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Henüz meditasyon içeriği eklemedin.',
                  style: TextStyle(
                    color: Color(0xFF606A61),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ...items.map(buildTeacherItem),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Meditasyon Yönetimi',
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
            onRefresh: reloadMeditations,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                buildFormCard(),
                const SizedBox(height: 24),
                buildMyContentsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}