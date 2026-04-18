import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';

/// Manages authentication state and exposes it to the widget tree.
/// Includes detailed logging for debugging signup issues.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserService _userService;

  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasCompletedProfile = false;
  bool _isProfileLoading = false;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;

  AuthProvider({
    AuthRepository? authRepository,
    UserService? userService,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userService = userService ?? UserService() {
    _init();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────
  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get hasCompletedProfile => _hasCompletedProfile;
  bool get isProfileLoading => _isProfileLoading;
  String get userId => _user?.uid ?? '';

  // ─── Initialization ──────────────────────────────────────────────────────
  void _init() {
    _authSub = _authRepository.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _isProfileLoading = true;
        notifyListeners(); // Notify router that we started loading

        // Listen to profile changes
        _profileSub?.cancel();
        _profileSub = _userService.userProfileStream(user.uid).listen(
          (profile) {
            _userProfile = profile;
            _hasCompletedProfile = profile?.hasCompletedProfile ?? false;
            _isProfileLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _isProfileLoading = false;
            notifyListeners();
          },
        );
      } else {
        _profileSub?.cancel();
        _userProfile = null;
        _hasCompletedProfile = false;
        _isProfileLoading = false;
        notifyListeners();
      }
    });
  }

  // ─── Sign Up ─────────────────────────────────────────────────────────────
  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    try {
      developer.log('[AuthProvider] Attempting signup for: $email');
      await _authRepository.signUp(email, password, name);
      developer.log('[AuthProvider] Signup successful');
      _setLoading(false);
      return true;
    } on AuthServiceException catch (e) {
      developer.log('[AuthProvider] AuthServiceException: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      developer.log('[AuthProvider] Unexpected error: $e', error: e);
      _setError('An unexpected error occurred.');
      _setLoading(false);
      return false;
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signIn(email, password);
      _setLoading(false);
      return true;
    } on AuthServiceException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      _setLoading(false);
      return false;
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  void clearError() => _clearError();

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
