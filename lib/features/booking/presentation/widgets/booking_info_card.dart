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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA).withOpacity(0.95),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: const Icon(
              Icons.self_improvement,
              color: Color(0xFF536B4E),
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni seans',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667064),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Bu öğretmenle yeni bir seans oluşturuyorsun.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF606A61),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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