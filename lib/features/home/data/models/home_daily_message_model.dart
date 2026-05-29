class HomeDailyMessageModel {
  final String id;
  final String title;
  final String subtitle;

  const HomeDailyMessageModel({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  factory HomeDailyMessageModel.fromMap(Map<String, dynamic> map) {
    return HomeDailyMessageModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
    );
  }

  static const HomeDailyMessageModel fallback = HomeDailyMessageModel(
    id: 'fallback',
    title: 'Bugün kendine nazik yaklaş',
    subtitle: 'Küçük bir duraklama bile günün enerjisini yumuşatabilir.',
  );
}