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

  // Determines the LoginType and loads the specific logged-in user's data.
  Future<void> _loadProfile() async {
    try {
      // 1. Prioritize checking for a DummyJSON user (e.g., Emily) in local storage first.
      User? dummyUser;
      try {
        dummyUser = await _userService.getUser();
      } catch (_) {
        // If it fails, it means no DummyJSON user is saved.
      }

      if (dummyUser != null && dummyUser.username.isNotEmpty) {
        // DummyJSON API login type detected.
        final carts = await _cartService.getCartsByUser(dummyUser.id);

        if (!mounted) return;
        setState(() {
          _isFirebaseUser = false;
          _user = dummyUser;
          _carts = carts;
          _isLoading = false;
        });
      } else {
        // 2. If no DummyJSON user exists, check for an active Firebase session.
        final firebaseUser = _userService.currentUser;

        if (firebaseUser != null) {
          // Firebase Auth login type detected.
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
          // Fallback if absolutely no session is found.
          if (!mounted) return;
          setState(() {
            _error = "No active user session found.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Shows dialog to update the Firebase user's display name.
  void _showUpdateUsernameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (controller.text.trim().isEmpty) return;
                await _userService.updateUsername(
                  username: controller.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username updated successfully'),
                  ),
                );
                _loadProfile();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Shows dialog to re-authenticate and change the Firebase user's password.
  void _showChangePasswordDialog() {
    final emailController = TextEditingController();
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Confirm Email'),
            ),
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.resetPasswordFromCurrentPassword(
                  currentPassword: currentPassController.text,
                  newPassword: newPassController.text,
                  email: emailController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // Shows dialog to re-authenticate and permanently delete the Firebase account.
  void _showDeleteAccountDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is permanent. Please re-enter credentials:',
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _userService.deleteAccount(
                  email: emailController.text.trim(),
                  password: passController.text,
                );
                await _userService.logout();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

    // Displays the Firebase user profile layout with account management.
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
          SizedBox(height: 24.h),

          // Account management section for Firebase users.
          CustomText(
            text: 'Account Management',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Update Username'),
                  onTap: _showUpdateUsernameDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Displays the DummyJSON API user profile layout with cart details.
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

  // Helper widget to build consistent information rows.
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

  // Helper widget to display cart summary and items.
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
