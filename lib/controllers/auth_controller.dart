import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Authentication controller
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _authStateInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get authStateInitialized => _authStateInitialized;

  AuthController() {
    _initAuthListener();
  }

  /// Listen to authentication state changes.
  /// Errors here are logged but not stored - auth state changes are passive.
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        try {
          _currentUser = await _authService.getUserData(user.uid);
        } catch (e) {
          debugPrint('Error fetching user data: $e');
          // Don't store error - this is a passive listener
        }
      } else {
        _currentUser = null;
      }
      _authStateInitialized = true;
      notifyListeners();
    });
  }

  /// Sign up a new user.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
    String? preferredLanguage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        preferredLanguage: preferredLanguage,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in an existing user.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out the current user.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile (displayName, photoUrl).
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete user profile with extended fields.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> completeUserProfile({
    required String displayName,
    required DateTime dateOfBirth,
    required String gender,
    String? phone,
    required String preferredLanguage,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Update Firestore with extended profile data
      final Map<String, dynamic> profileData = {
        'displayName': displayName,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'gender': gender,
        'phone': phone,
        'preferredLanguage': preferredLanguage,
        'profileCompleted': true,
      };

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.uid)
          .update(profileData);

      // Update Firebase Auth display name if changed
      if (displayName != _currentUser!.displayName) {
        await _authService.updateUserProfile(
          uid: _currentUser!.uid,
          displayName: displayName,
        );
      }

      // Refresh current user data
      _currentUser = await _authService.getUserData(_currentUser!.uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update preferred language.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> updatePreferredLanguage(String languageCode) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(_currentUser!.uid)
        .update({'preferredLanguage': languageCode});

    // Refresh current user data
    _currentUser = await _authService.getUserData(_currentUser!.uid);
    notifyListeners();
  }
}
