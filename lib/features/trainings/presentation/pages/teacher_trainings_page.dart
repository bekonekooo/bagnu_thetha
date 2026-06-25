import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/trainings/data/models/training_model.dart';
import 'package:flutter_application_1/features/trainings/data/services/training_service.dart';

class TeacherTrainingsPage extends StatefulWidget {
  const TeacherTrainingsPage({super.key});

  @override
  State<TeacherTrainingsPage> createState() => _TeacherTrainingsPageState();
}

class _TrainingSessionDraft {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const _TrainingSessionDraft({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  String get sessionDate {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String cleanTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  String get startTimeText => cleanTime(startTime);
  String get endTimeText => cleanTime(endTime);

  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }

  String get formattedTimeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');

    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  bool get isValid {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    return endMinutes > startMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'session_date': sessionDate,
      'start_time': startTimeText,
      'end_time': endTimeText,
    };
  }
}

class _TeacherTrainingsPageState extends State<TeacherTrainingsPage> {
  final TrainingService trainingService = TrainingService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final categoryController = TextEditingController();
  final locationTextController = TextEditingController();
  final priceController = TextEditingController();
  final capacityController = TextEditingController();

  late Future<List<TrainingModel>> trainingsFuture;

  String selectedLocationType = 'online';
  String selectedCurrency = 'try';
  String selectedMode = 'single';

  bool isSaving = false;

  DateTime? selectedSingleDate;
  final List<_TrainingSessionDraft> sessionDrafts = [];

  static const String pageBackground =
      'assets/images/backgrounds/home_bg_4.jpg';

  @override
  void initState() {
    super.initState();
    trainingsFuture = trainingService.fetchMyTeacherTrainings();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    categoryController.dispose();
    locationTextController.dispose();
    priceController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  Future<void> reloadTrainings() async {
    setState(() {
      trainingsFuture = trainingService.fetchMyTeacherTrainings();
    });

    await trainingsFuture;
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }

  Future<DateTime?> pickDate({
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Eğitim gününü seç',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );
  }

  Future<TimeOfDay?> pickTime({
    TimeOfDay? initialTime,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Saat seç',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );
  }

  Future<void> selectSingleDate() async {
    final picked = await pickDate(initialDate: selectedSingleDate);

    if (picked == null) return;

    setState(() {
      selectedSingleDate = picked;
      sessionDrafts.clear();
    });
  }

  Future<void> addSessionDraft() async {
    DateTime? nullableDate;

    if (selectedMode == 'single') {
      if (selectedSingleDate == null) {
        showMessage('Önce tek günlük eğitim tarihini seçmelisin.');
        return;
      }

      if (sessionDrafts.length >= 3) {
        showMessage('Tek günlük eğitim için en fazla 3 saat seçebilirsin.');
        return;
      }

      nullableDate = selectedSingleDate;
    } else {
      nullableDate = await pickDate();

      if (nullableDate == null) return;
    }

    final pickedStart = await pickTime();

    if (pickedStart == null) return;

    final pickedEnd = await pickTime(
      initialTime: TimeOfDay(
        hour: pickedStart.hour + 1 > 23 ? 23 : pickedStart.hour + 1,
        minute: pickedStart.minute,
      ),
    );

    if (pickedEnd == null) return;

    final selectedDate = nullableDate;

    if (selectedDate == null) return;

    final draft = _TrainingSessionDraft(
      date: selectedDate,
      startTime: pickedStart,
      endTime: pickedEnd,
    );

    if (!draft.isValid) {
      showMessage('Bitiş saati başlangıç saatinden sonra olmalı.');
      return;
    }

    setState(() {
      sessionDrafts.add(draft);
      sessionDrafts.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);

        if (dateCompare != 0) {
          return dateCompare;
        }

        final aStart = a.startTime.hour * 60 + a.startTime.minute;
        final bStart = b.startTime.hour * 60 + b.startTime.minute;

        return aStart.compareTo(bStart);
      });
    });
  }

  void removeSessionDraft(int index) {
    setState(() {
      sessionDrafts.removeAt(index);
    });
  }

  bool isValidUrl(String value) {
    if (value.trim().isEmpty) return true;

    return value.startsWith('http://') || value.startsWith('https://');
  }

  Future<void> createTraining() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final category = categoryController.text.trim();
    final locationText = locationTextController.text.trim();

    final price =
        double.tryParse(priceController.text.trim().replaceAll(',', '.')) ?? 0;

