class CommentModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorImageUrl;
  final String body;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorImageUrl,
    required this.body,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];

    final authorName = profile is Map
        ? (profile['full_name']?.toString().trim().isNotEmpty == true
            ? profile['full_name'].toString()
            : 'Kullanıcı')
        : 'Kullanıcı';

    final authorImageUrl =
        profile is Map ? profile['image_url']?.toString() : null;

    return CommentModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      authorName: authorName,
      authorImageUrl:
          authorImageUrl != null && authorImageUrl.isNotEmpty
              ? authorImageUrl
              : null,
      body: map['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
