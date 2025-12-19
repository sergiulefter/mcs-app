import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth? _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  /// Parse DateTime from various formats (String, Timestamp, or null)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  // Get current user
  User? get currentUser => _authInstance.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _authInstance.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? displayName,
    String? preferredLanguage,
  }) async {
    // Create user in Firebase Auth
    UserCredential userCredential =
        await _authInstance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user == null) return null;

    // Update display name if provided
    if (displayName != null) {
      await user.updateDisplayName(displayName);
      await user.reload();
      user = _authInstance.currentUser;
    }

    // Create user document in Firestore with preferred language
    UserModel userModel = UserModel(
      uid: user!.uid,
      email: user.email ?? email,
      displayName: displayName,
      photoUrl: null,
      createdAt: DateTime.now(),
      preferredLanguage: preferredLanguage ?? 'en',
    );

    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(userModel.toMap());

    return userModel;
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await _authInstance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user == null) return null;

    // First check if user exists in 'users' collection
    DocumentSnapshot userDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
    }

    // Check if user exists in 'doctors' collection
    DocumentSnapshot doctorDoc = await _firestore
        .collection(AppConstants.collectionDoctors)
        .doc(user.uid)
        .get();

    if (doctorDoc.exists) {
      // Create a UserModel from doctor data with isDoctor flag
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      return UserModel(
        uid: user.uid,
        email: doctorData['email'] ?? user.email ?? '',
        displayName: doctorData['fullName'],
        photoUrl: doctorData['photoUrl'],
        createdAt: _parseDateTime(doctorData['createdAt']) ?? DateTime.now(),
        isDoctor: true,
      );
    }

    // If user document doesn't exist in either collection, create one in 'users'
    UserModel userModel = UserModel.fromFirebaseUser(user);
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(userModel.toMap());
    return userModel;
  }

  // Sign out
  Future<void> signOut() async {
    await _authInstance.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _authInstance.sendPasswordResetEmail(email: email);
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    // First check 'users' collection
    DocumentSnapshot userDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .get();
    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, uid);
    }

    // Check 'doctors' collection
    DocumentSnapshot doctorDoc = await _firestore
        .collection(AppConstants.collectionDoctors)
        .doc(uid)
        .get();
    if (doctorDoc.exists) {
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      return UserModel(
        uid: uid,
        email: doctorData['email'] ?? '',
        displayName: doctorData['fullName'],
        photoUrl: doctorData['photoUrl'],
        createdAt: _parseDateTime(doctorData['createdAt']) ?? DateTime.now(),
        isDoctor: true,
      );
    }

    return null;
  }

  // Update user profile
  Future<UserModel?> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    User? user = _authInstance.currentUser;
    if (user == null) throw Exception('No user logged in');

    Map<String, dynamic> updates = {};

    // Update Firebase Auth profile if displayName is provided
    if (displayName != null && displayName != user.displayName) {
      await user.updateDisplayName(displayName);
      updates['displayName'] = displayName;
    }

    // Update Firebase Auth photo URL if provided
    if (photoUrl != null && photoUrl != user.photoURL) {
      await user.updatePhotoURL(photoUrl);
      updates['photoUrl'] = photoUrl;
    }

    // Reload Firebase Auth user to get updated info
    await user.reload();
    user = _authInstance.currentUser;

    // Update Firestore document if there are changes
    if (updates.isNotEmpty) {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .update(updates);
    }

    // Fetch and return updated user data
    return await getUserData(uid);
  }
}
