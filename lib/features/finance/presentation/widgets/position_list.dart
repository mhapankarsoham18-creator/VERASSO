import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../domain/models.dart';

/// A widget that displays a list of the user's current asset positions.
class PositionList extends StatelessWidget {
  /// The list of assets currently held by the user.
  final List<Asset> myAssets;

  /// The overarching market metadata for the assets.
  final List<AssetMetadata> marketAssets;

  /// Callback to show the buy/sell dialog for a specific asset.
  final Function(AssetMetadata, bool) onShowBuySell;

  /// Creates a [PositionList] instance.
  const PositionList({
    super.key,
    required this.myAssets,
    required this.marketAssets,
    required this.onShowBuySell,
  });

  @override
  Widget build(BuildContext context) {
    if (myAssets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.briefcase, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text('No active positions',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children:
          myAssets.map((asset) => _buildHoldingCard(context, asset)).toList(),
    );
  }

  Widget _buildHoldingCard(BuildContext context, Asset asset) {
    // Find metadata to get current price
    final meta = marketAssets.firstWhere(
      (m) => m.symbol == asset.symbol,
      orElse: () => AssetMetadata(
        symbol: asset.symbol,
        name: asset.name,
        price: asset.avgPrice,
        change: 0,
        sector: 'Unknown',
      ),
    );

    final currentValue = asset.units * meta.price;
    final costBasis = asset.units * asset.avgPrice;
    final profit = currentValue - costBasis;
    final profitPercent = costBasis > 0 ? (profit / costBasis) * 100 : 0.0;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(asset.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(LucideIcons.minusCircle,
                    color: Colors.redAccent, size: 20),
                onPressed: () => onShowBuySell(meta, false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Units: ${asset.units.toStringAsFixed(2)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54)),
                  Text('Avg Price: \$${asset.avgPrice.toStringAsFixed(2)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${currentValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    '${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)} (${profitPercent >= 0 ? '+' : ''}${profitPercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                        fontSize: 12,
                        color: profit >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
