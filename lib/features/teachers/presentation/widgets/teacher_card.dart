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

  const TeacherCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.category,
    required this.experience,
    required this.rating,
    required this.bio,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final cleanBio = bio.trim().isEmpty
        ? 'Bu öğretmen hakkında detaylı bilgi için profili inceleyebilirsin.'
        : bio.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.deepPurple.shade50,
                      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
                      child: hasImage
                          ? null
                          : const Icon(
                              Icons.person,
                              size: 34,
                              color: Colors.deepPurple,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            specialty,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
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
                                iconColor: Colors.amber,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  cleanBio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Detay Gör'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: iconColor ?? Colors.deepPurple,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}