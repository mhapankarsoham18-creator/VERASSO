import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/services/tutorial_service.dart';
import '../../../core/ui/tutorial_overlay.dart';
import '../../gamification/presentation/user_stats_controller.dart';
import '../models/business_model.dart';
import '../services/business_service.dart';
import '../tutorials/business_tutorial.dart';

/// Simulation of a startup’s lifecycle, letting learners adjust revenue,
/// costs, and hiring decisions to see cash flow and stage changes over time.
class BusinessWorkflow extends ConsumerStatefulWidget {
  /// Creates a [BusinessWorkflow] instance.
  const BusinessWorkflow({super.key});

  @override
  ConsumerState<BusinessWorkflow> createState() => _BusinessWorkflowState();
}

class _BusinessWorkflowState extends ConsumerState<BusinessWorkflow>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BusinessState _business;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Business Workflow'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
            Tab(text: 'Dashboard'),
            Tab(text: 'Finances'),
            Tab(text: 'Team'),
            Tab(text: 'Decisions'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(),
            _buildFinancesTab(),
            _buildTeamTab(),
            _buildDecisionsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _advanceMonth,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(LucideIcons.fastForward),
        label: const Text('Next Month'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _business = BusinessState.initial();
    _loadBusinessState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final completed = await TutorialService.isTutorialCompleted(
          TutorialIds.businessWorkflow);
      if (!completed && mounted) {
        _showTutorial();
      }
    });
  }

  void _adjustRevenue(double delta) {
    setState(() {
      _business = _business.copyWith(
        monthlyRevenue: (_business.monthlyRevenue + delta).clamp(0, 1000000),
      );
    });
    _saveState();
  }

  void _advanceMonth() {
    final revenue = _business.monthlyRevenue;
    final expenses = _business.totalFixedCosts +
        _business.totalVariableCosts +
        _business.totalPayroll;
    final netCashFlow = revenue - expenses;
    final newCash = _business.cash + netCashFlow;

    // Add cash flow entry
    final cashFlowEntry = CashFlowEntry(
      date: DateTime.now().add(Duration(days: 30 * _business.monthsInBusiness)),
      revenue: revenue,
      expenses: expenses,
      netCashFlow: netCashFlow,
      endingBalance: newCash,
    );

    // Determine stage based on performance
    BusinessStage newStage = _business.stage;
    if (_business.monthsInBusiness >= 12 && revenue >= 20000) {
      newStage = BusinessStage.growth;
    } else if (_business.monthsInBusiness >= 24 && revenue >= 50000) {
      newStage = BusinessStage.maturity;
    }

    setState(() {
      _business = _business.copyWith(
        cash: newCash,
        monthlyExpenses: expenses,
        monthsInBusiness: _business.monthsInBusiness + 1,
        cashFlowHistory: [..._business.cashFlowHistory, cashFlowEntry],
        stage: newStage,
      );
    });

    _saveState();

    if (newCash <= 0) {
      _showGameOver();
    }
  }

  Widget _buildCostItem(String name, double amount, String category) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text('\$${amount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.orangeAccent)),
              PopupMenuButton<double>(
                icon: const Icon(LucideIcons.moreVertical,
                    color: Colors.white54, size: 18),
                onSelected: (value) => _updateCost(category, name, value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: amount + 100, child: const Text('+\$100')),
                  PopupMenuItem(
                      value: (amount - 100).clamp(0, double.infinity),
                      child: const Text('-\$100')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 80),
      child: Column(
        children: [
          // Stage & Months
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _getStageName(_business.stage).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                Text(
                  'BUSINESS PERFORMANCE',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text('Month ${_business.monthsInBusiness}',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPIs
          Row(
            children: [
              Expanded(
                  child: _buildKPICard(
                      'Cash',
                      '\$${_business.cash.toStringAsFixed(0)}',
                      LucideIcons.dollarSign,
                      Colors.greenAccent)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKPICard(
                      'Revenue',
                      '\$${_business.monthlyRevenue.toStringAsFixed(0)}',
                      LucideIcons.trendingUp,
                      Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildKPICard(
                      'Expenses',
                      '\$${_business.monthlyExpenses.toStringAsFixed(0)}',
                      LucideIcons.trendingDown,
                      Colors.redAccent)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKPICard('Team', '${_business.employees.length}',
                      LucideIcons.users, Colors.purpleAccent)),
            ],
          ),
          const SizedBox(height: 16),

          // Cash Flow Chart
          if (_business.cashFlowHistory.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text('Cash Flow History',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            GlassContainer(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _business.cashFlowHistory.asMap().entries.map((e) {
                        return FlSpot(
                            e.key.toDouble(), e.value.endingBalance / 1000);
                      }).toList(),
                      isCurved: true,
                      color: Colors.greenAccent,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecisionCard(BusinessDecision decision) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(decision.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(decision.description,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ...decision.options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _business = _business.copyWith(
                        cash: _business.cash + option.cashImpact,
                        monthlyRevenue:
                            _business.monthlyRevenue + option.revenueImpact,
                      );
                    });
                    _saveState();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(option.outcome)),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(option.label)),
                      if (option.revenueImpact != 0)
                        Text(
                          '${option.revenueImpact > 0 ? '+' : ''}\$${option.revenueImpact.toStringAsFixed(0)}/mo',
                          style: TextStyle(
                            fontSize: 12,
                            color: option.revenueImpact > 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDecisionsTab() {
    final availableDecisions = BusinessDecisions.all
        .where((d) => d.requiredStage == _business.stage)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 80),
      child: Column(
        children: [
          if (availableDecisions.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No decisions available at this stage.',
                  style: TextStyle(color: Colors.white54)),
            ))
          else
            ...availableDecisions
                .map((decision) => _buildDecisionCard(decision)),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Text(employee.name[0],
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(employee.role,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
          Text('\$${employee.monthlySalary.toStringAsFixed(0)}/mo',
              style: const TextStyle(
                  color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinancesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Control
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Revenue',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('\$${_business.monthlyRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 24, color: Colors.greenAccent)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _adjustRevenue(1000),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('+\$1000'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _adjustRevenue(-1000),
                      icon: const Icon(LucideIcons.minus, size: 16),
                      label: const Text('-\$1000'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fixed Costs
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('Fixed Costs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ..._business.fixedCosts.entries
              .map((e) => _buildCostItem(e.key, e.value, 'fixed')),

          const SizedBox(height: 16),

          // Variable Costs
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('Variable Costs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ..._business.variableCosts.entries
              .map((e) => _buildCostItem(e.key, e.value, 'variable')),

          const SizedBox(height: 16),

          // Summary
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryRow('Total Revenue', _business.monthlyRevenue,
                    Colors.greenAccent),
                _buildSummaryRow('Fixed Costs', _business.totalFixedCosts,
                    Colors.orangeAccent),
                _buildSummaryRow('Variable Costs', _business.totalVariableCosts,
                    Colors.orangeAccent),
                _buildSummaryRow(
                    'Payroll', _business.totalPayroll, Colors.orangeAccent),
                const Divider(color: Colors.white24),
                _buildSummaryRow(
                    'Net Income',
                    _business.netIncome,
                    _business.netIncome >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text('\$${amount.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 140, left: 16, right: 16, bottom: 80),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Employees',
                        style: TextStyle(color: Colors.white70)),
                    Text('${_business.employees.length}',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Monthly Payroll',
                        style: TextStyle(color: Colors.white70)),
                    Text('\$${_business.totalPayroll.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_business.employees.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No employees yet. Hire your first team member!',
                  style: TextStyle(color: Colors.white54)),
            ))
          else
            ..._business.employees.map((e) => _buildEmployeeCard(e)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _business.cash >= 5000 ? _hireEmployee : null,
            icon: const Icon(LucideIcons.userPlus),
            label: const Text('Hire Employee'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getStageName(BusinessStage stage) {
    switch (stage) {
      case BusinessStage.startup:
        return 'Startup';
      case BusinessStage.growth:
        return 'Growth';
      case BusinessStage.maturity:
        return 'Maturity';
      case BusinessStage.decline:
        return 'Decline';
    }
  }

  void _hireEmployee() {
    final roles = ['Developer', 'Marketer', 'Sales Rep', 'Designer', 'Support'];
    final salaries = [5000, 4000, 4500, 4000, 3500];
    final random = Random();
    final index = random.nextInt(roles.length);

    final employee = Employee(
      id: DateTime.now().toString(),
      name: 'Employee ${_business.employees.length + 1}',
      role: roles[index],
      monthlySalary: salaries[index].toDouble(),
      hiredDate: DateTime.now(),
    );

    setState(() {
      _business = _business.copyWith(
        employees: [..._business.employees, employee],
      );
    });
    _saveState();
  }

  Future<void> _loadBusinessState() async {
    final savedState =
        await ref.read(businessServiceProvider).loadBusinessState();
    if (savedState != null && mounted) {
      setState(() {
        _business = savedState;
      });
    }
  }

  Future<void> _saveState() async {
    await ref.read(businessServiceProvider).saveBusinessState(_business);
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Business Failed!',
            style: TextStyle(color: Colors.redAccent)),
        content: const Text('You ran out of cash. Better luck next time!',
            style: TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _business = BusinessState.initial();
              });
              _saveState();
            },
            child: const Text('Start Over'),
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: businessTutorialSteps,
        onComplete: () {
          TutorialService.markTutorialCompleted(TutorialIds.businessWorkflow);
          ref.read(userStatsProvider.notifier).addXP(200);
        },
      ),
    );
  }

  void _updateCost(String category, String key, double value) {
    setState(() {
      if (category == 'fixed') {
        final newCosts = Map<String, double>.from(_business.fixedCosts);
        newCosts[key] = value;
        _business = _business.copyWith(fixedCosts: newCosts);
      } else {
        final newCosts = Map<String, double>.from(_business.variableCosts);
        newCosts[key] = value;
        _business = _business.copyWith(variableCosts: newCosts);
      }
    });
    _saveState();
  }

  // Emojis removed as per professional design standards
}
