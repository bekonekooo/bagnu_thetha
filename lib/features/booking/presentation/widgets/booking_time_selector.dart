import 'package:flutter/material.dart';

class BookingTimeSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final bool isLoadingTimes;
  final List<String> availableTimes;
  final bool Function(DateTime date, String time) isSlotInPast;
  final Function(String time) onTimeSelected;

  const BookingTimeSelector({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.isLoadingTimes,
    required this.availableTimes,
    required this.isSlotInPast,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) {
      return _MessageBox(
        icon: Icons.calendar_month_outlined,
        title: 'Tarih seçilmedi',
        subtitle: 'Uygun saatleri görmek için önce tarih seçmelisin.',
      );
    }

    if (isLoadingTimes) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Müsait saatler yükleniyor...'),
          ],
        ),
      );
    }

    final visibleTimes = availableTimes
        .where((time) => !isSlotInPast(selectedDate!, time))
        .toList();

    if (visibleTimes.isEmpty) {
      return _MessageBox(
        icon: Icons.event_busy,
        title: 'Müsait saat yok',
        subtitle:
            'Bu gün için uygun saat bulunmuyor. Lütfen başka bir tarih seç.',
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: visibleTimes.map((time) {
        final isSelected = selectedTime == time;

        return ChoiceChip(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(time),
          ),
          selected: isSelected,
          onSelected: (_) {
            onTimeSelected(time);
          },
          selectedColor: Colors.deepPurple,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            ),
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MessageBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(
              icon,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
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
}