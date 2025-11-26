import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';

/// Central source of truth for the authenticated doctor's profile.
/// Streams the doctor document and exposes helpers for availability updates.
class DoctorProfileController extends ChangeNotifier {
  final DoctorService _doctorService = DoctorService();
  DoctorModel? _doctor;
  bool _isLoading = false;
  String? _error;
  String? _doctorId;

  StreamSubscription<DoctorModel?>? _subscription;

  DoctorModel? get doctor => _doctor;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _doctor != null;

  Future<void> prime(String doctorId, {bool force = false}) async {
    if (!force && _doctorId == doctorId && _subscription != null) return;

    _doctorId = doctorId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _subscription?.cancel();
    _subscription = _doctorService
        .streamDoctor(doctorId)
        .listen((doc) {
      _doctor = doc;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    if (_doctorId == null) return;
    try {
      _isLoading = true;
      notifyListeners();
      final fresh =
          await _doctorService.fetchDoctorById(_doctorId!, serverOnly: true);
      if (fresh != null) {
        _doctor = fresh;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    if (_doctorId == null) return;
    try {
      await _doctorService.updateAvailability(_doctorId!, isAvailable);
      _doctor = _doctor?.copyWith(isAvailable: isAvailable);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
