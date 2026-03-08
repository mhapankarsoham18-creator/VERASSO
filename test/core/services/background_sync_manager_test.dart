import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/services/background_sync_manager.dart';
import 'package:verasso/core/services/network_connectivity_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';

class MockNetworkConnectivityService extends Mock implements NetworkConnectivityService {
  @override
  Stream<NetworkStatus> get statusStream => super.noSuchMethod(
        Invocation.getter(#statusStream),
        returnValue: const Stream<NetworkStatus>.empty(),
      ) as Stream<NetworkStatus>;
}

class MockOfflineStorageService extends Mock implements OfflineStorageService {
  @override
  Map<dynamic, dynamic> getPendingActionsMap() => super.noSuchMethod(
        Invocation.method(#getPendingActionsMap, []),
        returnValue: <dynamic, dynamic>{},
      ) as Map<dynamic, dynamic>;
}

void main() {
  late MockNetworkConnectivityService mockNetworkService;
  late MockOfflineStorageService mockStorageService;
  late StreamController<NetworkStatus> networkStatusController;

  setUp(() {
    mockNetworkService = MockNetworkConnectivityService();
    mockStorageService = MockOfflineStorageService();
    networkStatusController = StreamController<NetworkStatus>.broadcast();

    when(mockNetworkService.statusStream).thenAnswer((_) => networkStatusController.stream);
    when(mockStorageService.getPendingActionsMap()).thenReturn({});
  });

  tearDown(() {
    networkStatusController.close();
  });

  group('BackgroundSyncManager Initialization', () {
    test('listens to network stream on init', () {
      // Actually creating the instance should attach the listener
      BackgroundSyncManager(mockNetworkService, mockStorageService);
      
      // We know it listened if it has listeners
      expect(networkStatusController.hasListener, isTrue);
    });
  });

  // Notes: The full offline sync logic involves SupabaseClient which is highly static
  // globally in this app (SupabaseService.client). Mocking it completely in unit test
  // without DI is tricky.
  // 
  // However, we can assert that when Network becomes online, it calls getPendingActionsMap().
  group('BackgroundSyncManager Sync Triggering', () {
    test('does not try to sync when offline', () async {
      BackgroundSyncManager(mockNetworkService, mockStorageService);
      
      networkStatusController.add(NetworkStatus.offline);
      // Let event loop run
      await Future.delayed(Duration.zero);
      
      verifyNever(mockStorageService.getPendingActionsMap());
    });

    test('calls getPendingActionsMap when network online', () async {
      BackgroundSyncManager(mockNetworkService, mockStorageService);
      
      networkStatusController.add(NetworkStatus.online);
      // Let event loop run
      await Future.delayed(Duration.zero);
      
      verify(mockStorageService.getPendingActionsMap()).called(1);
    });
  });
}
