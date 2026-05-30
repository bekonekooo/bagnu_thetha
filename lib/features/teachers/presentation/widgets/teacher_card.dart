import 'package:flutter/material.dart';

class TeacherCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String category;
  final String experience;
  final double rating;
  final String bio;
  final VoidCallback onTap;
  final String? imageUrl;
  final double sessionPrice;
  final String currency;

  const TeacherCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.category,
    required this.experience,
    required this.rating,
    required this.bio,
    required this.onTap,
    required this.sessionPrice,
    required this.currency,
    this.imageUrl,
  });

  String get formattedPrice {
    if (sessionPrice <= 0) {
      return 'Ücret belirtilmemiş';
    }

    final cleanPrice = sessionPrice % 1 == 0
        ? sessionPrice.toInt().toString()
        : sessionPrice.toStringAsFixed(2);

    if (currency.toLowerCase() == 'try') {
      return '₺$cleanPrice';
    }

    return '$cleanPrice ${currency.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    final cleanBio = bio.trim().isEmpty
        ? 'Bu öğretmen hakkında detaylı bilgi için profili inceleyebilirsin.'
        : bio.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.56),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEEF3EA).withOpacity(0.92),
                        border: Border.all(
                          color: const Color(0xFFD7E1D0),
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white.withOpacity(0.85),
                        backgroundImage:
                            hasImage ? NetworkImage(imageUrl!) : null,
                        child: hasImage
                            ? null
                            : const Icon(
                                Icons.person_outline,
                                size: 38,
                                color: Color(0xFF536B4E),
                              ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F3A32),
                              height: 1.15,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            specialty,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF536B4E),
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MiniBadge(
                                icon: Icons.category_outlined,
                                text: category.isEmpty ? 'Kategori' : category,
                              ),
                              _MiniBadge(
                                icon: Icons.workspace_premium_outlined,
                                text: experience.isEmpty
                                    ? 'Deneyim'
                                    : experience,
                              ),
                              _MiniBadge(
                                icon: Icons.star,
                                text: rating.toStringAsFixed(1),
                                iconColor: const Color(0xFFE6A700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3E8).withOpacity(0.68),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD7E1D0).withOpacity(0.75),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.62),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF4F7A52),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Seans Ücreti',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F3A32),
                          ),
                        ),
                      ),
                      Text(
                        formattedPrice,
                        style: const TextStyle(
                          color: Color(0xFF4F7A52),
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  cleanBio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF465046),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Detay Gör'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF536B4E),
                          side: const BorderSide(
                            color: Color(0xFF536B4E),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.34),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Randevu Al'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF536B4E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _MiniBadge({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.44),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: iconColor ?? const Color(0xFF536B4E),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F3A32),
            ),
          ),
        ],
      ),
    );
  }
}