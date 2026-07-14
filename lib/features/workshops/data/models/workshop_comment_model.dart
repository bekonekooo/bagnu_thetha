class WorkshopCommentModel {
  final String id;
  final String workshopId;
  final String userId;
  final String commentText;
  final String userName;
  final String userImageUrl;
  final DateTime? createdAt;

  const WorkshopCommentModel({
    required this.id,
    required this.workshopId,
    required this.userId,
    required this.commentText,
    required this.userName,
    required this.userImageUrl,
    required this.createdAt,
  });

  factory WorkshopCommentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final profileMap = map['profiles'];

    return WorkshopCommentModel(
      id: map['id']?.toString() ?? '',
      workshopId:
          map['workshop_id']?.toString() ?? '',
      userId:
          map['user_id']?.toString() ?? '',
      commentText:
          map['comment_text']?.toString() ?? '',
      userName: profileMap is Map
          ? profileMap['full_name']?.toString() ??
              'Kullanıcı'
          : 'Kullanıcı',
      userImageUrl: profileMap is Map
          ? profileMap['image_url']?.toString() ?? ''
          : '',
      createdAt: DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ),
    );
  }
}