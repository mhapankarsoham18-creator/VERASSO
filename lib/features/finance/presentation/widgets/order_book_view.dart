import 'package:flutter/material.dart';

/// A widget that displays a simplified order book with bids and asks.
class OrderBookView extends StatelessWidget {
  /// The list of buy orders (bids).
  final List<double> bids;

  /// The list of sell orders (asks).
  final List<double> asks;

  /// Creates an [OrderBookView] instance.
  const OrderBookView({
    super.key,
    required this.bids,
    required this.asks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSide(asks, Colors.redAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSide(bids, Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildSide(List<double> prices, Color color) {
    return Column(
      children: prices
          .map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${p.toStringAsFixed(2)}',
                        style: TextStyle(color: color, fontSize: 11)),
                    Container(
                      height: 4,
                      width:
                          (p % 10) * 4, // Pseudo random width for visualization
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
