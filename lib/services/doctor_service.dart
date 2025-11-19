import '../models/doctor_model.dart';
import '../models/medical_specialty.dart';
import 'firebase_service.dart';

class DoctorService {
  final FirebaseService _firebaseService = FirebaseService();
  static const String _collection = 'doctors';

  /// Fetch all doctors from Firestore
  Future<List<DoctorModel>> fetchAllDoctors() async {
    try {
      final querySnapshot = await _firebaseService.getAllDocuments(_collection);
      return querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Error fetching doctors: $e';
    }
  }

  /// Fetch a single doctor by UID
  Future<DoctorModel?> fetchDoctorById(String uid) async {
    try {
      final docSnapshot = await _firebaseService.getDocumentById(_collection, uid);
      if (!docSnapshot.exists) return null;

      return DoctorModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw 'Error fetching doctor: $e';
    }
  }

  /// Stream all doctors (real-time updates)
  Stream<List<DoctorModel>> streamAllDoctors() {
    return _firebaseService.streamCollection(_collection).map(
          (snapshot) => snapshot.docs
              .map((doc) => DoctorModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList(),
        );
  }

  /// Stream a single doctor (real-time updates)
  Stream<DoctorModel?> streamDoctor(String uid) {
    return _firebaseService.streamDocument(_collection, uid).map((snapshot) {
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
    try {
      final querySnapshot = await _firebaseService.queryDocuments(
        _collection,
        field: 'specialty',
        isEqualTo: specialty.name,
      );

      return querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Error fetching doctors by specialty: $e';
    }
  }

  /// Fetch only available doctors
  Future<List<DoctorModel>> fetchAvailableDoctors() async {
    try {
      final querySnapshot = await _firebaseService.queryDocuments(
        _collection,
        field: 'isAvailable',
        isEqualTo: true,
      );

      final doctors = querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Filter out doctors on vacation
      return doctors.where((doctor) => doctor.isCurrentlyAvailable).toList();
    } catch (e) {
      throw 'Error fetching available doctors: $e';
    }
  }

  /// Search doctors by name or specialty
  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      final allDoctors = await fetchAllDoctors();
      final lowerQuery = query.toLowerCase();

      return allDoctors.where((doctor) {
        return doctor.fullName.toLowerCase().contains(lowerQuery) ||
            doctor.specialty.name.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw 'Error searching doctors: $e';
    }
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
    try {
      await _firebaseService.updateDocument(_collection, uid, data);
    } catch (e) {
      throw 'Error updating doctor profile: $e';
    }
  }

  /// Update doctor availability status
  Future<void> updateAvailability(String uid, bool isAvailable) async {
    try {
      await _firebaseService.updateDocument(_collection, uid, {
        'isAvailable': isAvailable,
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Error updating availability: $e';
    }
  }

  /// Add vacation period for a doctor
  Future<void> addVacationPeriod(
    String uid,
    DateRange vacationPeriod,
  ) async {
    try {
      final doctor = await fetchDoctorById(uid);
      if (doctor == null) throw 'Doctor not found';

      final updatedVacations = [...doctor.vacationPeriods, vacationPeriod];

      await _firebaseService.updateDocument(_collection, uid, {
        'vacationPeriods': updatedVacations.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      throw 'Error adding vacation period: $e';
    }
  }

  /// Remove vacation period for a doctor
  Future<void> removeVacationPeriod(
    String uid,
    int vacationIndex,
  ) async {
    try {
      final doctor = await fetchDoctorById(uid);
      if (doctor == null) throw 'Doctor not found';

      final updatedVacations = List<DateRange>.from(doctor.vacationPeriods);
      if (vacationIndex >= 0 && vacationIndex < updatedVacations.length) {
        updatedVacations.removeAt(vacationIndex);
      }

      await _firebaseService.updateDocument(_collection, uid, {
        'vacationPeriods': updatedVacations.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      throw 'Error removing vacation period: $e';
    }
  }

  /// Create a new doctor profile (admin function)
  Future<void> createDoctorProfile(DoctorModel doctor) async {
    try {
      await _firebaseService.setDocument(
        _collection,
        doctor.uid,
        doctor.toMap(),
      );
    } catch (e) {
      throw 'Error creating doctor profile: $e';
    }
  }

  /// Delete doctor profile (admin function)
  Future<void> deleteDoctorProfile(String uid) async {
    try {
      await _firebaseService.deleteDocument(_collection, uid);
    } catch (e) {
      throw 'Error deleting doctor profile: $e';
    }
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
