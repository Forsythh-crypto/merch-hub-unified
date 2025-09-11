class ListingImage {
  final int id;
  final int listingId;
  final String imagePath;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ListingImage({
    required this.id,
    required this.listingId,
    required this.imagePath,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingImage.fromJson(Map<String, dynamic> json) {
    return ListingImage(
      id: json['id'],
      listingId: json['listing_id'],
      imagePath: json['image_path'],
      sortOrder: json['sort_order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'image_path': imagePath,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}