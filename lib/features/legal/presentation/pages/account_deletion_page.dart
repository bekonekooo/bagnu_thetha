import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/company_info.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/services/account_deletion_service.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final AccountDeletionService deletionService = AccountDeletionService();
  bool isDeleting = false;

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hesabını kalıcı olarak sil?'),
          content: const Text(
            'Bu işlem profilini, geçmişini ve kişisel bağlantılarını silebilir. Yorumların anonimleştirilerek kalabilir; Stripe ödeme kayıtları kullanıcı bağlantısı kaldırılarak korunabilir. Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kalıcı olarak sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || isDeleting) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await deletionService.deleteAccount();

      try {
        await supabase.auth.signOut();
      } catch (_) {
        // Auth hesabı silindiyse yerel oturum temizleme başarısız olsa bile
        // router sonraki auth değişikliğinde kullanıcıyı dışarı çıkarır.
      }

      if (!mounted) return;
      context.go('/login');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hesap silinemedi: $error'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hesabımı Sil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
        children: [
          Text(
            'Hesap silme talebinle birlikte kişisel verilerinin kapsamını ve teknik süreci açıkça anlatmak istiyoruz.',
            style: textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 24),
          const _DeletionSection(
            title: 'Silinmesi beklenenler',
            body:
                'Supabase Auth hesabı, profil bilgileri, beğeniler, oynatma geçmişi, astroloji/numeroloji/Çin burcu geçmişi, bildirimler, rezervasyon ve gereksiz kullanıcı bağlantıları silinir. Profil fotoğrafları Storage’dan kaldırılır.',
          ),
          const _DeletionSection(
            title: 'Anonimleştirilecekler',
            body:
                'Yorumlar silinmez; kullanıcı bağlantısı kaldırılarak “Silinmiş Kullanıcı” adıyla kalabilir. Stripe üzerinden gerçekleşen 1’e 1 seans ödeme kayıtları korunabilir, ancak kullanıcı bağlantısı kaldırılır.',
          ),
          const _DeletionSection(
            title: 'İşlem hakkında',
            body:
                'Silme işlemi güvenli bir Supabase Edge Function üzerinden yürütülür. Service role key Flutter uygulamasında bulunmaz. İşlem tamamlandığında oturum kapatılır ve giriş ekranına dönülür.',
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6B9AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9DED5),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.manage_accounts_outlined,
                        color: Color(0xFF974B43),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesap işlemleri',
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF663A3A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bu işlem geri alınamaz. Devam etmeden önce verilerini gözden geçir.',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF795F59),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isDeleting ? null : _deleteAccount,
                    icon: isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(
                      isDeleting
                          ? 'Hesap siliniyor...'
                          : 'Hesabımı kalıcı olarak sil',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF974B43),
                      disabledForegroundColor: const Color(0xFFB49A94),
                      side: const BorderSide(
                        color: Color(0xFFB96555),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'İşlem sırasında bir hata oluşursa ${CompanyInfo.kvkkEmail} adresinden destek alabilirsin.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _DeletionSection extends StatelessWidget {
  final String title;
  final String body;

  const _DeletionSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}
