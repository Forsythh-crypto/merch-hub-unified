import 'listing_image.dart';

class Listing {
  final int id;
  final String title;
  final String? description;
  final String? imagePath;
  final int departmentId;
  final int userId;
  final double price;
  final String? size;
  final String status;
  final int categoryId;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects
  final User? user;
  final Department? department;
  final Category? category;
  final List<SizeVariant>? sizeVariants;
  final List<ListingImage>? images;

  Listing({
    required this.id,
    required this.title,
    this.description,
    this.imagePath,
    required this.departmentId,
    required this.userId,
    required this.price,
    this.size,
    required this.status,
    required this.categoryId,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.department,
    this.category,
    this.sizeVariants,
    this.images,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.reviews,
  });

  // Ratings
  final double averageRating;
  final int reviewCount;
  final List<Review>? reviews;

  factory Listing.fromJson(Map<String, dynamic> json) {

    double price;
    if (json['price'] is String) {
      price = double.parse(json['price'] as String);
    } else if (json['price'] is int) {
      price = (json['price'] as int).toDouble();
    } else if (json['price'] is double) {
      price = json['price'] as double;
    } else {
      print('❌ Unexpected price type: ${json['price'].runtimeType}');
      price = 0.0;
    }

    return Listing(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imagePath: (json['image_path'] as String?)?.replaceAll('\\', '/'),
      departmentId: json['department_id'],
      userId: json['user_id'],
      price: price,
      size: json['size'],
      status: json['status'] ?? 'pending',
      categoryId: json['category_id'],
      stockQuantity: json['stock_quantity'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      sizeVariants: json['size_variants'] != null
          ? (json['size_variants'] as List)
                .map((variant) => SizeVariant.fromJson(variant))
                .toList()
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
                .map((image) => ListingImage.fromJson(image))
                .toList()
          : null,
      averageRating: (json['average_rating'] is int) 
          ? (json['average_rating'] as int).toDouble() 
          : (json['average_rating'] as double?) ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((review) => Review.fromJson(review))
              .toList()
          : null,
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'department_id': departmentId,
      'user_id': userId,
      'price': price,
      'size': size,
      'status': status,
      'category_id': categoryId,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'images': images?.map((image) => image.toJson()).toList(),
    };
  }
}

class Review {
  final int id;
  final int rating;
  final String? review;
  final String userName;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    this.review,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      review: json['review'],
      userName: json['user_name'] ?? 'Anonymous',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? departmentId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      departmentId: json['department_id'],
    );
  }
}

class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(id: json['id'], name: json['name']);
  }
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], name: json['name']);
  }
}

class SizeVariant {
  final int id;
  final int listingId;
  final String size;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  SizeVariant({
    required this.id,
    required this.listingId,
    required this.size,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SizeVariant.fromJson(Map<String, dynamic> json) {
    return SizeVariant(
      id: json['id'],
      listingId: json['listing_id'],
      size: json['size'],
      stockQuantity: json['stock_quantity'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'size': size,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
