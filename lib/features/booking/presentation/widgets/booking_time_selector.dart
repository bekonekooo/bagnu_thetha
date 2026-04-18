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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              final isPast = selectedDate != null
                  ? isSlotInPast(selectedDate!, time)
                  : false;

              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                onSelected: isPast
                    ? null
                    : (_) {
                        onTimeSelected(time);
                      },
                selectedColor: Colors.deepPurple,
                disabledColor: Colors.grey.shade300,
                labelStyle: TextStyle(
                  color: isPast
                      ? Colors.grey
                      : isSelected
                          ? Colors.white
                          : Colors.black,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}