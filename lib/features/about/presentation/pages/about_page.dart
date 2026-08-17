import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = const [
      ('Biz Kimiz', 'Bu alanı BagnuTheta hakkında doğrulanmış kurumsal metinle güncelleyin.'),
      ('Neler Sunuyoruz', 'Meditasyon, rehberlik, eğitim, atölye ve seans deneyimlerini tek bir sakin alanda buluşturuyoruz.'),
      ('Misyonumuz', 'Kullanıcıların kendileriyle bağ kurabilecekleri güvenilir ve sade bir alan oluşturmak.'),
      ('Uygulama Hakkında', 'BagnuTheta’nın güncel ürün ve hizmet açıklamasını burada yayınlayabilirsiniz.'),
      ('İletişim', 'İletişim bilgileri için Bize Ulaşın sayfasını kullanabilirsiniz.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Hakkımızda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        children: [
          Text(
            'BagnuTheta',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: const Color(0xFF653B3C),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          const Text('Kendine dönmek için daha sakin bir alan.'),
          const SizedBox(height: 36),
          for (final section in sections) ...[
            Text(
              section.$1,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(section.$2, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}
