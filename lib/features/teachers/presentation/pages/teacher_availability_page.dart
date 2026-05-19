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

  final List<String> timeOptions = const [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

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

  Future<void> addTemplateHours() async {
    if (isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Şablon saatleri ekle'),
          content: Text(
            '${weekdayName(selectedWeekday)} günü için 10:00 - 18:00 arası saatler eklensin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Ekle'),
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
      final template = [
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
      ];

      await availabilityService.addMultipleAvailability(
        teacherId: widget.teacherId,
        weekday: selectedWeekday,
        timeSlots: template,
      );

      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şablon saatler eklendi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şablon eklenemedi: $e')),
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

  bool isTimeAlreadyAdded(String time) {
    return selectedDayAvailability().any((item) => item.timeSlot == time);
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: timeOptions.map((time) {
            final isSelected = selectedTime == time;
            final alreadyAdded = isTimeAlreadyAdded(time);

            return ChoiceChip(
              selected: isSelected,
              label: Text(alreadyAdded ? '$time ✓' : time),
              onSelected: (_) {
                setState(() {
                  selectedTime = time;
                });
              },
              selectedColor: Colors.deepPurple,
              backgroundColor: alreadyAdded ? Colors.green.shade50 : Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : alreadyAdded
                        ? Colors.green.shade800
                        : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected
                      ? Colors.deepPurple
                      : alreadyAdded
                          ? Colors.green.shade200
                          : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildActionPanel() {
    final alreadyAdded = isTimeAlreadyAdded(selectedTime);

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
                  alreadyAdded
                      ? '$selectedTime zaten ${weekdayName(selectedWeekday)} gününe ekli.'
                      : '$selectedTime saatini ${weekdayName(selectedWeekday)} gününe ekleyebilirsin.',
                  style: const TextStyle(height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting || alreadyAdded ? null : addAvailability,
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : addTemplateHours,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Şablon Ekle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
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