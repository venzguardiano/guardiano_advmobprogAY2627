import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // Checks if a Firebase Auth user or local session exists, then routes accordingly.
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    // 1. Check direct Firebase Auth session persistence
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final loggedIn = await _userService.isLoggedIn();

    // 2. If either Firebase Auth or local user service confirms a session, navigate to Home
    if (firebaseUser != null || loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/nubdexchange_logo.png',
              width: 96.w,
              height: 96.w,
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: 'NUBD Exchange',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
