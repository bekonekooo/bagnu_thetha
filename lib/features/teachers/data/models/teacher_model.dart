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
  final double sessionPrice;
  final String currency;

  final int likeCount;
  final int ratingCount;
  final double ratingAvg;

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
    required this.sessionPrice,
    required this.currency,
    this.likeCount = 0,
    this.ratingCount = 0,
    this.ratingAvg = 0,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialty: map['specialty']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      experience: map['experience']?.toString() ?? '',
      rating: double.tryParse(map['rating']?.toString() ?? '0') ?? 0,
      bio: map['bio']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      isActive: map['is_active'] ?? true,
      sessionPrice:
          double.tryParse(map['session_price']?.toString() ?? '0') ?? 0,
      currency: map['currency']?.toString() ?? 'try',
      likeCount: int.tryParse(map['like_count']?.toString() ?? '0') ?? 0,
      ratingCount: int.tryParse(map['rating_count']?.toString() ?? '0') ?? 0,
      ratingAvg: double.tryParse(map['rating_avg']?.toString() ?? '0') ?? 0,
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
      'session_price': sessionPrice,
      'currency': currency,
    };
  }

  String get formattedPrice {
    if (sessionPrice <= 0) {
      return 'Ücret belirtilmemiş';
    }

    final cleanPrice = sessionPrice % 1 == 0
        ? sessionPrice.toInt().toString()
        : sessionPrice.toStringAsFixed(2);

    if (currency.toLowerCase() == 'try') {
      return '₺$cleanPrice';
    }

    return '$cleanPrice ${currency.toUpperCase()}';
  }
}