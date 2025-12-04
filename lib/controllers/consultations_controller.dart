import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';
import '../utils/constants.dart';
import 'mixins/consultation_filter_mixin.dart';

class ConsultationsController extends ChangeNotifier with ConsultationFilterMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ConsultationModel> _consultations = [];
  bool _isLoading = false;
  String? _error;
  String? _loadedUserId;
  bool _hasPrimedForUser = false;
  String _selectedStatus = 'all'; // 'all' | 'pending' | 'in_review' | 'completed' | 'cancelled'
  String _selectedSegment = 'active'; // 'active' | 'completed' | 'all'

  List<ConsultationModel> get consultations => _consultations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;
  String get selectedSegment => _selectedSegment;
  bool get hasPrimedForUser => _hasPrimedForUser;

  // Computed counts for segment badges
  int get activeCount => _consultations
      .where((c) => ConsultationFilterMixin.isActiveStatus(c.status))
      .length;

  int get completedCount => _consultations
      .where((c) => c.status == AppConstants.statusCompleted)
      .length;

  int get cancelledCount => _consultations
      .where((c) => c.status == AppConstants.statusCancelled)
      .length;

  // Computed property for home screen statistics
  int get pendingCount => _consultations
      .where((c) => c.status == AppConstants.statusPending)
      .length;

  // Recent active consultations for home screen (top 3)
  List<ConsultationModel> get recentActiveConsultations => _consultations
      .where((c) => ConsultationFilterMixin.isActiveStatus(c.status))
      .take(3)
      .toList();
  bool hasDataForUser(String userId) =>
      _hasPrimedForUser && _loadedUserId == userId;

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
          .collection(AppConstants.collectionConsultations)
          .where('patientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _consultations = querySnapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();

      // Fetch doctor info for each consultation
      await _fetchDoctorInfo();

      _loadedUserId = userId;
      _hasPrimedForUser = true;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Prime data for a given user; skips network if already loaded for same user unless forced.
  Future<void> primeForUser(String userId, {bool force = false}) async {
    if (!force && _hasPrimedForUser && _loadedUserId == userId) {
      return;
    }
    await fetchUserConsultations(userId);
  }

  // Fetch doctor information for consultations
  Future<void> _fetchDoctorInfo() async {
    for (var consultation in _consultations) {
      if (consultation.doctorId != null) {
        try {
          final doctorDoc = await _firestore
              .collection(AppConstants.collectionDoctors)
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

  // Set segment filter (active | completed | all)
  void setSegmentFilter(String segment) {
    _selectedSegment = segment;
    notifyListeners();
  }

  // Get consultations filtered by segment
  List<ConsultationModel> get segmentFilteredConsultations {
    switch (_selectedSegment) {
      case 'active':
        return _consultations
            .where((c) => ConsultationFilterMixin.isActiveStatus(c.status))
            .toList();
      case 'completed':
        return _consultations
            .where((c) => c.status == AppConstants.statusCompleted)
            .toList();
      case 'all':
      default:
        return _consultations;
    }
  }

  // Refresh consultations
  Future<void> refresh(String userId) async {
    await fetchUserConsultations(userId);
  }

  // Clear data (e.g., on logout)
  void clear() {
    _consultations = [];
    _isLoading = false;
    _loadedUserId = null;
    _hasPrimedForUser = false;
    _error = null;
    _selectedStatus = 'all';
    _selectedSegment = 'active';
    notifyListeners();
  }

  // Cancel a consultation
  Future<void> cancelConsultation(String consultationId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionConsultations)
          .doc(consultationId)
          .update({
        'status': AppConstants.statusCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final index = _consultations.indexWhere((c) => c.id == consultationId);
      if (index != -1) {
        _consultations[index] = _consultations[index].copyWith(
          status: AppConstants.statusCancelled,
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

  // Submit patient response to an info request
  Future<void> submitInfoResponse(
    String consultationId,
    String infoRequestId, {
    required List<String> answers,
    String? additionalInfo,
  }) async {
    try {
      // Find the consultation
      final consultation = _consultations.firstWhere(
        (c) => c.id == consultationId,
        orElse: () => throw Exception('Consultation not found'),
      );

      // Find and update the info request
      final updatedInfoRequests = consultation.infoRequests.map((request) {
        if (request.id == infoRequestId) {
          return request.copyWith(
            answers: answers,
            additionalInfo: additionalInfo,
            respondedAt: DateTime.now(),
          );
        }
        return request;
      }).toList();

      // Update Firestore
      await _firestore
          .collection(AppConstants.collectionConsultations)
          .doc(consultationId)
          .update({
        'status': AppConstants.statusInReview,
        'updatedAt': FieldValue.serverTimestamp(),
        'infoRequests': updatedInfoRequests.map((r) => r.toMap()).toList(),
      });

      // Update local state
      final index = _consultations.indexWhere((c) => c.id == consultationId);
      if (index != -1) {
        _consultations[index] = _consultations[index].copyWith(
          status: AppConstants.statusInReview,
          updatedAt: DateTime.now(),
          infoRequests: updatedInfoRequests,
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
