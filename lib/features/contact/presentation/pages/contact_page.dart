import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/company_info.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _open(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu bağlantı şu anda açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bize Ulaşın')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Text(
            '${CompanyInfo.brand} ile ilgili soruların, önerilerin veya desteğe ihtiyacın olduğunda bize ulaşabilirsin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          _ContactItem(
            icon: Icons.support_agent_outlined,
            label: 'Destek',
            value: CompanyInfo.supportEmail,
            onTap: () => _open(context, 'mailto:${CompanyInfo.supportEmail}'),
          ),
          _ContactItem(
            icon: Icons.email_outlined,
            label: 'Genel iletişim',
            value: CompanyInfo.contactEmail,
            onTap: () => _open(context, 'mailto:${CompanyInfo.contactEmail}'),
          ),
          _ContactItem(
            icon: Icons.privacy_tip_outlined,
            label: 'KVKK',
            value: CompanyInfo.kvkkEmail,
            onTap: () => _open(context, 'mailto:${CompanyInfo.kvkkEmail}'),
          ),
          _ContactItem(
            icon: Icons.phone_outlined,
            label: 'Telefon / WhatsApp',
            value: CompanyInfo.phone,
            onTap: () => _open(context, CompanyInfo.whatsappUrl),
          ),
          _ContactItem(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            value: CompanyInfo.instagramHandle,
            onTap: () => _open(context, CompanyInfo.instagramUrl),
          ),
          _ContactItem(
            icon: Icons.language_outlined,
            label: 'Web sitesi',
            value: 'yenidenkendine.com',
            onTap: () => _open(context, CompanyInfo.websiteUrl),
          ),
          const SizedBox(height: 22),
          Text('Adres', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            CompanyInfo.address,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_outward_rounded, size: 18),
      onTap: onTap,
    );
  }
}
