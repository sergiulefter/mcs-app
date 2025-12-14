import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Service for admin-specific operations.
///
/// This service uses Cloud Functions for privileged operations like
/// creating/deleting users and doctors, which require Firebase Admin SDK.
class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  // ============================================
  // CLOUD FUNCTION - DOCTOR CREATION
  // ============================================

  /// Create a new doctor account using Cloud Function.
  ///
  /// This method calls the `createDoctor` Cloud Function which:
  /// 1. Creates a Firebase Auth account for the doctor
  /// 2. Creates a Firestore document in the 'doctors' collection
  ///
  /// Note: Doctors are stored ONLY in the 'doctors' collection.
  /// The 'users' collection is for patients and admins only.
  ///
  /// Returns the UID of the created doctor
  /// Throws a [FirebaseFunctionsException] if the operation fails
  Future<String> createDoctor({
    required String email,
    required String password,
    required DoctorModel doctorData,
  }) async {
    final callable = _functions.httpsCallable('createDoctor');

    final result = await callable.call<Map<String, dynamic>>({
      'email': email,
      'password': password,
      'doctorData': {
        'fullName': doctorData.fullName,
        'specialty': doctorData.specialty.name,
        'subspecialties': doctorData.subspecialties,
        'experienceYears': doctorData.experienceYears,
        'consultationPrice': doctorData.consultationPrice,
        'languages': doctorData.languages,
        'bio': doctorData.bio,
        'education': doctorData.education
            .map((e) => {
                  'institution': e.institution,
                  'degree': e.degree,
                  'year': e.year,
                })
            .toList(),
      },
    });

    return result.data['uid'] as String;
  }

  // ============================================
  // CLOUD FUNCTION - USER/DOCTOR DELETION
  // ============================================

  /// Delete a user (patient) using Cloud Function.
  ///
  /// This method calls the `deleteUser` Cloud Function which:
  /// 1. Deletes the Firebase Auth account
  /// 2. Deletes the Firestore user document
  ///
  /// Throws a [FirebaseFunctionsException] if the operation fails
  Future<void> deleteUser(String uid) async {
    final callable = _functions.httpsCallable('deleteUser');
    await callable.call<Map<String, dynamic>>({'userId': uid});
  }

  /// Delete a doctor using Cloud Function.
  ///
  /// This method calls the `deleteDoctor` Cloud Function which:
  /// 1. Deletes the Firebase Auth account
  /// 2. Deletes the Firestore doctor document
  ///
  /// Note: Consultations are NOT deleted - they remain with the original
  /// doctorId reference. The app should handle displaying these appropriately.
  ///
  /// Throws a [FirebaseFunctionsException] if the operation fails
  Future<void> deleteDoctor(String uid) async {
    final callable = _functions.httpsCallable('deleteDoctor');
    await callable.call<Map<String, dynamic>>({'doctorId': uid});
  }

  // ============================================
  // CLOUD FUNCTION - ADMIN MANAGEMENT
  // ============================================

  /// Set admin custom claim on a user using Cloud Function.
  ///
  /// This method calls the `setAdminClaim` Cloud Function which sets
  /// the isAdmin custom claim on the target user's Firebase Auth token.
  ///
  /// The target user will need to re-authenticate (or refresh their token)
  /// for the claim to take effect.
  ///
  /// Throws a [FirebaseFunctionsException] if the operation fails
  Future<void> setAdminClaim({
    required String targetUserId,
    required bool isAdmin,
  }) async {
    final callable = _functions.httpsCallable('setAdminClaim');
    await callable.call<Map<String, dynamic>>({
      'targetUserId': targetUserId,
      'isAdmin': isAdmin,
    });
  }

  /// Bootstrap the first admin user using Cloud Function.
  ///
  /// This method should only be used ONCE to set up the first admin.
  /// It requires a secret key that must be configured in Firebase Functions.
  ///
  /// After the first admin is created, use [setAdminClaim] to add more admins.
  ///
  /// Throws a [FirebaseFunctionsException] if:
  /// - The secret key is invalid
  /// - An admin already exists
  /// - The target user doesn't exist
  Future<void> bootstrapAdmin({
    required String secretKey,
    required String targetUserId,
  }) async {
    final callable = _functions.httpsCallable('bootstrapAdmin');
    await callable.call<Map<String, dynamic>>({
      'secretKey': secretKey,
      'targetUserId': targetUserId,
    });
  }

  // ============================================
  // LOCAL OPERATIONS (No Cloud Function needed)
  // ============================================

  /// Check if the current user is an admin.
  ///
  /// This checks the Firestore user document for userType == 'admin'.
  /// Note: For security-critical operations, the Cloud Functions also
  /// verify the isAdmin custom claim on the auth token.
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

  /// Update a doctor's profile.
  ///
  /// This is a direct Firestore update, protected by Firestore security rules.
  /// Only admins (verified by custom claim) can update doctor profiles.
  Future<void> updateDoctor(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.collectionDoctors)
        .doc(uid)
        .update(data);
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

  // ============================================
  // DEPRECATED METHODS (Kept for backwards compatibility)
  // ============================================

  /// @deprecated Use [createDoctor] instead.
  /// This method is kept for backwards compatibility but should not be used.
  @Deprecated('Use createDoctor() instead - no admin password required')
  Future<String> createDoctorWithAuth({
    required String email,
    required String password,
    required DoctorModel doctorData,
    required String adminEmail,
    required String adminPassword,
  }) async {
    // Simply delegate to the new method, ignoring admin credentials
    return createDoctor(
      email: email,
      password: password,
      doctorData: doctorData,
    );
  }
}
