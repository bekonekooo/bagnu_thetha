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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasDate
                  ? const Color(0xFF536B4E).withOpacity(0.35)
                  : Colors.white.withOpacity(0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hasDate
                      ? const Color(0xFFEEF3EA).withOpacity(0.95)
                      : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: hasDate
                        ? const Color(0xFFD7E1D0)
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: hasDate
                      ? const Color(0xFF536B4E)
                      : const Color(0xFF8A9188),
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
                        color: hasDate
                            ? const Color(0xFF536B4E)
                            : const Color(0xFF667064),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F3A32),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF536B4E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}