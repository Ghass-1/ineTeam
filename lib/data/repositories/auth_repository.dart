import 'package:firebase_auth/firebase_auth.dart';
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
    final user = await _authService.signUp(email, password);

    // Create the initial Firestore profile
    final profile = UserModel(
      uid: user.uid,
      name: name,
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
    await _userService.createUserProfile(profile);

    return user;
  }

  /// Signs in an existing user.
  Future<User> signIn(String email, String password) async {
    return await _authService.signIn(email, password);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Checks if the user has completed their profile setup.
  Future<bool> hasCompletedProfile(String uid) async {
    final profile = await _userService.getUserProfile(uid);
    return profile?.hasCompletedProfile ?? false;
  }
}