    final capacityText = capacityController.text.trim();
    final capacity = capacityText.isEmpty ? null : int.tryParse(capacityText);

    if (title.isEmpty) {
      showMessage('Eğitim başlığı zorunlu.');
      return;
    }

    if (description.isEmpty) {
      showMessage('Eğitim açıklaması zorunlu.');
      return;
    }

    if (!isValidUrl(imageUrl)) {
      showMessage('Kapak görseli URL http veya https ile başlamalı.');
      return;
    }

    if (capacityText.isNotEmpty && capacity == null) {
      showMessage('Kontenjan sayı olarak girilmeli.');
      return;
    }

    if (sessionDrafts.isEmpty) {
      showMessage('En az bir gün/saat aralığı eklemelisin.');
      return;
    }

    if (selectedMode == 'single' && sessionDrafts.length > 3) {
      showMessage('Tek günlük eğitim için en fazla 3 saat seçebilirsin.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await trainingService.createTraining(
        title: title,
        description: description,
        imageUrl: imageUrl,
        category: category,
        locationType: selectedLocationType,
        locationText: locationText,
        price: price,
        currency: selectedCurrency,
        capacity: capacity,
        sessions: sessionDrafts.map((item) => item.toMap()).toList(),
      );

      titleController.clear();
      descriptionController.clear();
      imageUrlController.clear();
      categoryController.clear();
      locationTextController.clear();
      priceController.clear();
      capacityController.clear();

      if (!mounted) return;

      setState(() {
        selectedLocationType = 'online';
        selectedCurrency = 'try';
        selectedMode = 'single';
        selectedSingleDate = null;
        sessionDrafts.clear();
        isSaving = false;
      });

      await reloadTrainings();

      showMessage(
        'Eğitim oluşturuldu. Öğrencilere görünmesi için Supabase’den aktif yapmalısın.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('Eğitim oluşturulamadı: $e');
    }
  }

  Future<void> toggleTrainingActive(TrainingModel training) async {
    try {
      await trainingService.toggleTrainingActive(
        trainingId: training.id,
        isActive: !training.isActive,
      );

      await reloadTrainings();

      showMessage(
        training.isActive
            ? 'Eğitim pasife alındı.'
            : 'Eğitim aktif hale getirildi.',
      );
    } catch (e) {
      showMessage('Eğitim durumu değiştirilemedi: $e');
    }
  }

