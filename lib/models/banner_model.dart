class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String discountCode;
  final String buttonText;
  final bool isActive;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.discountCode,
    this.buttonText = 'EXPLORE OFFERS',
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'discountCode': discountCode,
      'buttonText': buttonText,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BannerModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return BannerModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      discountCode: map['discountCode'] ?? '',
      buttonText: map['buttonText'] ?? 'EXPLORE OFFERS',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
