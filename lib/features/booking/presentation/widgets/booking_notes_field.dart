import 'package:flutter/material.dart';

class BookingNotesField extends StatelessWidget {
  final TextEditingController controller;

  const BookingNotesField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Not ekle',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F3A32),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Öğretmene iletmek istediğin kısa bir not varsa yazabilirsin.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF606A61),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            cursorColor: const Color(0xFF536B4E),
            decoration: InputDecoration(
              hintText:
                  'Örn: İlk seansım olacak, özellikle şu konuda destek almak istiyorum...',
              hintStyle: const TextStyle(
                color: Color(0xFF9AA09A),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                borderSide: BorderSide(
                  color: Color(0xFF536B4E),
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}