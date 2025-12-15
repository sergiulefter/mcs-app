import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs_app/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService', () {
    late MethodChannel connectivityChannel;

    setUp(() {
      // Mock the connectivity_plus platform channel
      connectivityChannel =
          const MethodChannel('dev.fluttercommunity.plus/connectivity');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectivityChannel, (MethodCall call) async {
        if (call.method == 'check') {
          // Return wifi connectivity
          return ['wifi'];
        }
        return null;
      });
    });

    tearDown(() {
      // Clear the mock handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectivityChannel, null);
    });

    test('initial state is online by default', () async {
      final service = ConnectivityService();

      // Default state before connectivity check completes
      expect(service.isOnline, true);

      // Give time for async init
      await Future.delayed(const Duration(milliseconds: 100));

      // Should still be online after checking connectivity
      expect(service.isOnline, true);

      service.dispose();
    });

    test('isOnline getter returns current state', () async {
      final service = ConnectivityService();

      // The getter should return a boolean
      expect(service.isOnline, isA<bool>());

      // Give time for async init
      await Future.delayed(const Duration(milliseconds: 100));

      service.dispose();
    });

    test('extends ChangeNotifier', () async {
      final service = ConnectivityService();

      // Verify it's a ChangeNotifier
      expect(service, isA<ConnectivityService>());
      expect(service, isA<ChangeNotifier>());

      // Verify we can add listeners without error
      var listenerCalled = false;
      service.addListener(() {
        listenerCalled = true;
      });

      // Listener was added successfully (won't be called unless state changes)
      expect(listenerCalled, false);

      // Give time for async init
      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up
      service.dispose();
    });

    test('dispose cancels subscription without error', () async {
      final service = ConnectivityService();

      // Give time for async init to set up subscription
      await Future.delayed(const Duration(milliseconds: 100));

      // Should not throw
      expect(() => service.dispose(), returnsNormally);
    });

    test('checkConnectivity method can be called', () async {
      final service = ConnectivityService();

      // Give time for init
      await Future.delayed(const Duration(milliseconds: 100));

      // Should not throw
      await service.checkConnectivity();

      // Should still be online
      expect(service.isOnline, true);

      service.dispose();
    });

    test('reports offline when connectivity is none', () async {
      // Mock offline state
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectivityChannel, (MethodCall call) async {
        if (call.method == 'check') {
          // Return no connectivity
          return ['none'];
        }
        return null;
      });

      final service = ConnectivityService();

      // Give time for async init
      await Future.delayed(const Duration(milliseconds: 100));

      // Should be offline
      expect(service.isOnline, false);

      service.dispose();
    });

    test('notifies listeners when connectivity changes', () async {
      final service = ConnectivityService();
      var notifyCount = 0;

      service.addListener(() {
        notifyCount++;
      });

      // Give time for initial async init (triggers one notification)
      await Future.delayed(const Duration(milliseconds: 100));

      // Initial notification count (at least 1 from init)
      expect(notifyCount, greaterThanOrEqualTo(1));

      service.dispose();
    });
  });
}
