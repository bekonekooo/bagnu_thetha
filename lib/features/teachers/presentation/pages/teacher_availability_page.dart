import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/booking/data/models/availability_model.dart';
import 'package:flutter_application_1/features/booking/data/services/availability_service.dart';

class TeacherAvailabilityPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherAvailabilityPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherAvailabilityPage> createState() =>
      _TeacherAvailabilityPageState();
}

class _TeacherAvailabilityPageState extends State<TeacherAvailabilityPage> {
  final availabilityService = AvailabilityService();

  bool isLoading = true;
  bool isSubmitting = false;

  List<AvailabilityModel> availabilityList = [];

  int selectedWeekday = DateTime.now().weekday;
  String selectedTime = '09:00';

  @override
  void initState() {
    super.initState();

    if (selectedWeekday < 1 || selectedWeekday > 7) {
      selectedWeekday = 1;
    }

    loadAvailability();
  }

  Future<void> loadAvailability() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await availabilityService.fetchAllTeacherAvailability(
        teacherId: widget.teacherId,
      );

      if (!mounted) return;

      setState(() {
        availabilityList = response;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saatler yüklenemedi: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addAvailability() async {
    if (isSubmitting) return;

    final conflict = conflictingAvailability(selectedTime);

    if (conflict != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$selectedTime, ${conflict.timeSlot} saatindeki 1 saatlik dersle çakışıyor.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await availabilityService.addAvailability(
        teacherId: widget.teacherId,
        weekday: selectedWeekday,
        timeSlot: selectedTime,
      );

      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${weekdayName(selectedWeekday)} $selectedTime eklendi'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saat eklenemedi: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> clearDay() async {
    final selectedDayList = grouped()[selectedWeekday] ?? [];

    if (selectedDayList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${weekdayName(selectedWeekday)} günü zaten boş'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Günü temizle'),
          content: Text(
            '${weekdayName(selectedWeekday)} günündeki tüm uygun saatleri silmek istiyor musun?',
          ),
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
              icon: const Icon(Icons.delete_outline),
              label: const Text('Temizle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      await availabilityService.clearDayAvailability(
        teacherId: widget.teacherId,
        weekday: selectedWeekday,
      );

      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${weekdayName(selectedWeekday)} günü temizlendi'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gün temizlenemedi: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> deleteAvailability(AvailabilityModel availability) async {
    try {
      await availabilityService.deleteAvailability(availability.id);
      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${availability.timeSlot} silindi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saat silinemedi: $e')),
      );
    }
  }

  String weekdayName(int day) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    return days[day - 1];
  }

  String shortWeekdayName(int day) {
    const days = [
      'Pzt',
      'Sal',
      'Çar',
      'Per',
      'Cum',
      'Cmt',
      'Paz',
    ];

    return days[day - 1];
  }

  TimeOfDay timeOfDayFromString(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;

    return TimeOfDay(
      hour: hour != null && hour >= 0 && hour <= 23 ? hour : 9,
      minute: minute != null && minute >= 0 && minute <= 59 ? minute : 0,
    );
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  int minutesFromTime(String value) {
    final time = timeOfDayFromString(value);
    return time.hour * 60 + time.minute;
  }

  String endTimeFor(String value) {
    final start = timeOfDayFromString(value);
    final totalMinutes = start.hour * 60 + start.minute + 60;
    final end = TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );

    return formatTime(end);
  }

  AvailabilityModel? conflictingAvailability(String time) {
    final requestedMinutes = minutesFromTime(time);

    for (final item in selectedDayAvailability()) {
      final existingMinutes = minutesFromTime(item.timeSlot);

      if ((requestedMinutes - existingMinutes).abs() < 60) {
        return item;
      }
    }

    return null;
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: timeOfDayFromString(selectedTime),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Ders başlangıç saatini seç',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
      hourLabelText: 'Saat',
      minuteLabelText: 'Dakika',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: Localizations.override(
            context: context,
            locale: const Locale('tr', 'TR'),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedTime = formatTime(picked);
    });
  }

  Map<int, List<AvailabilityModel>> grouped() {
    final map = <int, List<AvailabilityModel>>{};

    for (final item in availabilityList) {
      map.putIfAbsent(item.weekday, () => []);
      map[item.weekday]!.add(item);
    }

    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
    }

