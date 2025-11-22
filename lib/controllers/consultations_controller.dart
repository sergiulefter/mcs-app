import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';

class ConsultationsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ConsultationModel> _consultations = [];
  bool _isLoading = false;
  String? _error;
  String _selectedStatus = 'all'; // 'all' | 'pending' | 'in_review' | 'completed' | 'cancelled'

  List<ConsultationModel> get consultations => _consultations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;

  // Get filtered consultations based on selected status
  List<ConsultationModel> get filteredConsultations {
    if (_selectedStatus == 'all') {
      return _consultations;
    }
    return _consultations
        .where((consultation) => consultation.status == _selectedStatus)
        .toList();
  }

  // Fetch consultations for a specific user
  Future<void> fetchUserConsultations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _consultations = querySnapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();

      // Fetch doctor info for each consultation
      await _fetchDoctorInfo();

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch doctor information for consultations
  Future<void> _fetchDoctorInfo() async {
    for (var consultation in _consultations) {
      if (consultation.doctorId != null) {
        try {
          final doctorDoc = await _firestore
              .collection('doctors')
              .doc(consultation.doctorId)
              .get();

          if (doctorDoc.exists) {
            final doctor = DoctorModel.fromMap(
              doctorDoc.data() as Map<String, dynamic>,
              doctorDoc.id,
            );
            consultation.doctorName = doctor.fullName;
            consultation.doctorSpecialty = doctor.specialty.name;
          }
        } catch (e) {
          // If doctor fetch fails, just continue with null values
          debugPrint('Error fetching doctor info: $e');
        }
      }
    }
  }

  // Set filter status
  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Refresh consultations
  Future<void> refresh(String userId) async {
    await fetchUserConsultations(userId);
  }

  // Clear data (e.g., on logout)
  void clear() {
    _consultations = [];
    _isLoading = false;
    _error = null;
    _selectedStatus = 'all';
    notifyListeners();
  }

  // Cancel a consultation
  Future<void> cancelConsultation(String consultationId) async {
    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final index = _consultations.indexWhere((c) => c.id == consultationId);
      if (index != -1) {
        _consultations[index] = _consultations[index].copyWith(
          status: 'cancelled',
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
