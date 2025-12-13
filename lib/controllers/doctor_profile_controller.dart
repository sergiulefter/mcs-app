import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mcs_app/models/doctor_model.dart';
import 'package:mcs_app/services/doctor_service.dart';

/// Central source of truth for the authenticated doctor's profile.
class DoctorProfileController extends ChangeNotifier {
  final DoctorService _doctorService = DoctorService();
  DoctorModel? _doctor;
  bool _isLoading = false;
  String? _doctorId;

  StreamSubscription<DoctorModel?>? _subscription;

  DoctorModel? get doctor => _doctor;
  bool get isLoading => _isLoading;
  bool get hasData => _doctor != null;

  /// Prime the doctor profile stream.
  Future<void> prime(String doctorId, {bool force = false}) async {
    if (!force && _doctorId == doctorId && _subscription != null) return;

    _doctorId = doctorId;
    _isLoading = true;
    notifyListeners();

    await _subscription?.cancel();
    _subscription = _doctorService.streamDoctor(doctorId).listen(
      (doc) {
        _doctor = doc;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        // Log stream errors but don't store - streams auto-recover
        debugPrint('DoctorProfileController stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Refresh doctor profile from server.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> refresh() async {
    if (_doctorId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final fresh =
          await _doctorService.fetchDoctorById(_doctorId!, serverOnly: true);
      if (fresh != null) {
        _doctor = fresh;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update doctor availability status.
  /// Throws exceptions on failure - UI should catch and display.
  Future<void> updateAvailability(bool isAvailable) async {
    if (_doctorId == null) return;

    await _doctorService.updateAvailability(_doctorId!, isAvailable);
    _doctor = _doctor?.copyWith(isAvailable: isAvailable);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
