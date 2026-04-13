import 'package:flutter/material.dart';

class SessionEmptyState extends StatelessWidget {
  final VoidCallback onFindTeacher;

  const SessionEmptyState({
    super.key,
    required this.onFindTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz bir seansın yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'İleride burada yaklaşan seanslarını, geçmiş görüşmelerini ve randevu detaylarını göreceksin.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFindTeacher,
              icon: const Icon(Icons.search),
              label: const Text('Öğretmen Bul'),
            ),
          ),
        ],
      ),
    );
  }
}