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
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    print(
      '🔍 Listing.fromJson: Price type: ${json['price'].runtimeType}, value: ${json['price']}',
    );

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
    };
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
