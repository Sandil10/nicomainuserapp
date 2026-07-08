import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Correct GoogleSignIn instance targeting the Web Client ID (Server Client ID)
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '965088107395-m1ib3pg8b4vqmc88argsfr1mqdvgh8fr.apps.googleusercontent.com',
  );

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Force a sign-out before starting
      await _googleSignIn.signOut();
      // Small delay to ensure state is cleared
      await Future.delayed(const Duration(milliseconds: 500));

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("Google Sign-In: User canceled the selection.");
        return null;
      }

      debugPrint("Google Sign-In: User selected - ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint("Google Sign-In: Authentication successful. Tokens received.");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: [${e.code}] ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Google Sign-In Exception Type: ${e.runtimeType}");
      debugPrint("Error during Google Sign-In: $e");
      rethrow;
    }
  }

  // Facebook Sign In
  static Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );
        return await _auth.signInWithCredential(credential);
      } else {
        debugPrint("Facebook login failed: ${loginResult.message}");
        return null;
      }
    } catch (e) {
      debugPrint("Error during Facebook Sign-In: $e");
      rethrow;
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error during sign out: $e");
    }
  }

  // Check if user is signed in
  static bool isSignedIn() => _auth.currentUser != null;

  // Get user info
  static Map<String, dynamic>? getUserInfo() {
    final user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
      };
    }
    return null;
  }

  static String getUserDisplayName() =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@')[0] ??
      'Admin User';

  static String getUserEmail() =>
      _auth.currentUser?.email ?? 'admin@example.com';

  static String? getUserPhotoURL() => _auth.currentUser?.photoURL;

  // Listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
