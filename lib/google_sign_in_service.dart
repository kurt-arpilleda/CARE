import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<Map<String, String>?> getGoogleUserData() async {
    final account = await _googleSignIn.signInSilently();
    if (account != null) {
      return {
        'id': account.id,
        'email': account.email,
        'displayName': account.displayName ?? '',
        'photoUrl': account.photoUrl ?? '',
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> signUpWithGoogle(BuildContext context) async {
    try {
      // Show account type selection dialog first
      String? accountType = await _showAccountTypeDialog(context);
      if (accountType == null) return null;

      // Show gender selection dialog
      String? gender = await _showGenderDialog(context);
      if (gender == null) return null;

      // Proceed with Google Sign-In
      final GoogleSignInAccount? googleAccount = await signIn();
      if (googleAccount == null) return null;

      // Extract user data
      final displayName = googleAccount.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final surName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Call API to signup with Google
      final ApiService apiService = ApiService();
      final response = await apiService.googleSignUp(
        firstName: firstName,
        surName: surName,
        gender: gender == 'Male' ? 0 : 1,
        email: googleAccount.email,
        phoneNum: '', // Google doesn't provide phone number
        userType: accountType == 'Driver' ? 0 : 1,
        googleId: googleAccount.id,
        photoUrl: googleAccount.photoUrl ?? '',
      );

      return response;
    } catch (error) {
      print('Google Sign-Up Error: $error');
      return null;
    }
  }

  static Future<String?> _showAccountTypeDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Account Type'),
          content: const Text('Please choose your account type:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('Driver'),
              child: const Text('Driver'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('Shop Owner'),
              child: const Text('Shop Owner'),
            ),
          ],
        );
      },
    );
  }

  static Future<String?> _showGenderDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          content: const Text('Please choose your gender:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('Male'),
              child: const Text('Male'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('Female'),
              child: const Text('Female'),
            ),
          ],
        );
      },
    );
  }
}