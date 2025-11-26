import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mcs_app/models/consultation_model.dart';
import 'package:mcs_app/models/user_model.dart';

/// Controller for doctor-side consultation management.
/// Handles live Firestore stream, status updates, responses, and info requests.
class DoctorConsultationsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<ConsultationModel> _consultations = [];
  final Map<String, UserModel> _patientsCache = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  bool _isLoading = false;
  bool _hasPrimed = false;
  String _selectedStatus = 'all';
  String? _error;
  String? _doctorId;

  List<ConsultationModel> get consultations => List.unmodifiable(_consultations);
  bool get isLoading => _isLoading;
  bool get hasPrimed => _hasPrimed;
  String get selectedStatus => _selectedStatus;
  String? get error => _error;

  List<ConsultationModel> get filteredConsultations {
    if (_selectedStatus == 'all') return consultations;
    return consultations.where((c) => c.status == _selectedStatus).toList();
  }

  UserModel? patientProfile(String patientId) => _patientsCache[patientId];

  /// Start streaming consultations for the authenticated doctor.
  Future<void> primeForDoctor(String doctorId, {bool force = false}) async {
    if (!force && _hasPrimed && _doctorId == doctorId) return;

    _doctorId = doctorId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _subscription?.cancel();

    _subscription = _firestore
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        _consultations
          ..clear()
          ..addAll(snapshot.docs
              .map((doc) => ConsultationModel.fromFirestore(doc))
              .toList());

        _hasPrimed = true;
        _isLoading = false;
        notifyListeners();

        // Fetch patient profiles (cached) to enrich cards and detail views.
        await _preloadPatients(_consultations.map((c) => c.patientId).toSet());
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    if (_doctorId == null) return;
    await primeForDoctor(_doctorId!, force: true);
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  ConsultationModel? consultationById(String consultationId) {
    for (final consultation in _consultations) {
      if (consultation.id == consultationId) return consultation;
    }
    return null;
  }

  Future<void> updateStatus(String consultationId, String status) async {
    try {
      await _firestore.collection('consultations').doc(consultationId).update({
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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

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

    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'doctorResponse': response.toMap(),
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _patchConsultation(
        consultationId,
        (current) => current.copyWith(
          status: 'completed',
          doctorResponse: response,
          completedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> requestMoreInfo(
    String consultationId, {
    required String message,
    required List<String> questions,
  }) async {
    final infoRequest = InfoRequestModel(
      message: message,
      questions: questions,
      doctorId: _doctorId ?? '',
      requestedAt: DateTime.now(),
    );

    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'status': 'info_requested',
        'updatedAt': FieldValue.serverTimestamp(),
        'infoRequests': FieldValue.arrayUnion([infoRequest.toMap()]),
      });

      _patchConsultation(
        consultationId,
        (current) => current.copyWith(
          status: 'info_requested',
          updatedAt: DateTime.now(),
          infoRequests: [...current.infoRequests, infoRequest],
        ),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _preloadPatients(Set<String> patientIds) async {
    final idsToLoad = patientIds.where((id) => !_patientsCache.containsKey(id));
    if (idsToLoad.isEmpty) return;

    for (final id in idsToLoad) {
      try {
        final doc = await _firestore.collection('users').doc(id).get();
        if (doc.exists) {
          _patientsCache[id] =
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      } catch (e) {
        // Best-effort enrichment; do not block UI on errors.
        debugPrint('DoctorConsultationsController: patient fetch failed $e');
      }
    }
    notifyListeners();
  }

  void clear() {
    _consultations.clear();
    _patientsCache.clear();
    _selectedStatus = 'all';
    _isLoading = false;
    _hasPrimed = false;
    _error = null;
    notifyListeners();
  }

  void _patchConsultation(
    String consultationId,
    ConsultationModel Function(ConsultationModel current) updater,
  ) {
    final index = _consultations.indexWhere((c) => c.id == consultationId);
    if (index == -1) return;

    _consultations[index] = updater(_consultations[index]);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
