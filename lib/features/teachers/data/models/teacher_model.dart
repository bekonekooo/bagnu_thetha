class TeacherModel {
  final String id;
  final String name;
  final String specialty;
  final String category;
  final String experience;
  final double rating;
  final String bio;
  final String imageUrl;
  final bool isActive;

  TeacherModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.category,
    required this.experience,
    required this.rating,
    required this.bio,
    required this.imageUrl,
    required this.isActive,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      category: map['category'] ?? '',
      experience: map['experience'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      bio: map['bio'] ?? '',
      imageUrl: map['image_url'] ?? '',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'category': category,
      'experience': experience,
      'rating': rating,
      'bio': bio,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}