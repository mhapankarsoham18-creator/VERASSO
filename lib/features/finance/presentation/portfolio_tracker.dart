import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/services/tutorial_service.dart';
import '../../../core/ui/tutorial_overlay.dart';
import '../data/broker_simulation_service.dart';
import '../domain/models.dart';
import '../services/portfolio_service.dart';
import '../tutorials/portfolio_tutorial.dart';
import 'widgets/market_view.dart';
import 'widgets/order_book_view.dart';
import 'widgets/position_list.dart';

/// Interactive brokerage simulator for tracking a mock portfolio, executing
/// trades, and receiving AI-powered feedback on diversification and risk.
class PortfolioTracker extends ConsumerStatefulWidget {
  /// Creates a [PortfolioTracker] instance.
  const PortfolioTracker({super.key});

  @override
  ConsumerState<PortfolioTracker> createState() => _PortfolioTrackerState();
}

class _PortfolioTrackerState extends ConsumerState<PortfolioTracker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double cashBalance = 10000;
  final List<Asset> _myAssets = [];
  final List<AssetTransaction> _transactionHistory = [];
  int totalXPEarned = 0;

  List<AssetMetadata> _marketAssets = [];

  @override
  Widget build(BuildContext context) {
    final livePrices = ref.watch(assetPriceStreamProvider);

    return livePrices.when(
      data: (assets) {
        // Update local market assets with live prices
        _marketAssets = assets
            .map((a) => AssetMetadata(
                  symbol: a.symbol,
                  name: a.name,
                  price: a.currentPrice,
                  change: double.parse(a.changePercent.toStringAsFixed(2)),
                  sector: 'Global Market',
                ))
            .toList();

        double totalValue = cashBalance +
            _myAssets.fold(0, (sum, a) {
              final meta = _marketAssets.firstWhere(
                (m) => m.symbol == a.symbol,
                orElse: () => AssetMetadata(
                  symbol: a.symbol,
                  name: a.name,
                  price: a.avgPrice,
                  change: 0,
                  sector: 'Unknown',
                ),
              );
              return sum + (a.units * meta.price);
            });

        double portfolioReturn = ((totalValue - 10000) / 10000) * 100;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Portfolio Tracker'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.bot),
                onPressed: () => _showAIReview(totalValue, portfolioReturn),
                tooltip: 'AI Analysis',
              ),
              IconButton(
                icon: const Icon(LucideIcons.helpCircle),
                onPressed: _showTutorial,
                tooltip: 'Show Tutorial',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Portfolio'),
                Tab(text: 'Market'),
                Tab(text: 'News'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: LiquidBackground(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPortfolioTab(totalValue, portfolioReturn),
                      _buildMarketTab(),
                      _buildNewsTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Portfolio Tracker')),
        body: AppErrorView(
          title: 'Market data unavailable',
          message: err.toString(),
          onRetry: () => ref.invalidate(assetPriceStreamProvider),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPortfolioData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final completed = await TutorialService.isTutorialCompleted(
          TutorialIds.portfolioTracker);
      if (!completed && mounted) {
        _showTutorial();
      }
    });
  }

  void showBuySellDialog(AssetMetadata asset, bool isBuy) {
    double units = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          contentPadding: EdgeInsets.zero,
          content: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${isBuy ? 'Execute Buy' : 'Execute Sell'} ${asset.symbol}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white38),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  asset.name,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Market Price',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 11)),
                        Text('\$${asset.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: asset.change >= 0
                            ? Colors.greenAccent.withValues(alpha: 0.1)
                            : Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${asset.change >= 0 ? '+' : ''}${asset.change}%',
                        style: TextStyle(
                            color: asset.change >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Live Simulated Order Book based on current market price
                const Text('ORDER BOOK',
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OrderBookView(
                  asks: List.generate(
                      3,
                      (i) =>
                          asset.price +
                          (math.Random().nextDouble() * 0.15) +
                          (i * 0.05)).toList()
                    ..sort(),
                  bids: List.generate(
                      3,
                      (i) =>
                          asset.price -
                          (math.Random().nextDouble() * 0.15) -
                          (i * 0.05)).toList()
                    ..sort((a, b) => b.compareTo(a)),
                ),

                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Units to ${isBuy ? 'Buy' : 'Sell'}',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon:
                        const Icon(LucideIcons.package, color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    setDialogState(() {
                      units = double.tryParse(v) ?? 1;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Total Execution Cost',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 13)),
                    ),
                    Text(
                      '\$${(units * asset.price).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isBuy ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isBuy) {
                        _buyAsset(asset, units);
                      } else {
                        final myAsset = _myAssets
                            .firstWhere((a) => a.symbol == asset.symbol);
                        _sellAsset(myAsset, units);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBuy ? Colors.greenAccent : Colors.redAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      '${isBuy ? 'BUY' : 'SELL'} ${asset.symbol.toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFancySummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white38),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_transactionHistory.isEmpty) {
      return const Center(
          child: Text('No transactions yet.',
              style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 40),
      itemCount: _transactionHistory.length,
      itemBuilder: (context, index) {
        final tx = _transactionHistory.reversed.toList()[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                tx.type == AssetTransactionType.buy
                    ? LucideIcons.arrowDown
                    : LucideIcons.arrowUp,
                color: tx.type == AssetTransactionType.buy
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.type == AssetTransactionType.buy ? 'Bought' : 'Sold'} ${tx.symbol}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${tx.units.toStringAsFixed(2)} units @ \$${tx.price.toStringAsFixed(2)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${(tx.units * tx.price).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tx.type == AssetTransactionType.buy
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsight(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.chevronRight, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTab() {
    return MarketView(
      assets: _marketAssets,
      priceHistory: const {}, // price history removed till real backend is ready
      myAssets: _myAssets,
      onBuySell: showBuySellDialog,
    );
  }

  Widget _buildNewsTab() {
    return const Center(
      child: Text(
        'News service unavailable.',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildPortfolioTab(double totalValue, double portfolioReturn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 40),
      child: Column(
        children: [
          // Portfolio Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Net Worth',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${totalValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: portfolioReturn >= 0
                            ? Colors.greenAccent.withValues(alpha: 0.1)
                            : Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${portfolioReturn >= 0 ? '▲' : '▼'} ${portfolioReturn.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: portfolioReturn >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _buildFancySummaryItem(
                          'Cash Balance',
                          '\$${cashBalance.toStringAsFixed(0)}',
                          LucideIcons.wallet),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: _buildFancySummaryItem(
                          'Market Value',
                          '\$${(totalValue - cashBalance).toStringAsFixed(0)}',
                          LucideIcons.trendingUp),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.award,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'JOURNALIST XP: $totalXPEarned',
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Diversification Pie Chart
          if (_myAssets.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text('Portfolio Allocation',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            GlassContainer(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _myAssets.map((asset) {
                    final meta = _marketAssets
                        .firstWhere((m) => m.symbol == asset.symbol);
                    final value = asset.units * meta.price;
                    final percentage =
                        (value / (totalValue - cashBalance)) * 100;
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple
                    ];
                    final colorIndex = _myAssets.indexOf(asset) % colors.length;

                    return PieChartSectionData(
                      value: value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: colors[colorIndex],
                      radius: 80,
                      titleStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // My Holdings
          if (_myAssets.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text('My Holdings',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            PositionList(
              myAssets: _myAssets,
              marketAssets: _marketAssets,
              onShowBuySell: showBuySellDialog,
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No holdings yet. Start investing!',
                    style: TextStyle(color: Colors.white54)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, {bool isMain = false}) {
    Color color =
        score > 80 ? Colors.green : (score > 50 ? Colors.amber : Colors.red);
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text('$score',
            style: TextStyle(
                color: color,
                fontSize: isMain ? 32 : 24,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _buyAsset(AssetMetadata metadata, double units) {
    double cost = metadata.price * units;
    if (cost > cashBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Insufficient funds!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      cashBalance -= cost;
      int index = _myAssets.indexWhere((a) => a.symbol == metadata.symbol);
      if (index != -1) {
        _myAssets[index] = Asset(
          symbol: metadata.symbol,
          name: metadata.name,
          units: _myAssets[index].units + units,
          avgPrice:
              ((_myAssets[index].avgPrice * _myAssets[index].units) + cost) /
                  (_myAssets[index].units + units),
        );
      } else {
        _myAssets.add(Asset(
          symbol: metadata.symbol,
          name: metadata.name,
          units: units,
          avgPrice: metadata.price,
        ));
      }

      // Add transaction
      _transactionHistory.add(AssetTransaction(
        type: AssetTransactionType.buy,
        symbol: metadata.symbol,
        units: units,
        price: metadata.price,
        date: DateTime.now(),
      ));

      // Award XP
      int xp = (cost / 100).round();
      totalXPEarned += xp;

      _savePortfolio();
      ref
          .read(portfolioServiceProvider)
          .recordBuy(metadata.symbol, units, metadata.price);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Bought ${units.toStringAsFixed(2)} units. +$xp XP!'),
            backgroundColor: Colors.green),
      );
    });
  }

  Future<void> _loadPortfolioData() async {
    final data = await ref.read(portfolioServiceProvider).loadPortfolio();
    if (mounted) {
      setState(() {
        cashBalance = data['cashBalance'];
        totalXPEarned = data['totalXP'];

        final holdings = data['holdings'] as List;
        _myAssets.clear();
        for (final h in holdings) {
          _myAssets.add(Asset(
            symbol: h['symbol'],
            name: h['name'],
            units: h['units'],
            avgPrice: h['avgPrice'],
          ));
        }

        final transactions = data['transactions'] as List;
        _transactionHistory.clear();
        for (final t in transactions) {
          _transactionHistory.add(AssetTransaction(
            type: t['type'] == 'buy'
                ? AssetTransactionType.buy
                : AssetTransactionType.sell,
            symbol: t['symbol'],
            units: t['units'],
            price: t['price'],
            date: t['date'],
          ));
        }
      });
    }
  }

  Future<void> _savePortfolio() async {
    await ref.read(portfolioServiceProvider).savePortfolio(
          cashBalance: cashBalance,
          totalXP: totalXPEarned,
          holdings: _myAssets
              .map((a) => {
                    'symbol': a.symbol,
                    'name': a.name,
                    'units': a.units,
                    'avgPrice': a.avgPrice,
                  })
              .toList(),
        );
  }

  void _sellAsset(Asset asset, double units) {
    final meta = _marketAssets.firstWhere((m) => m.symbol == asset.symbol);
    double revenue = meta.price * units;

    if (units > asset.units) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Insufficient units!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      cashBalance += revenue;

      if (units >= asset.units) {
        _myAssets.remove(asset);
      } else {
        int index = _myAssets.indexOf(asset);
        _myAssets[index] = Asset(
          symbol: asset.symbol,
          name: asset.name,
          units: asset.units - units,
          avgPrice: asset.avgPrice,
        );
      }

      // Add transaction
      _transactionHistory.add(AssetTransaction(
        type: AssetTransactionType.sell,
        symbol: asset.symbol,
        units: units,
        price: meta.price,
        date: DateTime.now(),
      ));

      // Award XP for profitable trades
      double profit = (meta.price - asset.avgPrice) * units;
      if (profit > 0) {
        int xp = (profit / 50).round();
        totalXPEarned += xp;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Sold ${units.toStringAsFixed(2)} units. Profit: \$${profit.toStringAsFixed(2)}. +$xp XP!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Sold ${units.toStringAsFixed(2)} units. Loss: \$${profit.abs().toStringAsFixed(2)}'),
              backgroundColor: Colors.orange),
        );
      }

      _savePortfolio();
      ref
          .read(portfolioServiceProvider)
          .recordSell(asset.symbol, units, meta.price);
    });
  }

  void _showAIReview(double totalValue, double portfolioReturn) {
    // Scoring Logic
    int diversityScore = _myAssets.length >= 3 ? 100 : (_myAssets.length * 30);
    int performanceScore =
        portfolioReturn > 0 ? 100 : (portfolioReturn > -5 ? 70 : 40);
    double cashRatio = totalValue > 0 ? (cashBalance / totalValue) : 1.0;
    int riskScore =
        (cashRatio > 0.1 && cashRatio < 0.5) ? 90 : 60; // Ideal cash 10-50%

    int totalScore =
        ((diversityScore + performanceScore + riskScore) / 3).round();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bot, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Text('Verasso AI Analysis',
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildScoreCard('Diversity', diversityScore),
                _buildScoreCard('Health', totalScore, isMain: true),
                _buildScoreCard('Risk Mgmt', riskScore),
              ],
            ),
            const SizedBox(height: 24),
            Text('Actionable Insights:',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            const SizedBox(height: 12),
            if (cashRatio > 0.6)
              _buildInsight('High Cash Drag',
                  'Consider investing more capital to maximize returns.'),
            if (_myAssets.length < 3)
              _buildInsight(
                  'Low Diversity', 'Add more varied assets to reduce risk.'),
            if (portfolioReturn < 0)
              _buildInsight('Underperformance',
                  'Review your negative positions. Consider stop-loss strategies.'),
            if (totalScore > 80 && _myAssets.length >= 3)
              _buildInsight('Excellent Profile',
                  'Your portfolio is well-balanced and performing well.'),
            if (_myAssets.isEmpty)
              _buildInsight(
                  'Empty Portfolio', 'Start trading to see analysis!'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: portfolioTutorialSteps,
        onComplete: () {
          TutorialService.markTutorialCompleted(TutorialIds.portfolioTracker);
        },
      ),
    );
  }
}
