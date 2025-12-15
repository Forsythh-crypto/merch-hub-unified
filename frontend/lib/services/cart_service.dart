import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/listing.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  static const String _storageKey = 'cart_items';

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString(_storageKey);
    if (cartJson != null) {
      final List<dynamic> decodedList = jsonDecode(cartJson);
      _items = decodedList.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encodedList);
    notifyListeners();
  }

  Future<void> addItem(Listing listing, int quantity, String? size, String? notes) async {
    // Check if item with same ID and size exists (optional, for now we treat as separate entries if notes differ, 
    // but usually merging same items is better behavior. Let's merge if size matches)
    final existingIndex = _items.indexWhere((item) => 
      item.listing.id == listing.id && item.size == size
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        listing: listing,
        quantity: quantity,
        size: size,
        notes: notes,
      ));
    }
    await _saveCart();
  }

  Future<void> removeItem(String cartItemId) async {
    _items.removeWhere((item) => item.id == cartItemId);
    await _saveCart();
  }
  
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      if (newQuantity <= 0) {
        await removeItem(cartItemId);
      } else {
        _items[index].quantity = newQuantity;
        await _saveCart();
      }
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
  }

  // Get items grouped by department
  Map<String, List<CartItem>> getItemsByDepartment() {
    final Map<String, List<CartItem>> grouped = {};
    for (var item in _items) {
      final deptName = item.listing.department?.name ?? 'General';
      if (!grouped.containsKey(deptName)) {
        grouped[deptName] = [];
      }
      grouped[deptName]!.add(item);
    }
    return grouped;
  }
  
  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }
}
