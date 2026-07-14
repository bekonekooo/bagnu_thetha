import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/services/workshop_service.dart';

class CreateWorkshopPage extends StatefulWidget {
  const CreateWorkshopPage({super.key});

  @override
  State<CreateWorkshopPage> createState() => _CreateWorkshopPageState();
}

class _CreateWorkshopPageState extends State<CreateWorkshopPage> {
  final WorkshopService workshopService = WorkshopService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController(text: '0');
  final capacityController = TextEditingController();
  final coverUrlController = TextEditingController();

  int durationDays = 1;
  String currency = 'try';

  bool isSaving = false;

  PlatformFile? selectedCoverFile;

  final List<_WorkshopDayDraft> dayDrafts = [];

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_7.jpg';

  static const Color primaryColor = Color(0xFF536B4E);
  static const Color textColor = Color(0xFF2F3A32);
  static const Color secondaryTextColor = Color(0xFF606A61);
  static const Color softGreen = Color(0xFFEEF3EA);

  @override
  void initState() {
    super.initState();
    _updateDayDrafts(1);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
    capacityController.dispose();
    coverUrlController.dispose();

    for (final draft in dayDrafts) {
      draft.dispose();
    }

    super.dispose();
  }

  void _updateDayDrafts(int newDuration) {
    if (newDuration > dayDrafts.length) {
      for (int index = dayDrafts.length; index < newDuration; index++) {
        dayDrafts.add(
          _WorkshopDayDraft(
            dayNumber: index + 1,
          ),
        );
      }
    } else if (newDuration < dayDrafts.length) {
      final removedDrafts = dayDrafts.sublist(newDuration);

      for (final draft in removedDrafts) {
        draft.dispose();
      }

      dayDrafts.removeRange(
        newDuration,
        dayDrafts.length,
      );
    }

    durationDays = newDuration;
  }

  bool isValidUrl(String value) {
    final cleaned = value.trim();

    return cleaned.startsWith('http://') ||
        cleaned.startsWith('https://');
  }

  double? parsePrice() {
    final cleaned = priceController.text
        .trim()
        .replaceAll(',', '.');

    return double.tryParse(cleaned);
  }

  int? parseCapacity() {
    final cleaned = capacityController.text.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return int.tryParse(cleaned);
  }

  String dayTypeLabel(String type) {
    switch (type) {
      case 'audio':
        return 'Ses Kaydı';
      case 'video':
        return 'Video Dosyası';
      case 'link':
        return 'Video Linki';
      default:
        return 'İçerik';
    }
  }

  String dayHelpText(String type) {
    switch (type) {
      case 'audio':
        return 'MP3, WAV, M4A, AAC veya OGG dosyası yükleyebilirsin.';
      case 'video':
        return 'MP4, MOV veya WEBM video dosyası yükleyebilirsin.';
      case 'link':
        return 'YouTube, Vimeo veya başka bir video bağlantısı ekleyebilirsin.';
      default:
        return '';
    }
  }

  List<String> allowedExtensions(String type) {
    if (type == 'audio') {
      return [
        'mp3',
        'wav',
        'm4a',
        'aac',
        'ogg',
      ];
    }

    if (type == 'video') {
      return [
        'mp4',
        'mov',
        'webm',
      ];
    }

    return [];
  }

