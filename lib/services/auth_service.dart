import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../utils/constants.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth? _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

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
    final UserCredential userCredential = await _authInstance
        .createUserWithEmailAndPassword(email: email, password: password);

    User? user = userCredential.user;
    if (user == null) return null;

    // Update display name if provided
    if (displayName != null) {
      await user.updateDisplayName(displayName);
      await user.reload();
      user = _authInstance.currentUser;
    }

    // Create user document in Firestore with preferred language
    final UserModel userModel = UserModel(
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
  // expectedRole: 'patient' or 'doctor' - validates user exists in correct collection
  Future<UserModel?> signIn({
    required String email,
    required String password,
    String? expectedRole,
  }) async {
    final UserCredential userCredential = await _authInstance
        .signInWithEmailAndPassword(email: email, password: password);

    final User? user = userCredential.user;
    if (user == null) return null;

    // Check if user exists in 'users' collection (patients)
    final DocumentSnapshot userDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .get();

    // Check if user exists in 'doctors' collection
    final DocumentSnapshot doctorDoc = await _firestore
        .collection(AppConstants.collectionDoctors)
        .doc(user.uid)
        .get();

    // Validate role if expectedRole is specified
    if (expectedRole == 'patient') {
      if (!userDoc.exists) {
        // User tried to log in as patient but doesn't exist in users collection
        await _authInstance.signOut();
        throw Exception(
          'This account is not registered as a patient. Please select "Doctor" to log in.',
        );
      }
      return UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        user.uid,
      );
    } else if (expectedRole == 'doctor') {
      if (!doctorDoc.exists) {
        // User tried to log in as doctor but doesn't exist in doctors collection
        await _authInstance.signOut();
        throw Exception(
          'This account is not registered as a doctor. Please select "Patient" to log in.',
        );
      }
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      final doctorModel = DoctorModel.fromMap(doctorData, user.uid);
      return doctorModel.toUserModel();
    }

    // No expectedRole specified - use original behavior
    if (userDoc.exists) {
      return UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        user.uid,
      );
    }

    if (doctorDoc.exists) {
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      final doctorModel = DoctorModel.fromMap(doctorData, user.uid);
      return doctorModel.toUserModel();
    }

    // If user document doesn't exist in either collection, create one in 'users'
    final UserModel userModel = UserModel.fromFirebaseUser(user);
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
    final DocumentSnapshot userDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .get();
    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, uid);
    }

    // Check 'doctors' collection
    final DocumentSnapshot doctorDoc = await _firestore
        .collection(AppConstants.collectionDoctors)
        .doc(uid)
        .get();
    if (doctorDoc.exists) {
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      final doctorModel = DoctorModel.fromMap(doctorData, uid);
      return doctorModel.toUserModel();
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

    final Map<String, dynamic> updates = {};

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
