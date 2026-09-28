import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  // Runtime memory cache to store locally added cart items for the session.
  static final List<Cart> _localCartsCache = [];

  // Gets all carts from the API combined with any locally added carts.
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      final remoteCarts = cartsJson.map((json) => Cart.fromJson(json)).toList();
      return [..._localCartsCache, ...remoteCarts];
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // Gets the cart(s) belonging to a specific user, including locally cached additions.
  Future<List<Cart>> getCartsByUser(int userId) async {
    try {
      final response = await http.get(Uri.parse('$host/carts/user/$userId'));

      List<Cart> remoteCarts = [];
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List cartsJson = data['carts'] ?? [];
        remoteCarts = cartsJson.map((json) => Cart.fromJson(json)).toList();
      }

      // Filter local cache for this specific user.
      final userLocalCarts = _localCartsCache
          .where((c) => c.userId == userId)
          .toList();

      if (userLocalCarts.isNotEmpty) {
        return [...userLocalCarts, ...remoteCarts];
      }

      return remoteCarts;
    } catch (e) {
      final userLocalCarts = _localCartsCache
          .where((c) => c.userId == userId)
          .toList();
      if (userLocalCarts.isNotEmpty) return userLocalCarts;
      throw Exception('Failed to load user cart: $e');
    }
  }

  // Adds a new cart for a user with the given product details and caches it locally.
  Future<Cart> addToCart(
    int userId,
    List<Map<String, dynamic>> products,
  ) async {
    try {
      await http.post(
        Uri.parse('$host/carts/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'products': products}),
      );
    } catch (_) {
      // Ignore network errors for mock API endpoint stability.
    }

    // Maps product details cleanly so the cart screen can render them instantly.
    final List<CartProduct> cartProducts = products.map((p) {
      final productObj = p['product'];
      return CartProduct(
        id: p['id'],
        title: productObj?.title ?? 'Product #${p['id']}',
        price: productObj?.price ?? 0.0,
        quantity: p['quantity'],
        total: (productObj?.price ?? 0.0) * p['quantity'],
        discountPercentage: productObj?.discountPercentage ?? 0.0,
        discountedTotal: (productObj?.price ?? 0.0) * p['quantity'],
        thumbnail: productObj?.thumbnail ?? '',
      );
    }).toList();

    final double totalAmount = cartProducts.fold(
      0,
      (sum, item) => sum + item.total,
    );

    final newCart = Cart(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      products: cartProducts,
      total: totalAmount,
      discountedTotal: totalAmount,
      userId: userId,
      totalProducts: cartProducts.length,
      totalQuantity: products.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      ),
    );

    // Save to local runtime cache so it shows up in the CartScreen immediately.
    _localCartsCache.add(newCart);
    return newCart;
  }
}
