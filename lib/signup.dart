import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'google_signin_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _firstNameController = TextEditingController();
  final _surNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _gender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Set<String> _touchedFields = {};

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final validCharacters = RegExp(r"^[a-zA-Z .,'-]+$");
    if (!validCharacters.hasMatch(value)) {
      return 'Only letters, spaces, and .,-\' are allowed';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleanedPhone = value.replaceAll(RegExp(r'[^0-9]'), '');

    final phoneRegex = RegExp(r'^09\d{9}$');
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      return 'Enter a valid 11-digit phone number starting with 09';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    final passwordRegex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must include uppercase, lowercase, number, and special character';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submitForm() async {
    setState(() {
      _touchedFields.addAll([
        'firstName',
        'surName',
        'email',
        'phone',
        'password',
        'confirmPassword',
        'accountType',
        'gender',
      ]);
    });
    if (!_touchedFields.contains('password') && _passwordController.text.isNotEmpty) {
      _touchedFields.add('password');
    }
    if (!_touchedFields.contains('confirmPassword') && _confirmPasswordController.text.isNotEmpty) {
      _touchedFields.add('confirmPassword');
    }

    bool isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }
    if (_gender == null) {
      Fluttertoast.showToast(msg: 'Please select gender');
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(msg: 'Passwords do not match');
      return;
    }

    try {
      final response = await _apiService.signUp(
        firstName: _firstNameController.text,
        surName: _surNameController.text,
        gender: _gender == 'Male' ? 0 : 1,
        email: _emailController.text,
        phoneNum: _phoneController.text,
        password: _passwordController.text,
        signupType: 0, // Manual signup
      );

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Signup successful');
        Navigator.pop(context);
      } else {
        if (response['message']?.contains('Email already exists') ?? false) {
          Fluttertoast.showToast(msg: 'This email is already registered');
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? 'Signup failed');
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF6FAFD),
                Color(0xFF1A3D63),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/icon.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'SIGN UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 3.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: Color(0xFFF6FAFD),
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _firstNameController,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(
                                    fontFamily: 'Lato-Italic',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.9),
                                    hintText: 'First Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorText: _touchedFields.contains('firstName')
                                        ? _validateName(_firstNameController.text, 'First name')
                                        : null,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _touchedFields.add('firstName');
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _surNameController,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(
                                    fontFamily: 'Lato-Italic',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.9),
                                    hintText: 'Surname',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorText: _touchedFields.contains('surName')
                                        ? _validateName(_surNameController.text, 'Surname')
                                        : null,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _touchedFields.add('surName');
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _touchedFields.contains('gender') && _gender == null
                            ? 'Gender is required'
                            : null,
                      ),
                      value: _gender,
                      style: const TextStyle(
                        fontFamily: 'Lato-Italic',
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      items: ['Male', 'Female'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                          _touchedFields.add('gender');
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(
                        fontFamily: 'Lato-Italic',
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _touchedFields.contains('email')
                            ? _validateEmail(_emailController.text)
                            : null,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          _touchedFields.add('email');
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(
                        fontFamily: 'Lato-Italic',
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Mobile Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _touchedFields.contains('phone')
                            ? _validatePhone(_phoneController.text)
                            : null,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        setState(() {
                          _touchedFields.add('phone');
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontFamily: 'Lato-Italic',
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _passwordController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        )
                            : null,
                        errorText: (_touchedFields.contains('password') || _passwordController.text.isNotEmpty)
                            ? _validatePassword(_passwordController.text)
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _touchedFields.add('password');
                          // Also validate confirm password when password changes
                          _touchedFields.add('confirmPassword');
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        fontFamily: 'Lato-Italic',
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _confirmPasswordController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        )
                            : null,
                        errorText: (_touchedFields.contains('confirmPassword') || _confirmPasswordController.text.isNotEmpty)
                            ? _validateConfirmPassword(_confirmPasswordController.text)
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _touchedFields.add('confirmPassword');
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3D63),
                        foregroundColor: const Color(0xFFF6FAFD),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white70)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          final googleUser = await GoogleSignInService.signIn();
                          if (googleUser != null) {
                            try {
                              String firstName = '';
                              String surName = '';

                              if (googleUser.displayName != null) {
                                final names = googleUser.displayName!.split(' ');
                                firstName = names.isNotEmpty ? names[0] : '';
                                surName = names.length > 1 ? names.sublist(1).join(' ') : '';
                              }

                              final response = await _apiService.signUpWithGoogle(
                                firstName: firstName,
                                surName: surName,
                                email: googleUser.email,
                                googleId: googleUser.id,
                                photoUrl: googleUser.photoUrl ?? '',
                              );

                              if (response['success'] == true) {
                                Fluttertoast.showToast(msg: 'Google signup successful');
                                Navigator.pop(context);
                              } else {
                                await GoogleSignInService.signOut();
                                Fluttertoast.showToast(msg: response['message'] ?? 'Google signup failed');
                              }
                            } catch (e) {
                              Fluttertoast.showToast(msg: 'Google sign-up failed: ${e.toString()}');
                            } finally {
                              await GoogleSignInService.signOut();
                            }
                          }
                        } catch (e) {
                          Fluttertoast.showToast(msg: 'Google sign-in failed: ${e.toString()}');
                          await GoogleSignInService.signOut();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text('Sign up with Google'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}