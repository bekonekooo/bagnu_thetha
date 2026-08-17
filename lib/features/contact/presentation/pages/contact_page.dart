import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/contact_info.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _open(BuildContext context, String value) async {
    if (value.startsWith('TODO_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İletişim bilgisi henüz eklenmemiş.')),
      );
      return;
    }
    final uri = Uri.tryParse(value);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            'BagnuTheta ile ilgili soruların, önerilerin veya desteğe ihtiyacın olduğunda bizimle iletişime geçebilirsin.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _ContactItem(
            icon: Icons.email_outlined,
            label: 'E-posta',
            value: ContactInfo.supportEmail,
            onTap: () => _open(context, ContactInfo.supportEmail),
          ),
          _ContactItem(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            value: ContactInfo.instagramUrl,
            onTap: () => _open(context, ContactInfo.instagramUrl),
          ),
          _ContactItem(
            icon: Icons.chat_bubble_outline,
            label: 'WhatsApp',
            value: ContactInfo.whatsappUrl,
            onTap: () => _open(context, ContactInfo.whatsappUrl),
          ),
          _ContactItem(
            icon: Icons.language_outlined,
            label: 'Web sitesi',
            value: ContactInfo.websiteUrl,
            onTap: () => _open(context, ContactInfo.websiteUrl),
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
