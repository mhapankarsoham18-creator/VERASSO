import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../services/pnl_calculator.dart';

/// A screen that provides a simplified tax estimation for federal income and
/// capital gains based on 2024 brackets.
class TaxEstimatorScreen extends StatefulWidget {
  /// Creates a [TaxEstimatorScreen] instance.
  const TaxEstimatorScreen({super.key});

  @override
  State<TaxEstimatorScreen> createState() => _TaxEstimatorScreenState();
}

class _TaxEstimatorScreenState extends State<TaxEstimatorScreen> {
  final _incomeController = TextEditingController(text: '50000');
  final _shortTermGainsController = TextEditingController(text: '0');
  final _longTermGainsController = TextEditingController(text: '0');

  String _filingStatus = 'single';
  double _estimatedTax = 0.0;
  double _effectiveRate = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Tax Estimator 2024', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Estimated Tax Bill',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_estimatedTax.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Effective Rate: ${_effectiveRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financial Details',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildInput('Annual Income', _incomeController,
                        LucideIcons.briefcase),
                    const SizedBox(height: 16),
                    _buildInput('Short Term Gains (< 1yr)',
                        _shortTermGainsController, LucideIcons.timer),
                    const SizedBox(height: 16),
                    _buildInput('Long Term Gains (> 1yr)',
                        _longTermGainsController, LucideIcons.calendarCheck),
                    const SizedBox(height: 16),
                    const Text('Filing Status',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filingStatus,
                          dropdownColor: Colors.grey[900],
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                                value: 'single', child: Text('Single')),
                            DropdownMenuItem(
                                value: 'married',
                                child: Text('Married Filing Jointly')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _filingStatus = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(LucideIcons.calculator),
                      label: const Text('CALCULATE TAXES'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const GlassContainer(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.amber, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This tool provides an estimate based on simplified 2024 tax brackets. Consult a professional for actual tax filing.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _calculate() {
    final income = double.tryParse(_incomeController.text) ?? 0.0;
    final shortTerm = double.tryParse(_shortTermGainsController.text) ?? 0.0;
    final longTerm = double.tryParse(_longTermGainsController.text) ?? 0.0;

    // Ordinary Income Tax (Income + Short Term)
    final ordinaryInc = income + shortTerm;
    // Calculate tax on ordinary income (simplified using same PnL logic)
    // We treat 'gain' as the whole income for estimation
    final ordinaryTax = PnLCalculator.estimateTax(
        gain: ordinaryInc,
        annualIncome: ordinaryInc,
        isLongTerm: false,
        filingStatus: _filingStatus);

    // Long Term Capital Gains Tax
    // This is stacked on top of ordinary income for bracket determination usually,
    // but simplified logic in PnLCalculator handles rate lookup based on total income.
    final totalIncome = ordinaryInc + longTerm;
    final capitalGainsTax = PnLCalculator.estimateTax(
        gain: longTerm,
        annualIncome: totalIncome, // Use total to find bracket
        isLongTerm: true,
        filingStatus: _filingStatus);

    setState(() {
      _estimatedTax = ordinaryTax + capitalGainsTax;
      if (totalIncome > 0) {
        _effectiveRate = (_estimatedTax / totalIncome) * 100;
      } else {
        _effectiveRate = 0.0;
      }
    });
  }
}
