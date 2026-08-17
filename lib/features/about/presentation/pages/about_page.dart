import 'package:flutter/material.dart';

import '../../../legal/presentation/pages/legal_document_page.dart';
import '../../../../core/legal/legal_content.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(document: LegalContent.about);
  }
}
