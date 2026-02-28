import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import '../../../core/mesh/models/mesh_packet.dart';
import '../../../core/services/bluetooth_mesh_service.dart';
import '../data/finance_repository.dart';

/// Provider for [PortfolioService].
final portfolioServiceProvider = Provider((ref) {
  final repository = ref.read(financeRepositoryProvider);
  final mesh = ref.read(bluetoothMeshServiceProvider);
  return PortfolioService(repository, mesh);
});

/// Portfolio service to handle Supabase persistence and Mesh-based redundancy

class PortfolioService {
  static const _alphaVantageKey =
      ''; // MUST BE SET VIA GOOGLE_PROPERTIES OR SECURED SECRET
  final FinanceRepository _repository;
  final BluetoothMeshService? _meshService;

  /// Creates a [PortfolioService] instance.
  PortfolioService(this._repository, [this._meshService]);

  /// Fetch real-time stock data from Alpha Vantage
  /// Falls back to simulation if API fails or limit reached
  Future<Map<String, dynamic>> fetchStockData(String symbol) async {
    try {
      final uri = Uri.parse(
          'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_alphaVantageKey');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Global Quote'] != null && data['Global Quote'].isNotEmpty) {
          return data['Global Quote'];
        }
      }
    } catch (e, stack) {
      AppLogger.warning('Stock fetch failed for $symbol', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }

    return {}; // Return empty if API fails, no simulation fallback
  }

  /// Initialize portfolio from Supabase
  Future<Map<String, dynamic>> loadPortfolio() async {
    try {
      final meta = await _repository.getPortfolioMeta();
      final holdings = await _repository.getPortfolioHoldings();
      final transactions = await _repository.getPortfolioTransactions();

      return {
        'cashBalance': meta['cash_balance'] ?? 10000.0,
        'totalXP': meta['total_xp_earned'] ?? 0,
        'holdings': holdings,
        'transactions': transactions,
      };
    } catch (e, stack) {
      AppLogger.error('Error loading portfolio', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return {
        'cashBalance': 10000.0,
        'totalXP': 0,
        'holdings': [],
        'transactions': [],
      };
    }
  }

  /// Record a buy transaction
  Future<void> recordBuy(String symbol, double units, double price) async {
    try {
      await _repository.addPortfolioTransaction(symbol, 'buy', units, price);
    } catch (e, stack) {
      AppLogger.error('Error recording buy', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Record a sell transaction
  Future<void> recordSell(String symbol, double units, double price) async {
    try {
      await _repository.addPortfolioTransaction(symbol, 'sell', units, price);
    } catch (e, stack) {
      AppLogger.error('Error recording sell', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Save portfolio state to Supabase
  Future<void> savePortfolio({
    required double cashBalance,
    required int totalXP,
    required List<Map<String, dynamic>> holdings,
  }) async {
    try {
      await _repository.updatePortfolioMeta(cashBalance, totalXP);

      // Update holdings
      for (final holding in holdings) {
        await _repository.upsertPortfolioHolding(
          holding['symbol'],
          holding['name'],
          holding['units'],
          holding['avgPrice'],
        );
      }
    } catch (e, stack) {
      AppLogger.error('Error saving portfolio', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Broadcast minified portfolio to Mesh siblings for redundancy
  Future<void> syncPortfolioToMesh({
    required double cashBalance,
    required List<Map<String, dynamic>> holdings,
  }) async {
    if (_meshService == null) return;

    try {
      // Create a minified snapshot
      final snapshot = {
        'cash': cashBalance,
        'hld': holdings
            .map((h) => {
                  's': h['symbol'] ?? h['name'], // Fallback
                  'u': h['units'],
                })
            .toList(),
      };

      await _meshService.broadcastPacket(
        MeshPayloadType.portfolioSync,
        snapshot,
      );
      AppLogger.info('Portfolio Pulse Sync broadcasted to Mesh');
    } catch (e, stack) {
      AppLogger.error('Mesh Sync Error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}
