import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStorageService {
  static const String _productsKey = 'products';
  static const String _ordersKey = 'orders';
  static const String _addressesKey = 'addresses';
  static const String _currentUserKey = 'current_user';
  static const String _cartKey = 'cart';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Products
  Future<List<Product>> getProducts() async {
    final String? data = _prefs.getString(_productsKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Product.fromJson(e)).toList();
  }

  Future<void> saveProducts(List<Product> products) async {
    final String data = jsonEncode(products.map((e) => e.toJson()).toList());
    await _prefs.setString(_productsKey, data);
  }

  Future<void> addProduct(Product product) async {
    final products = await getProducts();
    products.add(product);
    await saveProducts(products);
  }

  Future<void> updateProduct(Product product) async {
    final products = await getProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await saveProducts(products);
    }
  }

  Future<void> deleteProduct(String productId) async {
    final products = await getProducts();
    products.removeWhere((p) => p.id == productId);
    await saveProducts(products);
  }

  // Orders
  Future<List<Order>> getOrders() async {
    final String? data = _prefs.getString(_ordersKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Order.fromJson(e)).toList();
  }

  Future<void> saveOrders(List<Order> orders) async {
    final String data = jsonEncode(orders.map((e) => e.toJson()).toList());
    await _prefs.setString(_ordersKey, data);
  }

  Future<void> addOrder(Order order) async {
    final orders = await getOrders();
    orders.insert(0, order);
    await saveOrders(orders);
  }

  Future<void> updateOrder(Order order) async {
    final orders = await getOrders();
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      orders[index] = order;
      await saveOrders(orders);
    }
  }

  Future<List<Order>> getOrdersByUserId(String userId) async {
    final orders = await getOrders();
    return orders.where((o) => o.userId == userId).toList();
  }

  // Addresses
  Future<List<Address>> getAddresses() async {
    final String? data = _prefs.getString(_addressesKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Address.fromJson(e)).toList();
  }

  Future<void> saveAddresses(List<Address> addresses) async {
    final String data = jsonEncode(addresses.map((e) => e.toJson()).toList());
    await _prefs.setString(_addressesKey, data);
  }

  Future<void> addAddress(Address address) async {
    final addresses = await getAddresses();
    addresses.add(address);
    await saveAddresses(addresses);
  }

  Future<void> updateAddress(Address address) async {
    final addresses = await getAddresses();
    final index = addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      addresses[index] = address;
      await saveAddresses(addresses);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final addresses = await getAddresses();
    addresses.removeWhere((a) => a.id == addressId);
    await saveAddresses(addresses);
  }

  // User
  Future<AppUser?> getCurrentUser() async {
    final String? data = _prefs.getString(_currentUserKey);
    if (data == null) return null;
    return AppUser.fromJson(jsonDecode(data));
  }

  Future<void> saveCurrentUser(AppUser user) async {
    final String data = jsonEncode(user.toJson());
    await _prefs.setString(_currentUserKey, data);
  }

  Future<void> clearCurrentUser() async {
    await _prefs.remove(_currentUserKey);
  }

  // Cart
  Future<List<CartItem>> getCart() async {
    final String? data = _prefs.getString(_cartKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => CartItem.fromJson(e)).toList();
  }

  Future<void> saveCart(List<CartItem> cart) async {
    final String data = jsonEncode(cart.map((e) => e.toJson()).toList());
    await _prefs.setString(_cartKey, data);
  }

  Future<void> clearCart() async {
    await _prefs.remove(_cartKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
