import 'package:flutter/material.dart';

import '../../../../core/legal/legal_content.dart';

class LegalDocumentPage extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentPage({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              document.intro,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ),
          const SizedBox(height: 26),
          for (final section in document.sections) ...[
            Text(section.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
