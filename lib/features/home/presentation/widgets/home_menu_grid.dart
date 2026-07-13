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
        icon: Icons.groups_2_outlined,
        title: 'Topluluk',
        route: '/community',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (context, index) {
          final item = items[index];

          return _NatureMenuCard(
            item: item,
            onTap: () => onTap(item.route),
          );
        },
      ),
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
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        splashColor: const Color(0xFF536B4E).withOpacity(0.10),
        highlightColor: const Color(0xFF536B4E).withOpacity(0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.74),
            borderRadius: BorderRadius.circular(30),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3EA).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: const Color(0xFFD7E1D0),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFF536B4E),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                    height: 1.08,
                    letterSpacing: -0.35,
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