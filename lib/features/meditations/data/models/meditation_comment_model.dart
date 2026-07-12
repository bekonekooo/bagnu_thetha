class MeditationCommentModel {
  final String id;
  final String meditationId;
  final String userId;
  final String commentText;
  final DateTime? createdAt;
  final String userFullName;
  final String userImageUrl;

  const MeditationCommentModel({
    required this.id,
    required this.meditationId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    required this.userFullName,
    required this.userImageUrl,
  });

  factory MeditationCommentModel.fromMap(Map<String, dynamic> map) {
    final profileRaw = map['profiles'];
    final profile = profileRaw is Map<String, dynamic>
        ? profileRaw
        : <String, dynamic>{};

    return MeditationCommentModel(
      id: map['id']?.toString() ?? '',
      meditationId: map['meditation_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      commentText: map['comment_text']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      userFullName: profile['full_name']?.toString().trim().isNotEmpty == true
          ? profile['full_name'].toString()
          : 'Kullanıcı',
      userImageUrl: profile['image_url']?.toString() ?? '',
    );
  }
}