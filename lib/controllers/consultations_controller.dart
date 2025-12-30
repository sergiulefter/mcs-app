import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';
import '../utils/constants.dart';
import 'mixins/consultation_filter_mixin.dart';

/// Patient consultations controller
class ConsultationsController extends ChangeNotifier
    with ConsultationFilterMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Default page size for pagination
  static const int _pageSize = 20;

  // State - SplayTreeSet for automatic deduplication and sorting
  final Set<ConsultationModel> _consultations = SplayTreeSet(
    (a, b) => b.createdAt.compareTo(a.createdAt), // newest first
  );
  bool _isLoading = false;
  String? _loadedUserId;
  bool _hasPrimedForUser = false;
  String _selectedStatus = 'all';
  String _selectedSegment = 'active';

  // Pagination state
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  // Getters - return List for UI compatibility
  List<ConsultationModel> get consultations => List.from(_consultations);
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;
  String get selectedSegment => _selectedSegment;
  bool get hasPrimedForUser => _hasPrimedForUser;
  bool get hasMore => _hasMore;

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
      return List.from(_consultations);
    }
    return _consultations
        .where((consultation) => consultation.status == _selectedStatus)
        .toList();
  }

  /// Fetch initial page of consultations for a specific user (resets pagination).
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> fetchUserConsultations(String userId) async {
    _isLoading = true;
    _consultations.clear();
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionConsultations)
          .where('patientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      _consultations.addAll(
        querySnapshot.docs.map((doc) => ConsultationModel.fromFirestore(doc)),
      );

      _lastDocument = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.last
          : null;
      _hasMore = querySnapshot.docs.length >= _pageSize;

      // Fetch doctor info for each consultation
      await _fetchDoctorInfo();

      _loadedUserId = userId;
      _hasPrimedForUser = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch more consultations (next page).
  /// Does nothing if already loading or no more data.
  Future<void> fetchMore() async {
    if (_isLoading || !_hasMore || _loadedUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      var query = _firestore
          .collection(AppConstants.collectionConsultations)
          .where('patientId', isEqualTo: _loadedUserId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      final newConsultations = querySnapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();

      _consultations.addAll(newConsultations);
      _lastDocument = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.last
          : null;
      _hasMore = querySnapshot.docs.length >= _pageSize;

      // Fetch doctor info for new consultations
      await _fetchDoctorInfoForList(newConsultations);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Prime data for a given user; skips network if already loaded for same user unless forced.
  Future<void> primeForUser(String userId, {bool force = false}) async {
    if (!force && _hasPrimedForUser && _loadedUserId == userId) {
      return;
    }
    await fetchUserConsultations(userId);
  }

  /// Fetch doctor information for all consultations in parallel.
  /// Errors here are logged but not thrown - this is supplementary data.
  Future<void> _fetchDoctorInfo() async {
    await _fetchDoctorInfoForList(_consultations.toList());
  }

  /// Fetch doctor information for a specific list of consultations.
  /// Updates local state with enriched data.
  Future<void> _fetchDoctorInfoForList(
    List<ConsultationModel> targetConsultations,
  ) async {
    // 1. Identify unique doctor IDs needed
    final doctorIds = targetConsultations
        .map((c) => c.doctorId)
        .where((id) => id != null)
        .toSet();

    if (doctorIds.isEmpty) return;

    // 2. Fetch doctor data
    // optimization: could cache these lookups if needed, but keeping it simple for now
    final Map<String, DoctorModel> doctorMap = {};

    await Future.wait(
      doctorIds.map((id) async {
        try {
          final doc = await _firestore
              .collection(AppConstants.collectionDoctors)
              .doc(id)
              .get();

          if (doc.exists) {
            doctorMap[id!] = DoctorModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }
        } catch (e) {
          debugPrint('Error fetching doctor $id: $e');
        }
      }),
    );

    // 3. Update consultations in the list AND the main set
    // We must remove the old instance and add the new one to preserve Set integrity
    // if the comparator logic or hashcode relied on these fields (it matches by ID/Created).

    // We iterate over the *targets* but update the *main state*
    for (final consultation in targetConsultations) {
      if (consultation.doctorId != null &&
          doctorMap.containsKey(consultation.doctorId)) {
        final doctor = doctorMap[consultation.doctorId];

        // Create immutable copy
        final updatedConsultation = consultation.copyWith(
          doctorName: doctor?.fullName,
          doctorSpecialty: doctor?.specialty.name,
        );

        // Update main state
        if (_consultations.contains(consultation)) {
          _consultations.remove(consultation);
          _consultations.add(updatedConsultation);
        }
      }
    }

    // Notify once after batch update
    notifyListeners();
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
        return List.from(_consultations);
    }
  }

  /// Refresh consultations.
  Future<void> refresh(String userId) async {
    await fetchUserConsultations(userId);
  }

  /// Clear data (e.g., on logout).
  void clear() {
    _consultations.clear();
    _isLoading = false;
    _loadedUserId = null;
    _hasPrimedForUser = false;
    _lastDocument = null;
    _hasMore = true;
    _selectedStatus = 'all';
    _selectedSegment = 'active';
    notifyListeners();
  }

  /// Cancel a consultation.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> cancelConsultation(String consultationId) async {
    await _firestore
        .collection(AppConstants.collectionConsultations)
        .doc(consultationId)
        .update({
          'status': AppConstants.statusCancelled,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    // Update local state - find, remove, update, re-add (Set pattern)
    final consultation = _consultations.firstWhere(
      (c) => c.id == consultationId,
      orElse: () => throw Exception('Consultation not found'),
    );
    _consultations.remove(consultation);
    _consultations.add(
      consultation.copyWith(
        status: AppConstants.statusCancelled,
        updatedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Submit patient response to an info request.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> submitInfoResponse(
    String consultationId,
    String infoRequestId, {
    required List<String> answers,
    String? additionalInfo,
  }) async {
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

    // Update local state - remove old, add updated (Set pattern)
    _consultations.remove(consultation);
    _consultations.add(
      consultation.copyWith(
        status: AppConstants.statusInReview,
        updatedAt: DateTime.now(),
        infoRequests: updatedInfoRequests,
      ),
    );
    notifyListeners();
  }
}
