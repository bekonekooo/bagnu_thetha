import 'package:flutter/material.dart';

class BookingDatePicker extends StatelessWidget {
  final String formattedDate;
  final VoidCallback onTap;

  const BookingDatePicker({
    super.key,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = formattedDate != 'Tarih seçilmedi';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDate ? Colors.deepPurple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasDate ? Colors.deepPurple.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  hasDate ? Colors.deepPurple : Colors.grey.shade100,
              child: Icon(
                Icons.calendar_month,
                color: hasDate ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDate ? 'Seçilen tarih' : 'Tarih seç',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasDate ? Colors.deepPurple : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}