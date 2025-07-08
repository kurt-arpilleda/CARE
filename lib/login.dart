import 'package:care/signup.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'dashboard.dart';
import 'google_signin_service.dart';
import 'dialog/account_type_dialog.dart';
import 'dialog/forgot_password_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _passwordHasInput = false;
  bool _isGoogleSignInLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() => _showPassword = false);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordHasInput = _passwordController.text.isNotEmpty;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (response['success'] == true) {
          await _apiService.saveAuthToken(response['token']);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Login failed')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isGoogleSignInLoading = true);

    try {
      final googleUser = await GoogleSignInService.signIn();
      if (googleUser != null) {
        try {
          // Try to login with Google first
          final loginResponse = await _apiService.loginWithGoogle(
            email: googleUser.email,
            googleId: googleUser.id,
          );

          if (loginResponse['success'] == true) {
            // User exists, proceed with login
            await _apiService.saveAuthToken(loginResponse['token']);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            }
          } else if (loginResponse['message'] == 'Google account not found') {
            // User doesn't exist, show account type dialog and create account
            final userType = await showAccountTypeDialog(context);
            if (userType != null) {
              String firstName = '';
              String surName = '';

              if (googleUser.displayName != null) {
                final names = googleUser.displayName!.split(' ');
                firstName = names.isNotEmpty ? names[0] : '';
                surName = names.length > 1 ? names.sublist(1).join(' ') : '';
              }

              final signupResponse = await _apiService.signUpWithGoogle(
                firstName: firstName,
                surName: surName,
                email: googleUser.email,
                googleId: googleUser.id,
                userType: userType,
                photoUrl: googleUser.photoUrl ?? '',
              );

              if (signupResponse['success'] == true) {
                // After successful signup, login
                final newLoginResponse = await _apiService.loginWithGoogle(
                  email: googleUser.email,
                  googleId: googleUser.id,
                );

                if (newLoginResponse['success'] == true) {
                  await _apiService.saveAuthToken(newLoginResponse['token']);
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  }
                } else {
                  Fluttertoast.showToast(msg: 'Login failed after signup');
                }
              } else {
                Fluttertoast.showToast(msg: signupResponse['message'] ?? 'Google signup failed');
              }
            }
          } else {
            Fluttertoast.showToast(msg: loginResponse['message'] ?? 'Google sign-in failed');
          }
        } catch (e) {
          Fluttertoast.showToast(msg: 'Google sign-in failed: ${e.toString()}');
        } finally {
          await GoogleSignInService.signOut();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Google sign-in failed: ${e.toString()}');
      await GoogleSignInService.signOut();
      await _apiService.logout();
      await _apiService.clearAuthToken();
    } finally {
      if (mounted) {
        setState(() => _isGoogleSignInLoading = false);
      }
    }
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
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/icon.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'LOG IN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 35,
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
                      'Please sign in to continue',
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
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      style: const TextStyle(
                          fontFamily: 'Lato-Italic',
                          fontWeight: FontWeight.w500
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Email or Phone Number',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email or phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      style: const TextStyle(
                          fontFamily: 'Lato-Italic',
                          fontWeight: FontWeight.w500
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: _passwordFocusNode.hasFocus && _passwordHasInput
                            ? IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ForgotPasswordDialog(),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3D63),
                        foregroundColor: const Color(0xFFF6FAFD),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'SIGN IN',
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
                      onPressed: _isGoogleSignInLoading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isGoogleSignInLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text('Sign in with Google'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            'Sign Up',
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