  Future<void> pickCoverFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      selectedCoverFile = result.files.first;
      coverUrlController.clear();
    });
  }

  Future<void> pickDayMediaFile(
    _WorkshopDayDraft draft,
  ) async {
    final extensions = allowedExtensions(
      draft.contentType,
    );

    if (extensions.isEmpty) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      draft.selectedMediaFile = result.files.first;
      draft.contentUrlController.clear();
    });
  }

  void clearCoverFile() {
    setState(() {
      selectedCoverFile = null;
    });
  }

  void clearDayMediaFile(
    _WorkshopDayDraft draft,
  ) {
    setState(() {
      draft.selectedMediaFile = null;
    });
  }

  String? validateGeneralForm() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final price = parsePrice();
    final capacity = parseCapacity();
    final coverUrl = coverUrlController.text.trim();

    if (title.length < 3) {
      return 'Atölye başlığı en az 3 karakter olmalı.';
    }

    if (description.isEmpty) {
      return 'Atölye açıklaması zorunlu.';
    }

    if (durationDays < 1 || durationDays > 20) {
      return 'Atölye süresi 1 ile 20 gün arasında olmalı.';
    }

    if (price == null || price < 0) {
      return 'Geçerli bir fiyat girmelisin.';
    }

    if (capacityController.text.trim().isNotEmpty) {
      if (capacity == null || capacity <= 0) {
        return 'Kapasite pozitif bir sayı olmalı.';
      }
    }

    if (coverUrl.isNotEmpty && !isValidUrl(coverUrl)) {
      return 'Kapak görseli bağlantısı http veya https ile başlamalı.';
    }

    return null;
  }

  String? validateDays() {
    for (final draft in dayDrafts) {
      final title = draft.titleController.text.trim();
      final contentUrl =
          draft.contentUrlController.text.trim();

      if (title.isEmpty) {
        return '${draft.dayNumber}. gün için başlık yazmalısın.';
      }

      if (draft.contentType == 'link') {
        if (contentUrl.isEmpty) {
          return '${draft.dayNumber}. gün için video bağlantısı eklemelisin.';
        }

        if (!isValidUrl(contentUrl)) {
          return '${draft.dayNumber}. gün bağlantısı http veya https ile başlamalı.';
        }
      } else {
        if (draft.selectedMediaFile == null) {
          return '${draft.dayNumber}. gün için ${dayTypeLabel(draft.contentType).toLowerCase()} seçmelisin.';
        }
      }
    }

    return null;
  }

  Future<void> createWorkshop() async {
    if (isSaving) {
      return;
    }

    final generalError = validateGeneralForm();

    if (generalError != null) {
      showMessage(generalError);
      return;
    }

    final daysError = validateDays();

    if (daysError != null) {
      showMessage(daysError);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      String finalCoverUrl =
          coverUrlController.text.trim();

      if (selectedCoverFile != null) {
        finalCoverUrl =
            await workshopService.uploadWorkshopCover(
          file: selectedCoverFile!,
        );
      }

      final List<Map<String, dynamic>> uploadedDays = [];

      for (final draft in dayDrafts) {
        String finalContentUrl =
            draft.contentUrlController.text.trim();

        if (draft.contentType != 'link') {
          finalContentUrl =
              await workshopService.uploadWorkshopMedia(
            file: draft.selectedMediaFile!,
            contentType: draft.contentType,
          );
        }

        uploadedDays.add({
          'day_number': draft.dayNumber,
          'title': draft.titleController.text.trim(),
          'description':
              draft.descriptionController.text.trim(),
          'content_type': draft.contentType,
          'content_url': finalContentUrl,
          'duration_text':
              draft.durationController.text.trim(),
        });
      }

      await workshopService.createWorkshop(
        title: titleController.text.trim(),
        description:
            descriptionController.text.trim(),
        imageUrl: finalCoverUrl,
        category: categoryController.text.trim(),
        durationDays: durationDays,
        price: parsePrice() ?? 0,
        currency: currency,
        capacity: parseCapacity(),
        days: uploadedDays,
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'Atölye taslak olarak oluşturuldu.',
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      showMessage(
        'Atölye oluşturulamadı: $error',
      );
    }
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget buildBackgroundBody({
    required Widget child,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                color: softGreen,
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

  InputDecoration inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.84),
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
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.4,
        ),
      ),
    );
  }

  Widget buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: !isSaving,
        cursorColor: primaryColor,
        decoration: inputDecoration(
          label: label,
          hint: hint,
        ),
      ),
    );
  }

  Widget buildSectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
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
      child: child,
    );
  }

  Widget buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD7E1D0),
            ),
          ),
          child: Icon(
            icon,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildGeneralInformationCard() {
    return buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader(
            icon: Icons.auto_awesome_mosaic_outlined,
            title: 'Atölye Bilgileri',
            subtitle:
                'Öğrencilerin göreceği temel atölye bilgilerini doldur.',
          ),
          const SizedBox(height: 20),
          buildInput(
            controller: titleController,
            label: 'Atölye Başlığı',
            hint: 'Örn: 7 Günlük Bolluk Atölyesi',
          ),
          buildInput(
            controller: descriptionController,
            label: 'Atölye Açıklaması',
            hint:
                'Atölyenin amacı ve içeriği hakkında bilgi ver.',
            maxLines: 5,
          ),
          buildInput(
            controller: categoryController,
            label: 'Kategori',
            hint: 'Örn: Bolluk, İlişkiler, Spiritüel',
          ),
          const SizedBox(height: 2),
          DropdownButtonFormField<int>(
            value: durationDays,
            decoration: inputDecoration(
              label: 'Atölye Süresi',
              hint: 'Gün sayısını seç',
            ),
            items: List.generate(
              20,
              (index) {
                final day = index + 1;

                return DropdownMenuItem<int>(
                  value: day,
                  child: Text(
                    '$day Gün',
                  ),
                );
              },
            ),
            onChanged: isSaving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _updateDayDrafts(value);
                    });
                  },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: priceController,
                  enabled: !isSaving,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: inputDecoration(
                    label: 'Fiyat',
                    hint: '0',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currency,
                  decoration: inputDecoration(
                    label: 'Para Birimi',
                    hint: '',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'try',
                      child: Text('TRY'),
                    ),
                    DropdownMenuItem(
                      value: 'usd',
                      child: Text('USD'),
                    ),
                    DropdownMenuItem(
                      value: 'eur',
                      child: Text('EUR'),
                    ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            currency = value;
                          });
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          buildInput(
            controller: capacityController,
            label: 'Katılımcı Kapasitesi',
            hint:
                'Boş bırakırsan sınırsız katılım olur.',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget buildCoverCard() {
    return buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader(
            icon: Icons.image_outlined,
            title: 'Kapak Görseli',
            subtitle:
                'Atölye listesinde gösterilecek kapak görselini seç.',
          ),
          const SizedBox(height: 18),
          if (selectedCoverFile != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCoverFile!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        isSaving ? null : clearCoverFile,
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFFC85C5C),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  isSaving ? null : pickCoverFile,
              icon: const Icon(
                Icons.upload_file,
              ),
              label: Text(
                selectedCoverFile == null
                    ? 'Kapak Görseli Seç'
                    : 'Kapak Görselini Değiştir',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(
                  color: primaryColor,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (selectedCoverFile == null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: coverUrlController,
              enabled: !isSaving,
              decoration: inputDecoration(
                label: 'Kapak Görseli URL',
                hint:
                    'Opsiyonel: https://...',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildDayCard(
    _WorkshopDayDraft draft,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: softGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${draft.dayNumber}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${draft.dayNumber}. Gün İçeriği',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: draft.contentType,
            decoration: inputDecoration(
              label: 'İçerik Türü',
              hint: '',
            ),
            items: const [
              DropdownMenuItem(
                value: 'audio',
                child: Text(
                  'Ses Kaydı Yükle',
                ),
              ),
              DropdownMenuItem(
                value: 'video',
                child: Text(
                  'Video Dosyası Yükle',
                ),
              ),
              DropdownMenuItem(
                value: 'link',
                child: Text(
                  'Video Linki Ekle',
                ),
              ),
            ],
            onChanged: isSaving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      draft.contentType = value;
                      draft.selectedMediaFile = null;
                      draft.contentUrlController.clear();
                    });
                  },
          ),
          const SizedBox(height: 12),
          buildInput(
            controller: draft.titleController,
            label: '${draft.dayNumber}. Gün Başlığı',
            hint:
                'Örn: Niyet Belirleme Çalışması',
          ),
          buildInput(
            controller:
                draft.descriptionController,
            label:
                '${draft.dayNumber}. Gün Açıklaması',
            hint:
                'Bu gün yapılacak çalışmayı açıkla.',
            maxLines: 3,
          ),
          buildInput(
            controller:
                draft.durationController,
            label: 'İçerik Süresi',
            hint:
                'Opsiyonel: 15 dk, 30 dk',
          ),
          if (draft.contentType == 'link')
            buildInput(
              controller:
                  draft.contentUrlController,
              label: 'Video Bağlantısı',
              hint:
                  'https://www.youtube.com/...',
            )
          else
            buildDayFilePicker(draft),
        ],
      ),
    );
  }

  Widget buildDayFilePicker(
    _WorkshopDayDraft draft,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            dayTypeLabel(draft.contentType),
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            dayHelpText(draft.contentType),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          if (draft.selectedMediaFile != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    color: primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      draft.selectedMediaFile!.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            clearDayMediaFile(draft);
                          },
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFFC85C5C),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving
                  ? null
                  : () {
                      pickDayMediaFile(draft);
                    },
              icon: const Icon(
                Icons.upload_file,
              ),
              label: Text(
                draft.selectedMediaFile == null
                    ? 'Dosya Seç'
                    : 'Dosyayı Değiştir',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(
                  color: primaryColor,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDaysSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        buildSectionCard(
          child: buildSectionHeader(
            icon: Icons.view_day_outlined,
            title: 'Günlük İçerikler',
            subtitle:
                '$durationDays günlük atölyenin her günü için ayrı ses, video veya bağlantı ekle.',
          ),
        ),
        const SizedBox(height: 16),
        ...dayDrafts.map(buildDayCard),
      ],
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed:
            isSaving ? null : createWorkshop,
        icon: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.save_outlined,
              ),
        label: Text(
          isSaving
              ? 'Dosyalar Yükleniyor...'
              : 'Atölyeyi Taslak Olarak Kaydet',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              primaryColor.withOpacity(0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
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
          'Yeni Atölye',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor:
            Colors.white.withOpacity(0.18),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      body: buildBackgroundBody(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),
            children: [
              buildGeneralInformationCard(),
              const SizedBox(height: 18),
              buildCoverCard(),
              const SizedBox(height: 18),
              buildDaysSection(),
              const SizedBox(height: 8),
              buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkshopDayDraft {
  final int dayNumber;

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController durationController;
  final TextEditingController contentUrlController;

  String contentType;
  PlatformFile? selectedMediaFile;

  _WorkshopDayDraft({
    required this.dayNumber,
  })  : titleController = TextEditingController(),
        descriptionController =
            TextEditingController(),
        durationController =
            TextEditingController(),
        contentUrlController =
            TextEditingController(),
        contentType = 'audio';

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    contentUrlController.dispose();
  }
}