import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream de cambios en el usuario
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Sign in con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('ℹ️ User cancelled Google Sign-In');
        return null; // User cancelled
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Signed in: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('❌ Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  // Check if user is signed in
  bool isSignedIn() {
    return currentUser != null;
  }

  // Get user ID
  String? getUserId() {
    return currentUser?.uid;
  }

  // Get user email
  String? getUserEmail() {
    return currentUser?.email;
  }

  // Get user display name
  String? getUserDisplayName() {
    return currentUser?.displayName;
  }

  // Get user photo URL
  String? getUserPhotoUrl() {
    return currentUser?.photoURL;
  }
}