  Future<void> deleteTraining(TrainingModel training) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eğitimi sil'),
          content: Text('"${training.title}" silinsin mi?'),
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
      await trainingService.deleteTraining(training.id);
      await reloadTrainings();
      showMessage('Eğitim silindi.');
    } catch (e) {
      showMessage('Eğitim silinemedi: $e');
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
            pageBackground,
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
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  Widget buildModeSelector() {
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
          const Text(
            'Eğitim Zamanlama Tipi',
            style: TextStyle(
              color: Color(0xFF2F3A32),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          RadioListTile<String>(
            value: 'single',
            groupValue: selectedMode,
            activeColor: const Color(0xFF536B4E),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tek gün içinde 3 saate kadar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Bir gün seç, en fazla 3 saat aralığı ekle.'),
            onChanged: isSaving
                ? null
                : (value) {
                    if (value == null) return;

                    setState(() {
                      selectedMode = value;
                      selectedSingleDate = null;
                      sessionDrafts.clear();
                    });
                  },
          ),
          RadioListTile<String>(
            value: 'multi',
            groupValue: selectedMode,
            activeColor: const Color(0xFF536B4E),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Birden fazla gün',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Her gün için tarih ve saat aralığı ekle.'),
            onChanged: isSaving
                ? null
                : (value) {
                    if (value == null) return;

                    setState(() {
                      selectedMode = value;
                      selectedSingleDate = null;
                      sessionDrafts.clear();
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget buildSessionBuilder() {
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
          const Text(
            'Gün ve Saatler',
            style: TextStyle(
              color: Color(0xFF2F3A32),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          if (selectedMode == 'single') ...[
            OutlinedButton.icon(
              onPressed: isSaving ? null : selectSingleDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                selectedSingleDate == null
                    ? 'Tek günlük eğitim tarihini seç'
                    : 'Seçilen tarih: ${formatDate(selectedSingleDate!)}',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu gün için en fazla 3 saat aralığı ekleyebilirsin.',
              style: TextStyle(
                color: Color(0xFF606A61),
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else
            const Text(
              'Her oturum için ayrı tarih ve saat aralığı seçebilirsin.',
              style: TextStyle(
                color: Color(0xFF606A61),
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 12),
          if (sessionDrafts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Henüz gün/saat eklenmedi.',
                style: TextStyle(
                  color: Color(0xFF606A61),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...sessionDrafts.asMap().entries.map((entry) {
              final index = entry.key;
              final draft = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Color(0xFF536B4E),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${draft.formattedDate} / ${draft.formattedTimeRange}',
                        style: const TextStyle(
                          color: Color(0xFF2F3A32),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          isSaving ? null : () => removeSessionDraft(index),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFFC85C5C),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : addSessionDraft,
              icon: const Icon(Icons.add),
              label: const Text('Gün / Saat Aralığı Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF536B4E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
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
                Icons.school_outlined,
                color: Color(0xFF536B4E),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yeni Eğitim Oluştur',
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
          buildInput(
            controller: titleController,
            label: 'Eğitim Başlığı',
            hint: 'Örn: ThetaHealing Temel Eğitim',
          ),
          buildInput(
            controller: descriptionController,
            label: 'Açıklama',
            hint: 'Eğitimin içeriğini yaz',
            maxLines: 4,
          ),
          buildInput(
            controller: imageUrlController,
            label: 'Kapak Görseli URL',
            hint: 'Opsiyonel: https://...',
          ),
          buildInput(
            controller: categoryController,
            label: 'Kategori',
            hint: 'Örn: ThetaHealing, Bolluk, İlişkiler',
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedLocationType,
                  decoration: InputDecoration(
                    labelText: 'Konum Tipi',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.78),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'online',
                      child: Text('Online'),
                    ),
                    DropdownMenuItem(
                      value: 'face_to_face',
                      child: Text('Yüz Yüze'),
                    ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            selectedLocationType = value;
                          });
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Para Birimi',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.78),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
                          if (value == null) return;

                          setState(() {
                            selectedCurrency = value;
                          });
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          buildInput(
            controller: locationTextController,
            label: 'Konum / Bağlantı',
            hint: 'Zoom linki, adres veya açıklama',
          ),
          Row(
            children: [
              Expanded(
                child: buildInput(
                  controller: priceController,
                  label: 'Fiyat',
                  hint: '0 ücretsiz',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildInput(
                  controller: capacityController,
                  label: 'Kontenjan',
                  hint: 'Opsiyonel',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          buildModeSelector(),
          buildSessionBuilder(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : createTraining,
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
              label: Text(isSaving ? 'Kaydediliyor...' : 'Eğitimi Oluştur'),
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

  Widget buildTrainingItem(TrainingModel training) {
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
            backgroundColor: training.isActive
                ? const Color(0xFFEEF3EA)
                : Colors.grey.shade200,
            child: Icon(
              Icons.school_outlined,
              color: training.isActive
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
                  training.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${training.statusLabel} • ${training.isActive ? "Aktif" : "Onay Bekliyor / Pasif"}',
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (training.sessions.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${training.sessions.length} oturum • İlk gün: ${training.firstDateText}',
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
            onPressed: () => toggleTrainingActive(training),
            icon: Icon(
              training.isActive ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF536B4E),
            ),
          ),
          IconButton(
            onPressed: () => deleteTraining(training),
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFC85C5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMyTrainingsEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Henüz eğitim oluşturmadın.',
        style: TextStyle(
          color: Color(0xFF606A61),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget buildMyTrainings() {
    return FutureBuilder<List<TrainingModel>>(
      future: trainingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              buildFormCard(),
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF536B4E),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              buildFormCard(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Eğitimler yüklenemedi: ${snapshot.error}',
                  style: const TextStyle(
                    color: Color(0xFF2F3A32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }

        final items = snapshot.data ?? [];

        final headerWidgets = <Widget>[
          buildFormCard(),
          const SizedBox(height: 24),
          const Text(
            'Oluşturduğum Eğitimler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F3A32),
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty) buildMyTrainingsEmptyCard(),
        ];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          itemCount: headerWidgets.length + items.length,
          itemBuilder: (context, index) {
            if (index < headerWidgets.length) {
              return headerWidgets[index];
            }

            return buildTrainingItem(items[index - headerWidgets.length]);
          },
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
          'Eğitim Yönetimi',
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
            onRefresh: reloadTrainings,
            child: buildMyTrainings(),
          ),
        ),
      ),
    );
  }
}