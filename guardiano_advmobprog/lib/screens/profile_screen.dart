import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/user.dart';
import '../models/cart.dart';

// services
import '../services/user_service.dart';
import '../services/cart_service.dart';

// widgets
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final CartService _cartService = CartService();

  User? _user;
  List<Cart> _carts = [];
  bool _isLoading = true;
  String? _error;
  bool _isFirebaseUser = false;
  String _firebaseEmail = '';
  String _firebaseUsername = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Determines LoginType and loads user data accordingly.
  Future<void> _loadProfile() async {
    try {
      // Check LoginType based on Firebase currentUser vs SharedPreferences
      final firebaseUser = _userService.currentUser;

      if (firebaseUser != null) {
        // Firebase Auth Login Type
        if (!mounted) return;
        setState(() {
          _isFirebaseUser = true;
          _firebaseEmail = firebaseUser.email ?? 'No Email';
          _firebaseUsername =
              firebaseUser.displayName ??
              firebaseUser.email?.split('@').first ??
              'Firebase User';
          _isLoading = false;
        });
      } else {
        // DummyJSON Login Type using getUserData()
        final user = await _userService.getUser();
        final carts = await _cartService.getCartsByUser(user.id);

        if (!mounted) return;
        setState(() {
          _isFirebaseUser = false;
          _user = user;
          _carts = carts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: CustomText(text: 'Error: $_error', fontSize: 13.sp),
      );
    }

    // Show user details depending on the LoginType()
    if (_isFirebaseUser) {
      return ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42.r,
                  backgroundColor: const Color(0xFF1E2A78),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                CustomText(
                  text: _firebaseUsername,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
                CustomText(
                  text: '(Firebase Auth User)',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _infoRow(Icons.email_outlined, 'Email', _firebaseEmail),
                Divider(height: 20.h),
                _infoRow(Icons.security, 'Auth Type', 'Firebase SDK'),
              ],
            ),
          ),
        ],
      );
    }

    // DummyJSON User Details Flow
    final user = _user!;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42.r,
                  backgroundImage: user.image.isNotEmpty
                      ? NetworkImage(user.image)
                      : null,
                  child: user.image.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                SizedBox(height: 12.h),
                CustomText(
                  text: '${user.firstName} ${user.lastName}',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
                CustomText(
                  text: '@${user.username}',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _infoRow(Icons.email_outlined, 'Email', user.email),
                Divider(height: 20.h),
                _infoRow(Icons.wc_outlined, 'Gender', user.gender),
                Divider(height: 20.h),
                _infoRow(Icons.badge_outlined, 'User ID', '#${user.id}'),
                Divider(height: 20.h),
                _infoRow(Icons.security, 'Auth Type', 'DummyJSON API'),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          CustomText(
            text: 'My Cart',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 12.h),
          _carts.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: CustomText(
                      text: 'No cart items found for this user.',
                      fontSize: 13.sp,
                    ),
                  ),
                )
              : Column(
                  children: _carts
                      .map((cart) => _cartCard(cart, isDark))
                      .toList(),
                ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.grey),
        SizedBox(width: 10.w),
        CustomText(text: label, fontSize: 13.sp, fontWeight: FontWeight.w500),
        const Spacer(),
        CustomText(text: value, fontSize: 13.sp),
      ],
    );
  }

  Widget _cartCard(Cart cart, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Cart #${cart.id}',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              CustomText(text: '${cart.totalProducts} items', fontSize: 12.sp),
            ],
          ),
          Divider(height: 16.h),
          ...cart.products.map(
            (product) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      product.thumbnail,
                      width: 40.w,
                      height: 40.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 40.w,
                        height: 40.w,
                        color: Colors.grey[200],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: CustomText(
                      text: product.title,
                      fontSize: 12.sp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CustomText(
                    text: 'x${product.quantity}',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Total',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              CustomText(
                text: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
