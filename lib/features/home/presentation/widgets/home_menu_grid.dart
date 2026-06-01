import 'package:flutter/material.dart';

class HomeMenuGrid extends StatelessWidget {
  final Function(String) onTap;

  const HomeMenuGrid({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _HomeMenuItem(
        icon: Icons.calendar_month_outlined,
        title: 'Seanslarım',
        subtitle: 'Randevularını ve canlı derslerini takip et',
        route: '/sessions',
      ),
      _HomeMenuItem(
        icon: Icons.add_circle_outline,
        title: 'Randevu Al',
        subtitle: 'Öğretmenlerden sana uygun seansı seç',
        route: '/teachers',
      ),
      _HomeMenuItem(
        icon: Icons.self_improvement,
        title: 'Meditasyonlar',
        subtitle: 'Ses kayıtları, videolar ve özel bağlantıları keşfet',
        route: '/meditations',
      ),
      _HomeMenuItem(
        icon: Icons.auto_graph_outlined,
        title: 'Aylık Rehberlik',
        subtitle: 'Kişisel analizlerini ve içgörülerini gör',
        route: '/guidance',
      ),
      _HomeMenuItem(
        icon: Icons.school_outlined,
        title: 'Eğitimler',
        subtitle: 'BagnuTheta içeriklerini keşfet',
        route: '/trainings',
      ),
      _HomeMenuItem(
        icon: Icons.groups_2_outlined,
        title: 'Topluluk',
        subtitle: 'Diğer kullanıcılarla aynı alanda buluş',
        route: '/community',
      ),
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _NatureMenuCard(
            item: item,
            onTap: () => onTap(item.route),
          ),
        );
      }).toList(),
    );
  }
}

class _HomeMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _HomeMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class _NatureMenuCard extends StatelessWidget {
  final _HomeMenuItem item;
  final VoidCallback onTap;

  const _NatureMenuCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.74),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3EA).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFD7E1D0),
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: const Color(0xFF536B4E),
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F3A32),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: Color(0xFF606A61),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Color(0xFF536B4E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}