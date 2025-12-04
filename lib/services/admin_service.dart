import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
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

    final userDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return false;

    final data = userDoc.data();
    return data?['userType'] == 'admin';
  }

  /// Get the user type of a user by UID
  Future<String?> getUserType(String uid) async {
    final userDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .get();
    if (!userDoc.exists) return null;

    final data = userDoc.data();
    return data?['userType'] as String?;
  }

  // ============================================
  // STATISTICS METHODS
  // ============================================

  /// Get dashboard statistics for admin panel
  /// Returns a map with counts for patients, doctors, consultations, etc.
  Future<Map<String, int>> getStatistics() async {
    // Fetch all counts in parallel for better performance
    final results = await Future.wait([
      _getPatientCount(),
      _getDoctorCount(),
      _getConsultationCounts(),
    ]);

    final patientCount = results[0] as int;
    final doctorCount = results[1] as int;
    final consultationCounts = results[2] as Map<String, int>;

    return {
      'totalPatients': patientCount,
      'totalDoctors': doctorCount,
      'totalConsultations': consultationCounts['total'] ?? 0,
      'pendingConsultations': consultationCounts['pending'] ?? 0,
      'inReviewConsultations': consultationCounts['in_review'] ?? 0,
      'completedConsultations': consultationCounts['completed'] ?? 0,
    };
  }

  Future<int> _getPatientCount() async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionUsers)
        .where('userType', isEqualTo: 'patient')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getDoctorCount() async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionDoctors)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, int>> _getConsultationCounts() async {
    // Get total count
    final totalSnapshot = await _firestore
        .collection(AppConstants.collectionConsultations)
        .count()
        .get();

    // Get pending count
    final pendingSnapshot = await _firestore
        .collection(AppConstants.collectionConsultations)
        .where('status', isEqualTo: AppConstants.statusPending)
        .count()
        .get();

    // Get in_review count
    final inReviewSnapshot = await _firestore
        .collection(AppConstants.collectionConsultations)
        .where('status', isEqualTo: AppConstants.statusInReview)
        .count()
        .get();

    // Get completed count
    final completedSnapshot = await _firestore
        .collection(AppConstants.collectionConsultations)
        .where('status', isEqualTo: AppConstants.statusCompleted)
        .count()
        .get();

    return {
      'total': totalSnapshot.count ?? 0,
      'pending': pendingSnapshot.count ?? 0,
      'in_review': inReviewSnapshot.count ?? 0,
      'completed': completedSnapshot.count ?? 0,
    };
  }

  // ============================================
  // USER MANAGEMENT METHODS
  // ============================================

  /// Fetch all patients (users with userType == 'patient')
  Future<List<UserModel>> fetchAllPatients() async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionUsers)
        .where('userType', isEqualTo: 'patient')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Delete a user (patient) - hard delete from Firestore
  /// Note: Firebase Auth account deletion requires Admin SDK or Cloud Function
  /// For MVP, we delete the Firestore document only
  Future<void> deleteUser(String uid) async {
    // Delete user document from Firestore
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .delete();

    // Note: To fully delete the user, you would need:
    // 1. A Cloud Function with Admin SDK to delete from Firebase Auth
    // 2. Or disable the user via custom claims
    // For MVP, the Firestore doc deletion is sufficient
  }

  // ============================================
  // DOCTOR MANAGEMENT METHODS
  // ============================================

  /// Update a doctor's profile
  Future<void> updateDoctor(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.collectionDoctors)
        .doc(uid)
        .update(data);
  }

  /// Delete a doctor - hard delete from Firestore
  /// Note: Firebase Auth account deletion requires Admin SDK or Cloud Function
  Future<void> deleteDoctor(String uid) async {
    // Delete doctor document from Firestore
    await _firestore
        .collection(AppConstants.collectionDoctors)
        .doc(uid)
        .delete();

    // Note: To fully delete the doctor, you would need:
    // 1. A Cloud Function with Admin SDK to delete from Firebase Auth
    // 2. Consider also deleting/anonymizing their consultations
    // For MVP, the Firestore doc deletion is sufficient
  }
}
