import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';
import 'doctor_service.dart';

/// Service for admin-specific operations
class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DoctorService _doctorService = DoctorService();

  /// Create a new doctor account with Firebase Auth and Firestore documents
  ///
  /// This method:
  /// 1. Creates a Firebase Auth user with the provided email/password
  /// 2. Re-authenticates as admin (since createUserWithEmailAndPassword switches context)
  /// 3. Creates a doctor profile in the 'doctors' collection ONLY
  ///
  /// Note: Doctors are stored ONLY in the 'doctors' collection.
  /// The 'users' collection is for patients and admins only.
  /// Doctor identity is determined by presence in 'doctors' collection at sign-in.
  ///
  /// Requires admin credentials to re-authenticate after creating the doctor's auth account.
  ///
  /// Returns the UID of the created doctor
  /// Throws an exception if any step fails
  Future<String> createDoctorWithAuth({
    required String email,
    required String password,
    required DoctorModel doctorData,
    required String adminEmail,
    required String adminPassword,
  }) async {
    String? uid;

    try {
      // 1. Create Firebase Auth account for the doctor
      // NOTE: This automatically signs in as the new doctor!
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      uid = credential.user!.uid;

      // 2. CRITICAL: Sign back in as admin before writing to Firestore
      // This is required because createUserWithEmailAndPassword switches auth context
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      // 3. Create doctor profile ONLY (no user document - doctors are not in 'users' collection)
      final doctor = doctorData.copyWith(
        uid: uid,
        email: email,
        isAvailable: false,
      );
      await _doctorService.createDoctorProfile(doctor);

      return uid;
    } catch (e) {
      // If we created the auth account but failed on Firestore, try to clean up
      // Note: We may not be able to delete the auth account without admin SDK
      rethrow;
    }
  }

  /// Check if the current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data();
    return data?['userType'] == 'admin';
  }

  /// Get the user type of a user by UID
  Future<String?> getUserType(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data();
    return data?['userType'] as String?;
  }
}
