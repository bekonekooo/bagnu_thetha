import 'package:flutter/material.dart';

class BookingInfoCard extends StatelessWidget {
  final String teacherName;

  const BookingInfoCard({
    super.key,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Öğretmen: $teacherName',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}