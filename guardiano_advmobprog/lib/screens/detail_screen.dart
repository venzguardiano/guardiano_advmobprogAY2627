import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product.dart';

// services
import '../services/cart_service.dart';

// widgets
import '../widgets/custom_text.dart';

// Displays full details for a single product.
class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final CartService _cartService = CartService();

  // No auth system yet, so this stands in for the logged in user.
  final int _userId = 5;

  bool _addingToCart = false;

  // Sends the current product to the cart endpoint.
  Future<void> _addToCart() async {
    setState(() => _addingToCart = true);

    try {
      await _cartService.addToCart(_userId, [
        {'id': widget.product.id, 'quantity': 1},
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add to cart: $e')));
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product thumbnail image.
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  product.thumbnail,
                  width: double.infinity,
                  height: 220.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(Icons.image, size: 48.sp),
                ),
              ),
              SizedBox(height: 16.h),

              // Title and brand.
              CustomText(
                text: product.title,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 4.h),
              DefaultTextStyle.merge(
                style: TextStyle(color: theme.hintColor),
                child: CustomText(text: product.brand, fontSize: 14.sp),
              ),
              SizedBox(height: 12.h),

              // Price and discount.
              Row(
                children: [
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(width: 8.w),
                  if (product.discountPercentage > 0)
                    DefaultTextStyle.merge(
                      style: const TextStyle(color: Colors.red),
                      child: CustomText(
                        text:
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),

              // Rating and stock.
              Row(
                children: [
                  Icon(Icons.star, size: 16.sp, color: Colors.amber),
                  SizedBox(width: 4.w),
                  CustomText(
                    text: product.rating.toStringAsFixed(1),
                    fontSize: 14.sp,
                  ),
                  SizedBox(width: 16.w),
                  DefaultTextStyle.merge(
                    style: TextStyle(color: theme.hintColor),
                    child: CustomText(
                      text: 'Stock: ${product.stock}',
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              _sectionTitle('Description'),
              CustomText(text: product.description, fontSize: 14.sp),
              SizedBox(height: 16.h),

              _sectionTitle('Category'),
              CustomText(text: product.category, fontSize: 14.sp),
              SizedBox(height: 16.h),

              // Tags list.
              if (product.tags.isNotEmpty) ...[
                _sectionTitle('Tags'),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: product.tags
                      .map(
                        (tag) => Chip(
                          label: CustomText(text: tag, fontSize: 12.sp),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 16.h),
              ],

              _sectionTitle('Product Info'),
              _infoRow('SKU', product.sku),
              _infoRow('Weight', '${product.weight} g'),
              _infoRow(
                'Dimensions',
                '${product.dimensions.width} x ${product.dimensions.height} x ${product.dimensions.depth} cm',
              ),
              _infoRow(
                'Minimum Order Quantity',
                '${product.minimumOrderQuantity}',
              ),
              _infoRow('Availability', product.availabilityStatus),
              SizedBox(height: 16.h),

              _sectionTitle('Warranty & Shipping'),
              CustomText(text: product.warrantyInformation, fontSize: 14.sp),
              SizedBox(height: 4.h),
              CustomText(text: product.shippingInformation, fontSize: 14.sp),
              SizedBox(height: 16.h),

              _sectionTitle('Return Policy'),
              CustomText(text: product.returnPolicy, fontSize: 14.sp),
              SizedBox(height: 16.h),

              // Reviews list.
              if (product.reviews.isNotEmpty) ...[
                _sectionTitle('Reviews'),
                ...product.reviews.map(
                  (review) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomText(
                                text: review.reviewerName,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              const Spacer(),
                              Icon(
                                Icons.star,
                                size: 14.sp,
                                color: Colors.amber,
                              ),
                              CustomText(
                                text: '${review.rating}',
                                fontSize: 12.sp,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          CustomText(text: review.comment, fontSize: 13.sp),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      // Add to cart button pinned to the bottom.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: _addingToCart ? null : _addToCart,
              icon: _addingToCart
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart),
              label: CustomText(
                text: _addingToCart ? 'Adding...' : 'Add to Cart',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Section header used throughout the details layout.
  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CustomText(
        text: title,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Label/value row for product info fields.
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          CustomText(
            text: '$label: ',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
          Expanded(
            child: CustomText(text: value, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
