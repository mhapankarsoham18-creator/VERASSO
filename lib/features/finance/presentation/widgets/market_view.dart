import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../domain/models.dart';

/// A widget that displays a list of market assets with interactive price charts.
class MarketView extends StatelessWidget {
  /// List of metadata for each asset in the market.
  final List<AssetMetadata> assets;

  /// Historical price data mapped by asset symbol.
  final Map<String, List<double>> priceHistory;

  /// User's current asset holdings for comparison.
  final List<Asset> myAssets;

  /// Callback function triggered when a buy or sell action is performed.
  final Function(AssetMetadata, bool) onBuySell;

  /// Creates a [MarketView] instance.
  const MarketView({
    super.key,
    required this.assets,
    required this.priceHistory,
    required this.myAssets,
    required this.onBuySell,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 40),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text('Available Assets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          ...assets.map((asset) => _buildMarketCardWithChart(context, asset)),
        ],
      ),
    );
  }

  Widget _buildMarketCardWithChart(BuildContext context, AssetMetadata asset) {
    final history = priceHistory[asset.symbol] ?? [];
    final hasOwnership = myAssets.any((a) => a.symbol == asset.symbol);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                child: Text(asset.symbol[0],
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(asset.sector,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${asset.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${asset.change > 0 ? '+' : ''}${asset.change}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: asset.change > 0
                            ? Colors.greenAccent
                            : Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: asset.change > 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => onBuySell(asset, true),
                icon: const Icon(LucideIcons.plusCircle, size: 16),
                label: const Text('Buy'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black),
              ),
              const SizedBox(width: 8),
              if (hasOwnership)
                ElevatedButton.icon(
                  onPressed: () => onBuySell(asset, false),
                  icon: const Icon(LucideIcons.minusCircle, size: 16),
                  label: const Text('Sell'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.black),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
