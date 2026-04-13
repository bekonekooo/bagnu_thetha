import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/features/sessions/data/mock_sessions.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const BookingPage({
    super.key,
    required this.teacher,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  String? selectedTime;

  final List<String> timeSlots = [
    '10:00',
    '12:00',
    '14:00',
    '16:00',
    '18:00',
    '20:00',
  ];

  Future<void> pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void selectTime(String time) {
    setState(() {
      selectedTime = time;
    });
  }

  void confirmBooking() {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce tarih ve saat seç.'),
        ),
      );
      return;
    }

    mockSessions.add({
      'teacherName': widget.teacher['name'],
      'specialty': widget.teacher['specialty'],
      'date': DateFormat('dd.MM.yyyy').format(selectedDate!),
      'time': selectedTime,
      'status': 'Yaklaşan',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seans başarıyla oluşturuldu.'),
      ),
    );

    context.go('/sessions');
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = widget.teacher['name'] ?? '';
    final specialty = widget.teacher['specialty'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seans Al'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacherName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialty,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tarih Seç',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  selectedDate == null
                      ? 'Tarih seç'
                      : DateFormat('dd.MM.yyyy').format(selectedDate!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Saat Seç',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: timeSlots.map((time) {
                final isSelected = selectedTime == time;

                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (_) => selectTime(time),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: confirmBooking,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Seansı Onayla'),
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