import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/user_model.dart';
import 'package:mcs_app/utils/constants.dart';
import 'package:uuid/uuid.dart';

import 'mixins/consultation_filter_mixin.dart';

/// Controller for doctor-side consultation management
class DoctorConsultationsController extends ChangeNotifier
    with ConsultationFilterMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State - SplayTreeSet for automatic deduplication and sorting
  final Set<ConsultationModel> _consultations = SplayTreeSet(
    (a, b) => b.createdAt.compareTo(a.createdAt), // newest first
  );
  // HashMap index for O(1) lookup by ID
  final Map<String, ConsultationModel> _consultationsMap = {};
  final Map<String, UserModel> _patientsCache = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  bool _isLoading = false;
  bool _hasPrimed = false;
  String _selectedSegment = 'in_progress';
  String _selectedStatus = 'all';
  String? _doctorId;

  // Getters - return List for UI compatibility
  List<ConsultationModel> get consultations => List.from(_consultations);
  bool get isLoading => _isLoading;
  bool get hasPrimed => _hasPrimed;
  String get selectedSegment => _selectedSegment;
  String get selectedStatus => _selectedStatus;

  /// Get consultations filtered by segment (New, In Progress, Completed)
  List<ConsultationModel> get segmentFilteredConsultations {
    List<ConsultationModel> segmentFiltered;

    switch (_selectedSegment) {
      case 'new':
        segmentFiltered = _consultations
            .where((c) => c.status == AppConstants.statusPending)
            .toList();
        break;
      case 'in_progress':
        segmentFiltered = _consultations
            .where((c) =>
                c.status == AppConstants.statusInReview ||
                c.status == AppConstants.statusInfoRequested)
            .toList();
        break;
      case 'completed':
        segmentFiltered = _consultations
            .where((c) => ConsultationFilterMixin.isFinishedStatus(c.status))
            .toList();
        break;
      default:
        segmentFiltered = List.from(_consultations);
    }

    // Apply additional status filter if not 'all'
    if (_selectedStatus != 'all') {
      segmentFiltered =
          segmentFiltered.where((c) => c.status == _selectedStatus).toList();
    }

    return segmentFiltered;
  }

  /// Counts for segment badges
  int get newCount => _consultations
      .where((c) => c.status == AppConstants.statusPending)
      .length;

  int get inProgressCount => _consultations
      .where((c) =>
          c.status == AppConstants.statusInReview ||
          c.status == AppConstants.statusInfoRequested)
      .length;

  int get completedCount => _consultations
      .where((c) => ConsultationFilterMixin.isFinishedStatus(c.status))
      .length;

  /// Recent pending consultations for doctor home screen
  List<ConsultationModel> get recentPendingConsultations {
    return _consultations
        .where((c) => c.status == AppConstants.statusPending)
        .toList(); // SplayTreeSet already sorts by createdAt desc
  }

  List<ConsultationModel> get filteredConsultations {
    if (_selectedStatus == 'all') return List.from(_consultations);
    return _consultations.where((c) => c.status == _selectedStatus).toList();
  }

  UserModel? patientProfile(String patientId) => _patientsCache[patientId];

  /// Start streaming consultations for the authenticated doctor.
  Future<void> primeForDoctor(String doctorId, {bool force = false}) async {
    if (!force && _hasPrimed && _doctorId == doctorId) return;

    _doctorId = doctorId;
    _isLoading = true;
    notifyListeners();

    await _subscription?.cancel();

    _subscription = _firestore
        .collection(AppConstants.collectionConsultations)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        _consultations.clear();
        _consultationsMap.clear();
        for (final doc in snapshot.docs) {
          final consultation = ConsultationModel.fromFirestore(doc);
          _consultations.add(consultation);
          _consultationsMap[consultation.id] = consultation;
        }

        _hasPrimed = true;
        _isLoading = false;
        notifyListeners();

        // Fetch patient profiles (cached) to enrich cards and detail views.
        await _preloadPatients(_consultations.map((c) => c.patientId).toSet());
      },
      onError: (e) {
        // Log stream errors but don't store - streams auto-recover
        debugPrint('DoctorConsultationsController stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    if (_doctorId == null) return;
    await primeForDoctor(_doctorId!, force: true);
  }

  void setSegmentFilter(String segment) {
    _selectedSegment = segment;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  /// O(1) lookup by consultation ID
  ConsultationModel? consultationById(String consultationId) =>
      _consultationsMap[consultationId];

  /// Update consultation status.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> updateStatus(String consultationId, String status) async {
    await _firestore
        .collection(AppConstants.collectionConsultations)
        .doc(consultationId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _patchConsultation(
      consultationId,
      (current) => current.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Add doctor response to consultation.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> addDoctorResponse(
    String consultationId, {
    required String responseText,
    String? recommendations,
    bool followUpNeeded = false,
    List<AttachmentModel>? attachments,
  }) async {
    final response = DoctorResponseModel(
      text: responseText,
      recommendations: recommendations,
      followUpNeeded: followUpNeeded,
      responseAttachments: attachments ?? [],
      respondedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.collectionConsultations)
        .doc(consultationId)
        .update({
      'doctorResponse': response.toMap(),
      'status': AppConstants.statusCompleted,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _patchConsultation(
      consultationId,
      (current) => current.copyWith(
        status: AppConstants.statusCompleted,
        doctorResponse: response,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Request more information from patient.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> requestMoreInfo(
    String consultationId, {
    required String message,
    required List<String> questions,
  }) async {
    final infoRequest = InfoRequestModel(
      id: const Uuid().v4(),
      message: message,
      questions: questions,
      doctorId: _doctorId ?? '',
      requestedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.collectionConsultations)
        .doc(consultationId)
        .update({
      'status': AppConstants.statusInfoRequested,
      'updatedAt': FieldValue.serverTimestamp(),
      'infoRequests': FieldValue.arrayUnion([infoRequest.toMap()]),
    });

    _patchConsultation(
      consultationId,
      (current) => current.copyWith(
        status: AppConstants.statusInfoRequested,
        updatedAt: DateTime.now(),
        infoRequests: [...current.infoRequests, infoRequest],
      ),
    );
  }

  /// Preload patient profiles for display in parallel.
  /// Errors here are logged but not thrown - this is supplementary data.
  Future<void> _preloadPatients(Set<String> patientIds) async {
    final idsToLoad = patientIds.where((id) => !_patientsCache.containsKey(id)).toList();
    if (idsToLoad.isEmpty) return;

    await Future.wait(
      idsToLoad.map((id) async {
        try {
          final doc = await _firestore
              .collection(AppConstants.collectionUsers)
              .doc(id)
              .get();
          if (doc.exists) {
            _patientsCache[id] =
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }
        } catch (e) {
          // Best-effort enrichment; do not block UI on errors.
          debugPrint('DoctorConsultationsController: patient fetch failed $e');
        }
      }),
    );
    notifyListeners();
  }

  void clear() {
    _consultations.clear();
    _consultationsMap.clear();
    _patientsCache.clear();
    _selectedSegment = 'in_progress';
    _selectedStatus = 'all';
    _isLoading = false;
    _hasPrimed = false;
    notifyListeners();
  }

  /// Update consultation in Set and Map - remove old, add updated
  void _patchConsultation(
    String consultationId,
    ConsultationModel Function(ConsultationModel current) updater,
  ) {
    final consultation = _consultationsMap[consultationId];
    if (consultation == null) {
      throw Exception('Consultation not found');
    }
    final updated = updater(consultation);
    _consultations.remove(consultation);
    _consultations.add(updated);
    _consultationsMap[consultationId] = updated;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
