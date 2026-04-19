import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication operations with error handling.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes for reactive UI.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs up a new user with email and password.
  /// Throws [AuthServiceException] on failure.
  Future<User> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (result.user == null) {
        throw AuthServiceException('Account creation failed. Please try again.');
      }
      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapFirebaseError(e.code));
    }
  }

  /// Signs in an existing user.
  /// Throws [AuthServiceException] on failure.
  Future<User> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (result.user == null) {
        throw AuthServiceException('Sign in failed. Please try again.');
      }
      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapFirebaseError(e.code));
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password reset email to the user.
  /// Throws [AuthServiceException] on failure.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapFirebaseError(e.code));
    }
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Custom exception for auth-related errors with user-friendly messages.
class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
