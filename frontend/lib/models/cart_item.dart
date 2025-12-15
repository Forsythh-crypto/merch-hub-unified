import 'listing.dart';

class CartItem {
  final String id; // Unique ID for the cart item (e.g. timestamp)
  final Listing listing;
  int quantity;
  final String? size;
  final String? notes;

  CartItem({
    required this.id,
    required this.listing,
    required this.quantity,
    this.size,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing': listing.toJson(), // We store the full listing to display details
      'quantity': quantity,
      'size': size,
      'notes': notes,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      listing: Listing.fromJson(json['listing']),
      quantity: json['quantity'],
      size: json['size'],
      notes: json['notes'],
    );
  }
  
  double get totalPrice => listing.price * quantity;
}
