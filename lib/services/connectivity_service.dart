import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service that monitors network connectivity status.
/// Notifies listeners when connectivity changes between online/offline states.
class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Check initial state
    final result = await Connectivity().checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    notifyListeners();

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    });
  }

  /// Manually trigger a connectivity check.
  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final wasOnline = _isOnline;
    _isOnline = !result.contains(ConnectivityResult.none);
    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
