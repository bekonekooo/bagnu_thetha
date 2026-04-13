import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final String teacherName;
  final String specialty;
  final String date;
  final String time;
  final String status;

  const SessionCard({
    super.key,
    required this.teacherName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, 3),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            specialty,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Text(date),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 8),
              Text(time),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 8),
              Text(status),
            ],
          ),
        ],
      ),
    );
  }
}