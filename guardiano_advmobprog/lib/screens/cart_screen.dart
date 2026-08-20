import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/cart.dart';

// services
import '../services/cart_service.dart';
import '../services/product_service.dart';

// screens
import 'detail_screen.dart';

// widgets
import '../widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ProductService _productService = ProductService();

  // No auth system yet, so this stands in for the logged in user.
  final int _userId = 3;

  late Future<List<Cart>> _cartsFuture;

  // Local editable copy of the cart items and their quantities.
  List<CartProduct> _items = [];
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _cartsFuture = _cartService.getCartsByUser(_userId);
  }

  // Fetches the full product then opens the detail screen.
  Future<void> _openDetails(int productId) async {
    try {
      final product = await _productService.getProductById(productId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open product: $e')));
    }
  }

  // Adjusts the local quantity of an item, floor of 1.
  void _changeQuantity(int itemId, int delta) {
    setState(() {
      final current = _quantities[itemId] ?? 1;
      final updated = current + delta;
      _quantities[itemId] = updated < 1 ? 1 : updated;
    });
  }

  // Sum of price * quantity across all items.
  double get _subtotal {
    double sum = 0;
    for (final item in _items) {
      final qty = _quantities[item.id] ?? item.quantity;
      sum += item.price * qty;
    }
    return sum;
  }

  void _confirmOrder() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order confirmed')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: FutureBuilder<List<Cart>>(
        future: _cartsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: CustomText(text: 'Error: ${snapshot.error}'));
          }

          final carts = snapshot.data ?? [];
          if (carts.isEmpty) {
            return const Center(child: CustomText(text: 'No carts found'));
          }

          // This user only has one cart.
          final cart = carts.first;

          // Seed local items/quantities once on first successful load.
          if (_items.isEmpty) {
            _items = cart.products;
            for (final item in _items) {
              _quantities[item.id] = item.quantity;
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(12.r),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final qty = _quantities[item.id] ?? item.quantity;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: InkWell(
                        onTap: () => _openDetails(item.id),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.network(
                                  item.thumbnail,
                                  width: 56.w,
                                  height: 56.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.image, size: 32.sp),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: item.title,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        CustomText(
                                          text:
                                              '\$${item.price.toStringAsFixed(2)}',
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        SizedBox(width: 8.w),
                                        if (item.discountPercentage > 0)
                                          DefaultTextStyle.merge(
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                            child: CustomText(
                                              text:
                                                  '-${item.discountPercentage.toStringAsFixed(0)}%',
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.add_circle, size: 20.sp),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _changeQuantity(item.id, 1),
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(text: '$qty', fontSize: 13.sp),
                                  SizedBox(height: 4.h),
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle,
                                      size: 20.sp,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _changeQuantity(item.id, -1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Subtotal and confirm order footer.
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(text: 'Subtotal', fontSize: 14.sp),
                        CustomText(
                          text: '\$${_subtotal.toStringAsFixed(2)}',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _confirmOrder,
                        child: CustomText(
                          text: 'Confirm Order',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