    return map;
  }

  List<AvailabilityModel> selectedDayAvailability() {
    return grouped()[selectedWeekday] ?? [];
  }

  Widget buildHeaderCard() {
    final selectedCount = selectedDayAvailability().length;

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.schedule,
              color: Colors.deepPurple,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teacherName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${weekdayName(selectedWeekday)} günü için $selectedCount uygun saat var.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gün Seç',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Uygunluk eklemek veya düzenlemek istediğin günü seç.',
          style: TextStyle(
            color: Colors.grey,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isSelected = selectedWeekday == day;
            final count = grouped()[day]?.length ?? 0;

            return ChoiceChip(
              selected: isSelected,
              label: Text('${shortWeekdayName(day)} ($count)'),
              onSelected: (_) {
                setState(() {
                  selectedWeekday = day;
                });
              },
              selectedColor: Colors.deepPurple,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget buildTimeSelector() {
    final conflict = conflictingAvailability(selectedTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saat Seç',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${weekdayName(selectedWeekday)} günü için uygun saat ekle.',
          style: const TextStyle(
            color: Colors.grey,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: conflict == null
                  ? Colors.deepPurple.shade100
                  : Colors.orange.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$selectedTime - ${endTimeFor(selectedTime)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: isSubmitting ? null : pickTime,
                    child: const Text('Saat seç'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                conflict == null
                    ? 'Ders süresi otomatik olarak 1 saat olacak.'
                    : '${conflict.timeSlot} ile çakışıyor. Başka bir saat seç.',
                style: TextStyle(
                  color: conflict == null
                      ? Colors.grey.shade700
                      : Colors.orange.shade800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActionPanel() {
    final conflict = conflictingAvailability(selectedTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.deepPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  conflict != null
                      ? '$selectedTime, ${conflict.timeSlot} ile çakışıyor.'
                      : '$selectedTime - ${endTimeFor(selectedTime)} aralığını ${weekdayName(selectedWeekday)} gününe ekleyebilirsin.',
                  style: const TextStyle(height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting || conflict != null
                  ? null
                  : addAvailability,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                isSubmitting ? 'İşleniyor...' : 'Seçili Saati Ekle',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSubmitting ? null : clearDay,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Günü Temizle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSelectedDayList() {
    final list = selectedDayAvailability();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${weekdayName(selectedWeekday)} Saatleri',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Silmek istediğin saatin üzerindeki çarpıya basabilirsin.',
          style: TextStyle(
            color: Colors.grey,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade50,
                  child: const Icon(
                    Icons.event_busy,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Bu gün için henüz uygun saat eklenmedi.',
                    style: TextStyle(height: 1.35),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: list.map((item) {
              return Chip(
                label: Text(
                  item.timeSlot,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                avatar: const Icon(
                  Icons.access_time,
                  size: 18,
                ),
                deleteIcon: const Icon(Icons.close),
                onDeleted: isSubmitting
                    ? null
                    : () {
                        deleteAvailability(item);
                      },
                backgroundColor: Colors.deepPurple.shade50,
                side: BorderSide(color: Colors.deepPurple.shade100),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget buildAllWeekSummary() {
    final data = grouped();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Haftalık Özet',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(7, (index) {
          final day = index + 1;
          final list = data[day] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selectedWeekday == day
                  ? Colors.deepPurple.shade50
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selectedWeekday == day
                    ? Colors.deepPurple.shade200
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    weekdayName(day),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  list.isEmpty ? 'Saat yok' : '${list.length} saat',
                  style: TextStyle(
                    color: list.isEmpty ? Colors.grey : Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygunluk Yönetimi'),
      ),
      body: RefreshIndicator(
        onRefresh: loadAvailability,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            buildHeaderCard(),
            const SizedBox(height: 26),
            if (isLoading)
              buildLoadingState()
            else ...[
              buildDaySelector(),
              const SizedBox(height: 26),
              buildTimeSelector(),
              const SizedBox(height: 22),
              buildActionPanel(),
              const SizedBox(height: 28),
              buildSelectedDayList(),
              const SizedBox(height: 28),
              buildAllWeekSummary(),
            ],
          ],
        ),
      ),
    );
  }
}
