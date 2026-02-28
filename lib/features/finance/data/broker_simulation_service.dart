import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the stream of simulated asset prices.
final assetPriceStreamProvider = StreamProvider<List<BrokerAsset>>((ref) {
  final service = ref.watch(brokerServiceProvider);
  return service.getPriceStream();
});

/// Provider for the [BrokerSimulationService] instance.
final brokerServiceProvider = Provider((ref) => BrokerSimulationService());

/// Represents a simulated financial asset
class BrokerAsset {
  /// The ticker symbol.
  final String symbol;

  /// The full name of the asset.
  final String name;

  /// Current price in simulation.
  final double currentPrice;

  /// Percentage change since start.
  final double changePercent;

  /// Creates a [BrokerAsset].
  BrokerAsset({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.changePercent,
  });
}

/// Service to simulate a real-world broker API
class BrokerSimulationService {
  // Initial prices
  final Map<String, double> _basePrices = {
    'VRS': 150.25, // Verasso Corp
    'BTC': 65400.0,
    'ETH': 3450.0,
    'GOLD': 2350.0,
    'AAPL': 185.50,
    'TSLA': 175.20,
  };

  final Map<String, String> _names = {
    'VRS': 'Verasso Global',
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'GOLD': 'Gold (Spot)',
    'AAPL': 'Apple Inc.',
    'TSLA': 'Tesla, Inc.',
  };

  /// Simulate a trade execution
  Future<bool> executeTrade({
    required String symbol,
    required double units,
    required bool isBuy,
  }) async {
    // Simulate network delay and high-stakes execution
    await Future.delayed(const Duration(milliseconds: 800));

    // In a real sim, we'd check balance here, but we let the controller handle it
    return true;
  }

  /// Stream of static asset prices (simulation fluctuations removed)
  Stream<List<BrokerAsset>> getPriceStream() async* {
    while (true) {
      final assets = _basePrices.entries.map((e) {
        return BrokerAsset(
          symbol: e.key,
          name: _names[e.key] ?? e.key,
          currentPrice: e.value,
          changePercent: 0.0,
        );
      }).toList();

      yield assets;
      await Future.delayed(const Duration(hours: 1)); // Yield once and wait
    }
  }
}
