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
  State<TeacherAvailabilityPage> createState() => _TeacherAvailabilityPageState();
}

class _TeacherAvailabilityPageState extends State<TeacherAvailabilityPage> {
  final availabilityService = AvailabilityService();

  bool isLoading = true;
  bool isSubmitting = false;

  List<AvailabilityModel> availabilityList = [];

  int selectedWeekday = 1;
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
        const SnackBar(content: Text('Uygunluk saati eklendi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eklenemedi: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> deleteAvailability(String id) async {
    try {
      await availabilityService.deleteAvailability(id);
      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saat silindi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }

  String weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Pazartesi';
      case 2:
        return 'Salı';
      case 3:
        return 'Çarşamba';
      case 4:
        return 'Perşembe';
      case 5:
        return 'Cuma';
      case 6:
        return 'Cumartesi';
      case 7:
        return 'Pazar';
      default:
        return 'Bilinmiyor';
    }
  }

  Map<int, List<AvailabilityModel>> groupedAvailability() {
    final Map<int, List<AvailabilityModel>> grouped = {};

    for (final item in availabilityList) {
      grouped.putIfAbsent(item.weekday, () => []);
      grouped[item.weekday]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedAvailability();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teacherName} Uygunluk'),
      ),
      body: RefreshIndicator(
        onRefresh: loadAvailability,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yeni Uygunluk Ekle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedWeekday,
                      decoration: const InputDecoration(
                        labelText: 'Gün seç',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(7, (index) {
                        final day = index + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text(weekdayName(day)),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedWeekday = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedTime,
                      decoration: const InputDecoration(
                        labelText: 'Saat seç',
                        border: OutlineInputBorder(),
                      ),
                      items: timeOptions.map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedTime = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : addAvailability,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Saati Ekle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mevcut Uygunluklar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (availabilityList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: const Text(
                  'Henüz uygun saat eklenmedi.',
                ),
              )
            else
              ...List.generate(7, (index) {
                final weekday = index + 1;
                final items = grouped[weekday] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      weekdayName(weekday),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade100,
                        ),
                        child: const Text('Saat yok'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items.map((item) {
                          return Chip(
                            label: Text(item.timeSlot),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () => deleteAvailability(item.id),
                          );
                        }).toList(),
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}