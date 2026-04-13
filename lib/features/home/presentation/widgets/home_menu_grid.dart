import 'package:flutter/material.dart';
import 'home_menu_card.dart';

class HomeMenuGrid extends StatelessWidget {
  final Function(String) onTap;

  const HomeMenuGrid({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        HomeMenuCard(
          icon: Icons.person,
          title: 'Profilim',
          subtitle: 'Kişisel bilgilerini gör',
          onTap: () => onTap('/profile'),
        ),
        HomeMenuCard(
          icon: Icons.calendar_month,
          title: 'Seanslarım',
          subtitle: 'Randevularını takip et',
          onTap: () => onTap('/sessions'),
        ),
        HomeMenuCard(
          icon: Icons.search,
          title: 'Öğretmen Bul',
          subtitle: 'Uzmanlara ulaş',
          onTap: () => onTap('/teachers'),
        ),
        HomeMenuCard(
          icon: Icons.school,
          title: 'Eğitimler',
          subtitle: 'İçerikleri keşfet',
          onTap: () => onTap('/trainings'),
        ),
        HomeMenuCard(
          icon: Icons.auto_graph,
          title: 'Aylık Rehberlik',
          subtitle: 'Kişisel analiz',
          onTap: () => onTap('/guidance'),
        ),
        HomeMenuCard(
          icon: Icons.groups,
          title: 'Topluluk',
          subtitle: 'Diğer kullanıcılarla etkileşim',
          onTap: () => onTap('/community'),
        ),
      ],
    );
  }
}