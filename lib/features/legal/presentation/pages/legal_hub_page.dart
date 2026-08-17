import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegalHubPage extends StatelessWidget {
  const LegalHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final links = const [
      ('Gizlilik Politikası', 'Kişisel verilerin nasıl işlendiği', '/privacy', Icons.lock_outline),
      ('KVKK Aydınlatma Metni', 'Veri sorumlusu ve başvuru bilgileri', '/kvkk', Icons.verified_user_outlined),
      ('Kullanım Koşulları', 'Hesap, içerik ve kullanım kuralları', '/terms', Icons.description_outlined),
      ('Plus Abonelik Koşulları', 'Mağaza abonelikleri ve yenileme', '/subscription-terms', Icons.workspace_premium_outlined),
      ('Seans / İptal / İade', '1’e 1 seans ödeme ve iptal koşulları', '/refund-policy', Icons.event_busy_outlined),
      ('18 Yaş Altı Bilgilendirme', 'Veli ve yasal temsilci bilgileri', '/minor-policy', Icons.family_restroom_outlined),
      ('Hesabımı Sil', 'Silme kapsamı ve mevcut teknik durum', '/account-deletion', Icons.delete_outline),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Hukuki & Gizlilik')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Text(
            'Yeniden Kendine hakkında yasal ve gizlilik bilgilerine buradan ulaşabilirsin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          for (final link in links)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Icon(link.$4, color: Theme.of(context).colorScheme.primary),
              title: Text(link.$1),
              subtitle: Text(link.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(link.$3),
            ),
        ],
      ),
    );
  }
}
