import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';
import '../models/medical_specialty.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'doctors';

  /// Fetch all doctors from Firestore
  Future<List<DoctorModel>> fetchAllDoctors() async {
    final querySnapshot = await _firestore.collection(_collection).get();
    return querySnapshot.docs
        .map((doc) => DoctorModel.fromMap(
              doc.data(),
              doc.id,
            ))
        .toList();
  }

  /// Fetch a single doctor by UID
  Future<DoctorModel?> fetchDoctorById(String uid) async {
    final docSnapshot = await _firestore.collection(_collection).doc(uid).get();
    if (!docSnapshot.exists) return null;

    return DoctorModel.fromMap(
      docSnapshot.data() as Map<String, dynamic>,
      docSnapshot.id,
    );
  }

  /// Stream all doctors (real-time updates)
  Stream<List<DoctorModel>> streamAllDoctors() {
    return _firestore.collection(_collection).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => DoctorModel.fromMap(
                    doc.data(),
                    doc.id,
                  ))
              .toList(),
        );
  }

  /// Stream a single doctor (real-time updates)
  Stream<DoctorModel?> streamDoctor(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return DoctorModel.fromMap(
        snapshot.data() as Map<String, dynamic>,
        snapshot.id,
      );
    });
  }

  /// Fetch doctors by specialty
  Future<List<DoctorModel>> fetchDoctorsBySpecialty(
      MedicalSpecialty specialty) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('specialty', isEqualTo: specialty.name)
        .get();

    return querySnapshot.docs
        .map((doc) => DoctorModel.fromMap(
              doc.data(),
              doc.id,
            ))
        .toList();
  }

  /// Fetch only available doctors
  Future<List<DoctorModel>> fetchAvailableDoctors() async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .get();

    final doctors = querySnapshot.docs
        .map((doc) => DoctorModel.fromMap(
              doc.data(),
              doc.id,
            ))
        .toList();

    // Filter out doctors on vacation
    return doctors.where((doctor) => doctor.isCurrentlyAvailable).toList();
  }

  /// Search doctors by name or specialty
  Future<List<DoctorModel>> searchDoctors(String query) async {
    final allDoctors = await fetchAllDoctors();
    final lowerQuery = query.toLowerCase();

    return allDoctors.where((doctor) {
      return doctor.fullName.toLowerCase().contains(lowerQuery) ||
          doctor.specialty.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter doctors by multiple criteria
  List<DoctorModel> filterDoctors(
    List<DoctorModel> doctors, {
    MedicalSpecialty? specialty,
    bool? availableOnly,
    List<String>? languages,
  }) {
    var filtered = doctors;

    if (specialty != null) {
      filtered = filtered.where((d) => d.specialty == specialty).toList();
    }

    if (availableOnly == true) {
      filtered = filtered.where((d) => d.isCurrentlyAvailable).toList();
    }

    if (languages != null && languages.isNotEmpty) {
      filtered = filtered.where((d) {
        return languages.any((lang) => d.languages.contains(lang));
      }).toList();
    }

    return filtered;
  }

  /// Update doctor profile (for doctor self-editing)
  Future<void> updateDoctorProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(uid).update(data);
  }

  /// Update doctor availability status
  Future<void> updateAvailability(String uid, bool isAvailable) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isAvailable': isAvailable,
      'lastActive': DateTime.now().toIso8601String(),
    });
  }

  /// Add vacation period for a doctor
  Future<void> addVacationPeriod(
    String uid,
    DateRange vacationPeriod,
  ) async {
    final doctor = await fetchDoctorById(uid);
    if (doctor == null) throw Exception('Doctor not found');

    final updatedVacations = [...doctor.vacationPeriods, vacationPeriod];

    await _firestore.collection(_collection).doc(uid).update({
      'vacationPeriods': updatedVacations.map((e) => e.toMap()).toList(),
    });
  }

  /// Remove vacation period for a doctor
  Future<void> removeVacationPeriod(
    String uid,
    int vacationIndex,
  ) async {
    final doctor = await fetchDoctorById(uid);
    if (doctor == null) throw Exception('Doctor not found');

    final updatedVacations = List<DateRange>.from(doctor.vacationPeriods);
    if (vacationIndex >= 0 && vacationIndex < updatedVacations.length) {
      updatedVacations.removeAt(vacationIndex);
    }

    await _firestore.collection(_collection).doc(uid).update({
      'vacationPeriods': updatedVacations.map((e) => e.toMap()).toList(),
    });
  }

  /// Create a new doctor profile (admin function)
  Future<void> createDoctorProfile(DoctorModel doctor) async {
    await _firestore.collection(_collection).doc(doctor.uid).set(doctor.toMap());
  }

  /// Delete doctor profile (admin function)
  Future<void> deleteDoctorProfile(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  /// Get doctors sorted by experience
  List<DoctorModel> sortDoctorsByExperience(
    List<DoctorModel> doctors, {
    bool descending = true,
  }) {
    final sorted = List<DoctorModel>.from(doctors);
    sorted.sort((a, b) {
      if (descending) {
        return b.experienceYears.compareTo(a.experienceYears);
      } else {
        return a.experienceYears.compareTo(b.experienceYears);
      }
    });
    return sorted;
  }

  /// Get doctors sorted by price
  List<DoctorModel> sortDoctorsByPrice(
    List<DoctorModel> doctors, {
    bool ascending = true,
  }) {
    final sorted = List<DoctorModel>.from(doctors);
    sorted.sort((a, b) {
      if (ascending) {
        return a.consultationPrice.compareTo(b.consultationPrice);
      } else {
        return b.consultationPrice.compareTo(a.consultationPrice);
      }
    });
    return sorted;
  }
}
