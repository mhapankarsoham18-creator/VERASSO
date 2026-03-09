import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/services/network_connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      super.noSuchMethod(
            Invocation.getter(#onConnectivityChanged),
            returnValue: const Stream<List<ConnectivityResult>>.empty(),
          )
          as Stream<List<ConnectivityResult>>;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      super.noSuchMethod(
            Invocation.method(#checkConnectivity, []),
            returnValue: Future.value([ConnectivityResult.none]),
          )
          as Future<List<ConnectivityResult>>;
}

void main() {
  late MockConnectivity mockConnectivity;
  late NetworkConnectivityService service;

  setUp(() {
    mockConnectivity = MockConnectivity();

    // Default mock simple stream
    when(
      mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);

    service = NetworkConnectivityService(connectivity: mockConnectivity);
  });

  group('NetworkConnectivityService', () {
    test('isConnected returns true for wifi', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      expect(await service.isConnected, isTrue);
    });

    test('isConnected returns true for mobile', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.mobile]);
      expect(await service.isConnected, isTrue);
    });

    test('isConnected returns true for ethernet', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.ethernet]);
      expect(await service.isConnected, isTrue);
    });

    test('isConnected returns false for none', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      expect(await service.isConnected, isFalse);
    });

    test('isConnected returns false for bluetooth', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.bluetooth]);
      expect(await service.isConnected, isFalse);
    });

    test('statusStream emits online when connected', () async {
      // Create a service with a specific stream that we can control or directly check the first element emitted
      when(mockConnectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.wifi],
        ]),
      );

      final specificService = NetworkConnectivityService(
        connectivity: mockConnectivity,
      );

      await expectLater(
        specificService.statusStream,
        emits(NetworkStatus.online),
      );
    });

    test('statusStream emits offline when disconnected', () async {
      when(mockConnectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.none],
        ]),
      );

      final specificService = NetworkConnectivityService(
        connectivity: mockConnectivity,
      );

      await expectLater(
        specificService.statusStream,
        emits(NetworkStatus.offline),
      );
    });

    test('statusStream emits multiple status changes', () async {
      when(mockConnectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
          [ConnectivityResult.mobile],
        ]),
      );

      final specificService = NetworkConnectivityService(
        connectivity: mockConnectivity,
      );

      await expectLater(
        specificService.statusStream,
        emitsInOrder([
          NetworkStatus.online,
          NetworkStatus.offline,
          NetworkStatus.online,
        ]),
      );
    });
  });
}
