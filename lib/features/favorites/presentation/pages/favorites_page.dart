import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  static const String backgroundImage =
      'assets/images/backgrounds/home_bg_1.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Favorilerim',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.14),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFEEF3EA),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.05),
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.76),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.68),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3EA).withOpacity(0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD7E1D0),
                          ),
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          color: Color(0xFF536B4E),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Favorilerim',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF2F3A32),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Kaydettiğin meditasyonlar, eğitimler ve özel içerikler burada toplanacak.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4F5A51),
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF536B4E),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yakında favori içeriklerini buradan takip edebileceksin.',
                          style: TextStyle(
                            color: Color(0xFF2F3A32),
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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