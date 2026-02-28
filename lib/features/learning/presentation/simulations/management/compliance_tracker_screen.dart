import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A simulation screen for tracking ROC & SEBI compliance filings.
///
/// Provides a structured checklist of mandatory corporate filings with
/// due dates, statuses, and descriptions to help students understand
/// the compliance lifecycle of a registered company.
class ComplianceTrackerScreen extends StatefulWidget {
  /// Creates a [ComplianceTrackerScreen] instance.
  const ComplianceTrackerScreen({super.key});

  @override
  State<ComplianceTrackerScreen> createState() =>
      _ComplianceTrackerScreenState();
}

class _ComplianceFiling {
  final String form;
  final String title;
  final String description;
  final String dueDate;
  final String authority;
  final String penalty;
  bool isCompleted;

  _ComplianceFiling({
    required this.form,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.authority,
    required this.penalty,
    required this.isCompleted,
  });
}

class _ComplianceTrackerScreenState extends State<ComplianceTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_ComplianceFiling> _rocFilings = [
    _ComplianceFiling(
      form: 'MGT-7',
      title: 'Annual Return',
      description: 'Must be filed within 60 days from AGM. Contains details of '
          'shareholders, directors, and share capital.',
      dueDate: 'Within 60 days of AGM',
      authority: 'ROC',
      penalty: '₹100/day (max ₹5,00,000)',
      isCompleted: false,
    ),
    _ComplianceFiling(
      form: 'AOC-4',
      title: 'Financial Statements',
      description: 'Filing of Balance Sheet, P&L, Cash Flow with ROC within '
          '30 days of AGM.',
      dueDate: 'Within 30 days of AGM',
      authority: 'ROC',
      penalty: '₹100/day per document',
      isCompleted: false,
    ),
    _ComplianceFiling(
      form: 'DIR-12',
      title: 'Change in Directors',
      description: 'To be filed within 30 days of appointment, resignation, '
          'or change in designation of a director.',
      dueDate: 'Within 30 days of change',
      authority: 'ROC',
      penalty: '₹50,000 – ₹5,00,000',
      isCompleted: false,
    ),
    _ComplianceFiling(
      form: 'ADT-1',
      title: 'Appointment of Auditor',
      description:
          'Filed within 15 days of AGM where the auditor is appointed.',
      dueDate: 'Within 15 days of AGM',
      authority: 'ROC',
      penalty: '₹300/day of default',
      isCompleted: false,
    ),
    _ComplianceFiling(
      form: 'INC-20A',
      title: 'Declaration for Commencement',
      description:
          'Declaration that every subscriber has paid the value of shares '
          'agreed. Filed within 180 days of incorporation.',
      dueDate: 'Within 180 days of incorporation',
      authority: 'ROC',
      penalty: '₹50,000 + ₹1,000/day',
      isCompleted: false,
    ),
  ];

  final List<_ComplianceFiling> _sebiFilings = [
    _ComplianceFiling(
      form: 'LODR Reg. 33',
      title: 'Quarterly Financial Results',
      description:
          'Listed companies must submit standalone/consolidated financial '
          'results within 45 days of quarter end.',
      dueDate: '45 days from quarter end',
      authority: 'SEBI (LODR)',
      penalty: 'Fine + trading suspension risk',
      isCompleted: false,
    ),
    _ComplianceFiling(
      form: 'LODR Reg. 31',
      title: 'Shareholding Pattern',
      description:
          'Disclosure of promoter and public shareholding within 21 days '
          'of each quarter end.',
      dueDate: '21 days from quarter end',
      authority: 'SEBI (LODR)',
      penalty: '₹5,000/day of default',
      isCompleted: false,
    ),
    _ComplianceFiling(
      form: 'SAST Reg. 29',
      title: 'Substantial Acquisition Disclosure',
      description: 'Any person acquiring 5%+ shares must disclose to the stock '
          'exchange within 2 working days.',
      dueDate: '2 working days of acquisition',
      authority: 'SEBI (SAST)',
      penalty: '₹25 crore or 3× profit',
      isCompleted: false,
    ),
    _ComplianceFiling(
      form: 'PIT Reg. 7',
      title: 'Insider Trading Disclosure',
      description: 'Designated persons must disclose trades exceeding ₹10 lakh '
          'within 2 trading days.',
      dueDate: '2 trading days of trade',
      authority: 'SEBI (PIT)',
      penalty: '₹25 crore or 3× profit',
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rocPercent = _completionPercent(_rocFilings);
    final sebiPercent = _completionPercent(_sebiFilings);
    final overallPercent =
        _completionPercent([..._rocFilings, ..._sebiFilings]);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Compliance Tracker'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigoAccent,
          tabs: [
            Tab(
                text:
                    'ROC (${_completedCount(_rocFilings)}/${_rocFilings.length})'),
            Tab(
                text:
                    'SEBI (${_completedCount(_sebiFilings)}/${_sebiFilings.length})'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            const SizedBox(height: 140),

            // Overall Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Compliance',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('${overallPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: overallPercent == 100
                                    ? Colors.greenAccent
                                    : Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: overallPercent / 100,
                        minHeight: 10,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallPercent == 100
                              ? Colors.greenAccent
                              : Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniStat(
                            label: 'ROC',
                            value: '${rocPercent.toStringAsFixed(0)}%',
                            color: Colors.blueAccent),
                        _MiniStat(
                            label: 'SEBI',
                            value: '${sebiPercent.toStringAsFixed(0)}%',
                            color: Colors.purpleAccent),
                        _MiniStat(
                            label: 'Total',
                            value: '${_completedCount([
                                  ..._rocFilings,
                                  ..._sebiFilings
                                ])}/${_rocFilings.length + _sebiFilings.length}',
                            color: Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFilingList(_rocFilings),
                  _buildFilingList(_sebiFilings),
                ],
              ),
            ),
          ],
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
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildFilingList(List<_ComplianceFiling> filings) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filings.length,
      itemBuilder: (context, index) {
        final filing = filings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            color: filing.isCompleted
                ? Colors.greenAccent.withValues(alpha: 0.05)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(filing.form,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.indigoAccent)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(filing.authority,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white54)),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: filing.isCompleted,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) {
                        setState(() {
                          filing.isCompleted = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(filing.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: filing.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: filing.isCompleted
                            ? Colors.white38
                            : Colors.white)),
                const SizedBox(height: 4),
                Text(filing.description,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.clock,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(filing.dueDate,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.amber)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle,
                        size: 14, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Penalty: ${filing.penalty}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _completedCount(List<_ComplianceFiling> filings) =>
      filings.where((f) => f.isCompleted).length;

  double _completionPercent(List<_ComplianceFiling> filings) =>
      filings.isEmpty ? 0 : (_completedCount(filings) / filings.length) * 100;
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }
}
