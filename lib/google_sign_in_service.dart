import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Sign in with Google
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      // Attempt to sign in
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Check if already signed in
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.signInSilently();
  }

  // Get user data for signup
  static Map<String, dynamic> extractUserData(GoogleSignInAccount account) {
    // Split display name into first and last name
    List<String> nameParts = account.displayName?.split(' ') ?? ['', ''];
    String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return {
      'firstName': firstName,
      'surName': lastName,
      'email': account.email,
      'googleId': account.id,
      'photoUrl': account.photoUrl,
    };
  }
}
