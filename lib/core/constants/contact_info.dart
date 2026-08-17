import 'company_info.dart';

/// Backward-compatible contact aliases for existing screens.
class ContactInfo {
  static const supportEmail = 'mailto:${CompanyInfo.supportEmail}';
  static const contactEmail = 'mailto:${CompanyInfo.contactEmail}';
  static const kvkkEmail = 'mailto:${CompanyInfo.kvkkEmail}';
  static const phoneUrl = 'tel:+905303030498';
  static const instagramUrl = CompanyInfo.instagramUrl;
  static const whatsappUrl = CompanyInfo.whatsappUrl;
  static const websiteUrl = CompanyInfo.websiteUrl;

  const ContactInfo._();
}
