import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Orchestrates auth + profile creation together.
class AuthRepository {
  final AuthService _authService;
  final UserService _userService;

  AuthRepository({
    AuthService? authService,
    UserService? userService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  User? get currentUser => _authService.currentUser;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Signs up a new user and creates their Firestore profile document.
  Future<User> signUp(String email, String password, String name) async {
    developer.log('[AuthRepository] Starting signup for email: $email');
    
    final user = await _authService.signUp(email, password);
    developer.log('[AuthRepository] Firebase Auth user created: ${user.uid}');

    // Create the initial Firestore profile
    final profile = UserModel(
      uid: user.uid,
      name: name,
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
    
    developer.log('[AuthRepository] Creating Firestore profile for user: ${user.uid}');
    try {
      await _userService.createUserProfile(profile);
      developer.log('[AuthRepository] Firestore profile created successfully');
    } catch (e) {
      developer.log('[AuthRepository] ERROR creating Firestore profile: $e');
      rethrow;
    }

    return user;
  }

  /// Signs in an existing user.
  Future<User> signIn(String email, String password) async {
    developer.log('[AuthRepository] Signing in user: $email');
    return await _authService.signIn(email, password);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    developer.log('[AuthRepository] Signing out user');
    await _authService.signOut();
  }

  /// Sends a password reset email to the user.
  Future<void> sendPasswordResetEmail(String email) async {
    developer.log('[AuthRepository] Sending password reset email to: $email');
    await _authService.sendPasswordResetEmail(email);
  }

  /// Checks if the user has completed their profile setup.
  Future<bool> hasCompletedProfile(String uid) async {
    final profile = await _userService.getUserProfile(uid);
    return profile?.hasCompletedProfile ?? false;
  }
}
