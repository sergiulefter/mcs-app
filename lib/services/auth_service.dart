import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? displayName,
    String? preferredLanguage,
  }) async {
    // Create user in Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user == null) return null;

    // Update display name if provided
    if (displayName != null) {
      await user.updateDisplayName(displayName);
      await user.reload();
      user = _auth.currentUser;
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

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

    return userModel;
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user == null) return null;

    // Get user data from Firestore
    DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
    } else {
      // If user document doesn't exist, create one
      UserModel userModel = UserModel.fromFirebaseUser(user);
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      return userModel;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    }
    return null;
  }

  // Update user profile
  Future<UserModel?> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    User? user = _auth.currentUser;
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
    user = _auth.currentUser;

    // Update Firestore document if there are changes
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }

    // Fetch and return updated user data
    return await getUserData(uid);
  }
}
