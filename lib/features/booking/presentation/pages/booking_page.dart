import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../sessions/data/services/session_service.dart';
import '../../data/services/availability_service.dart';

class BookingPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const BookingPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  String? selectedTime;
  bool isLoading = false;
  bool isLoadingTimes = false;

  final sessionService = SessionService();
  final availabilityService = AvailabilityService();
  final notesController = TextEditingController();

  List<String> availableTimes = [];

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        selectedTime = null;
      });

      await fetchAvailableTimes(pickedDate);
    }
  }

  Future<void> fetchAvailableTimes(DateTime date) async {
    setState(() {
      isLoadingTimes = true;
      availableTimes = [];
    });

    try {
      final availabilityList =
          await availabilityService.fetchTeacherAvailability(
        teacherId: widget.teacherId,
        weekday: date.weekday,
      );

      final bookedTimes = await sessionService.fetchBookedTimes(
        teacherId: widget.teacherId,
        sessionDate: date,
      );

      final allAvailableTimes =
          availabilityList.map((item) => item.timeSlot).toList();

      final filteredTimes = allAvailableTimes
          .where((time) => !bookedTimes.contains(time))
          .toList();

      if (!mounted) return;

      setState(() {
        availableTimes = filteredTimes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saatler yüklenemedi: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoadingTimes = false;
      });
    }
  }

  Future<void> confirmBooking() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seçin')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await sessionService.createSession(
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        sessionDate: selectedDate!,
        sessionTime: selectedTime!,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seans başarıyla oluşturuldu')),
      );

      context.go('/sessions');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  String get formattedDate {
    if (selectedDate == null) {
      return 'Tarih seçilmedi';
    }

    final day = selectedDate!.day.toString().padLeft(2, '0');
    final month = selectedDate!.month.toString().padLeft(2, '0');
    final year = selectedDate!.year.toString();

    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teacherName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seans Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Öğretmen: ${widget.teacherName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tarih Seç',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(formattedDate),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Saat Seç',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (selectedDate == null)
              const Text('Önce tarih seçmelisin.')
            else if (isLoadingTimes)
              const Center(child: CircularProgressIndicator())
            else if (availableTimes.isEmpty)
              const Text('Bu gün için müsait saat bulunmuyor.')
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableTimes.map((time) {
                  final isSelected = selectedTime == time;

                  return ChoiceChip(
                    label: Text(time),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedTime = time;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            const Text(
              'Not (İsteğe Bağlı)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Seansla ilgili kısa bir not yazabilirsin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Seansı Onayla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}