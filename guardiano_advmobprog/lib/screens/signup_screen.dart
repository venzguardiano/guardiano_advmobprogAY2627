import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();

  // Set default auth mode to Firebase SDK
  bool _isFirebase = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isFirebase) {
          // Register user in Firebase Auth and create Firestore Users document
          await _userService.createAccount(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _fNameController.text.trim(),
            lastName: _lNameController.text.trim(),
          );

          await _userService.updateUsername(
            username: _usernameController.text.trim(),
          );

          await _userService.logout();
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFirebase
                  ? 'Firebase Account created successfully! Please sign in.'
                  : 'DummyJSON user simulated successfully! Please sign in.',
            ),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E2A78)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: 'Create Account',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: 'Sign up to get started',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 24.h),

                  // Segmented toggle
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

                  // First Name
                  TextFormField(
                    controller: _fNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required.';
                      }
                      if (value.trim().length < 2) {
                        return 'First name must be at least 2 characters long.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Last Name
                  TextFormField(
                    controller: _lNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required.';
                      }
                      if (value.trim().length < 2) {
                        return 'Last name must be at least 2 characters long.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Age
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Age is required.';
                      }
                      final age = int.tryParse(value.trim());
                      if (age == null) {
                        return 'Please enter a valid numeric age.';
                      }
                      if (age < 1 || age > 120) {
                        return 'Please enter a realistic age between 1 and 120.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Contact No
                  TextFormField(
                    controller: _contactNoController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Contact number is required.';
                      }
                      if (value.trim().length < 7) {
                        return 'Please enter a valid phone number format.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required.';
                      }
                      if (value.trim().length < 4) {
                        return 'Username must be at least 4 characters long.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email address is required.';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address (e.g., user@email.com).';
                      }
                      if (value.trim().length < 6) {
                        return 'Email address is too short.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Password
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
                        return 'Password is required.';
                      }
                      if (value.length < 6) {
                        return 'Password is too short (must be at least 6 characters).';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 28.h),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
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
                              text: 'Sign Up',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
