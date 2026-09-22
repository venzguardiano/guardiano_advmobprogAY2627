import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();

  // Tracks request in progress state, password field visibility, and active auth mode.
  bool _isFirebase = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validates the form, authenticates via the selected service, then routes to home.
  void _login() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        // Clears any lingering sessions (Firebase or DummyJSON) before new login.
        await _userService.logout();

        if (_isFirebase) {
          // Firebase SDK login flow.
          await _userService.signIn(
            email: _identifierController.text.trim(),
            password: _passwordController.text,
          );

          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // DummyJSON API login flow.
          final response = await _userService.loginUser(
            _identifierController.text.trim(),
            _passwordController.text,
          );

          // Persists the logged-in user's data to SharedPreferences.
          await _userService.saveUserData(response);

          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });

          Navigator.pushReplacementNamed(context, '/home', arguments: response);
        }
      } catch (e) {
        // Surfaces the login error to the user via a SnackBar.
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30.h),
                  Image.asset(
                    'assets/images/nubdexchange_logo.png',
                    width: 72.w,
                    height: 72.w,
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Welcome',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: 'Sign in to continue',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 24.h),

                  // Auth mode segmented toggle.
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFirebase = false;
                                _identifierController.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: !_isFirebase
                                    ? const Color(0xFF1E2A78)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: Text(
                                  'DummyJSON API',
                                  style: TextStyle(
                                    color: !_isFirebase
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFirebase = true;
                                _identifierController.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: _isFirebase
                                    ? const Color(0xFF1E2A78)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: Text(
                                  'Firebase SDK',
                                  style: TextStyle(
                                    color: _isFirebase
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Username or Email input depending on active auth mode.
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: _isFirebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _isFirebase ? 'Email Address' : 'Username',
                      prefixIcon: Icon(
                        _isFirebase
                            ? Icons.email_outlined
                            : Icons.person_outline,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _isFirebase
                            ? 'Email is required'
                            : 'Username is required';
                      }
                      if (_isFirebase &&
                          (!value.contains('@') || !value.contains('.'))) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Password input with a show/hide toggle.
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 28.h),

                  // Login button, disabled with a spinner while loading.
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2A78),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : CustomText(
                              text: 'Log In',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Navigation button to Signup Screen.
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const CustomText(
                      text: "Don't have an account? Sign Up",
                      color: Color(0xFF1E2A78),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
