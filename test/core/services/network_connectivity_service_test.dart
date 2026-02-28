import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/services/network_connectivity_service.dart';

void main() {
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> streamController;
  late NetworkConnectivityService service;

  group('NetworkConnectivityService Tests', () {
    setUp(() {
      mockConnectivity = MockConnectivity();
      streamController = StreamController<List<ConnectivityResult>>.broadcast();

      // Mock onConnectivityChanged to return our stream controller's stream
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => streamController.stream);

      service = NetworkConnectivityService(connectivity: mockConnectivity);
    });

    tearDown(() {
      streamController.close();
    });

    test('Should emit online when connected to wifi', () async {
      // Create expectations before emitting
      final expectation = expectLater(
        service.statusStream,
        emitsInOrder([NetworkStatus.online]),
      );

      // Emit wifi connection event
      streamController.add([ConnectivityResult.wifi]);

      await expectation;
    });

    test('Should emit online when connected to mobile', () async {
      final expectation = expectLater(
        service.statusStream,
        emitsInOrder([NetworkStatus.online]),
      );

      streamController.add([ConnectivityResult.mobile]);

      await expectation;
    });

    test('Should emit offline when not connected', () async {
      final expectation = expectLater(
        service.statusStream,
        emitsInOrder([NetworkStatus.offline]),
      );

      streamController.add([ConnectivityResult.none]);

      await expectation;
    });

    test('isConnected getter returns true when connected', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      expect(await service.isConnected, isTrue);
    });

    test('isConnected getter returns false when disconnected', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      expect(await service.isConnected, isFalse);
    });
  });
}

// Mock Classes
class MockConnectivity extends Mock implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      super.noSuchMethod(
        Invocation.getter(#onConnectivityChanged),
        returnValue: Stream<List<ConnectivityResult>>.empty(),
      );

  @override
  Future<List<ConnectivityResult>> checkConnectivity() => super.noSuchMethod(
        Invocation.method(#checkConnectivity, []),
        returnValue: Future.value([ConnectivityResult.none]),
      );
}
