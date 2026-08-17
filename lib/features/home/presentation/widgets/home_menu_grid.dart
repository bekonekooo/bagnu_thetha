import 'package:flutter/material.dart';

class HomeMenuGrid extends StatelessWidget {
  static const bool showCommunity = false;
  final Function(String) onTap;

  const HomeMenuGrid({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_HomeMenuItem>[
      _HomeMenuItem(
        icon: Icons.calendar_month_outlined,
        title: 'Seanslarım',
        route: '/sessions',
      ),
      _HomeMenuItem(
        icon: Icons.add_circle_outline,
        title: 'Randevu Al',
        route: '/teachers',
      ),
      _HomeMenuItem(
        icon: Icons.self_improvement,
        title: 'Meditasyonlar',
        route: '/meditations',
      ),
      _HomeMenuItem(
        icon: Icons.auto_graph_outlined,
        title: 'Rehberlik',
        route: '/guidance',
      ),
      _HomeMenuItem(
        icon: Icons.school_outlined,
        title: 'Eğitimler',
        route: '/trainings',
      ),
      _HomeMenuItem(
        icon: Icons.bookmark_border_rounded,
        title: 'Favorilerim',
        route: '/favorites',
      ),
      _HomeMenuItem(
        icon: Icons.auto_awesome_mosaic_outlined,
        title: 'Atölyeler',
        route: '/workshops',
      ),
    ];
    // Community remains implemented and routable, but is intentionally hidden
    // from the current consumer UI until the feature is reintroduced.

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return _SoftMenuCard(
          item: item,
          onTap: () => onTap(item.route),
        );
      }).toList(),
    );
  }
}

class _HomeMenuItem {
  final IconData icon;
  final String title;
  final String route;

  const _HomeMenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}

class _SoftMenuCard extends StatelessWidget {
  final _HomeMenuItem item;
  final VoidCallback onTap;

  const _SoftMenuCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF536B4E).withOpacity(0.08),
        highlightColor: const Color(0xFF536B4E).withOpacity(0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE8DDC9),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3EA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD7E1D0),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFF536B4E),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2F3A32),
                      height: 1.08,
                      letterSpacing: -0.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
