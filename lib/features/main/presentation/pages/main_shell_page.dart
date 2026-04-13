import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends StatelessWidget {
  final Widget child;

  const MainShellPage({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location == '/home') return 0;
    if (location == '/sessions') return 1;
    if (location == '/profile') return 2;

    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/sessions');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Seanslar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}