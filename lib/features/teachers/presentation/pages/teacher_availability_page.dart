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

class _TeacherAvailabilityPageState
    extends State<TeacherAvailabilityPage> {
  final availabilityService = AvailabilityService();

  bool isLoading = true;
  bool isSubmitting = false;

  List<AvailabilityModel> availabilityList = [];

  int selectedWeekday = 1;
  String selectedTime = '09:00';

  final List<String> timeOptions = const [
    '09:00','10:00','11:00','12:00',
    '13:00','14:00','15:00','16:00',
    '17:00','18:00','19:00','20:00',
  ];

  @override
  void initState() {
    super.initState();
    loadAvailability();
  }

  Future<void> loadAvailability() async {
    setState(() => isLoading = true);

    try {
      final response =
          await availabilityService.fetchAllTeacherAvailability(
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
      setState(() => isLoading = false);
    }
  }

  Future<void> addAvailability() async {
    setState(() => isSubmitting = true);

    try {
      await availabilityService.addAvailability(
        teacherId: widget.teacherId,
        weekday: selectedWeekday,
        timeSlot: selectedTime,
      );

      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saat eklendi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => isSubmitting = false);
    }
  }

  Future<void> addTemplateHours() async {
    setState(() => isSubmitting = true);

    try {
      final template = [
        '10:00','11:00','12:00','13:00',
        '14:00','15:00','16:00','17:00','18:00'
      ];

      await availabilityService.addMultipleAvailability(
        teacherId: widget.teacherId,
        weekday: selectedWeekday,
        timeSlots: template,
      );

      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şablon eklendi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => isSubmitting = false);
    }
  }

  Future<void> clearDay() async {
    try {
      await availabilityService.clearDayAvailability(
        teacherId: widget.teacherId,
        weekday: selectedWeekday,
      );

      await loadAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gün temizlendi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> deleteAvailability(String id) async {
    await availabilityService.deleteAvailability(id);
    await loadAvailability();
  }

  String weekdayName(int day) {
    const days = [
      'Pazartesi','Salı','Çarşamba',
      'Perşembe','Cuma','Cumartesi','Pazar'
    ];
    return days[day - 1];
  }

  Map<int, List<AvailabilityModel>> grouped() {
    final map = <int, List<AvailabilityModel>>{};
    for (var item in availabilityList) {
      map.putIfAbsent(item.weekday, () => []);
      map[item.weekday]!.add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final data = grouped();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teacherName} Uygunluk'),
      ),
      body: RefreshIndicator(
        onRefresh: loadAvailability,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// ADD PANEL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField(
                      value: selectedWeekday,
                      items: List.generate(7, (i) {
                        final d = i + 1;
                        return DropdownMenuItem(
                          value: d,
                          child: Text(weekdayName(d)),
                        );
                      }),
                      onChanged: (v) =>
                          setState(() => selectedWeekday = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(
                      value: selectedTime,
                      items: timeOptions
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedTime = v!),
                    ),
                    const SizedBox(height: 12),

                    /// ADD BUTTON
                    ElevatedButton(
                      onPressed: isSubmitting ? null : addAvailability,
                      child: const Text('Saat Ekle'),
                    ),

                    const SizedBox(height: 8),

                    /// TEMPLATE + CLEAR
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                isSubmitting ? null : addTemplateHours,
                            child: const Text('Şablon'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: clearDay,
                            child: const Text('Temizle'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// LIST
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ...List.generate(7, (i) {
                final day = i + 1;
                final list = data[day] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      weekdayName(day),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    if (list.isEmpty)
                      const Text('Saat yok')
                    else
                      Wrap(
                        spacing: 8,
                        children: list.map((e) {
                          return Chip(
                            label: Text(e.timeSlot),
                            onDeleted: () =>
                                deleteAvailability(e.id),
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