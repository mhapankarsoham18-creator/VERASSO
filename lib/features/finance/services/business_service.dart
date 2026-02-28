import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../data/finance_repository.dart';
import '../models/business_model.dart';

/// Provider for [BusinessService].
final businessServiceProvider = Provider((ref) {
  final repository = ref.read(financeRepositoryProvider);
  return BusinessService(repository);
});

/// Business service to handle Supabase persistence
class BusinessService {
  final FinanceRepository _repository;

  /// Creates a [BusinessService] instance.
  BusinessService(this._repository);

  /// Auto-save business state periodically
  Future<void> autoSave(BusinessState state) async {
    // Save every 3 months or when cash is low
    if (state.monthsInBusiness % 3 == 0 || state.cash < 5000) {
      await saveBusinessState(state);
    }
  }

  /// Load saved business state from Supabase
  Future<BusinessState?> loadBusinessState() async {
    try {
      final data = await _repository.getBusinessState();
      if (data == null) return null;

      // Parse employees
      final employeesData = data['employees_data'] as List? ?? [];
      final employees = employeesData.map((e) {
        return Employee(
          id: e['id'],
          name: e['name'],
          role: e['role'],
          monthlySalary: double.parse(e['monthly_salary'].toString()),
          hiredDate: DateTime.parse(e['hired_date']),
        );
      }).toList();

      // Parse cash flow history
      final cashFlowData = data['cash_flow_history'] as List? ?? [];
      final cashFlowHistory = cashFlowData.map((c) {
        return CashFlowEntry(
          date: DateTime.parse(c['date']),
          revenue: double.parse(c['revenue'].toString()),
          expenses: double.parse(c['expenses'].toString()),
          netCashFlow: double.parse(c['net_cash_flow'].toString()),
          endingBalance: double.parse(c['ending_balance'].toString()),
        );
      }).toList();

      // Parse fixed and variable costs from JSON
      final fixedCostsData = data['fixed_costs'] ?? {};
      final variableCostsData = data['variable_costs'] ?? {};

      return BusinessState(
        stage: BusinessStage.values.firstWhere(
          (e) => e.name == data['stage'],
          orElse: () => BusinessStage.startup,
        ),
        cash: double.parse(data['cash'].toString()),
        monthlyRevenue: double.parse(data['revenue'].toString()),
        monthlyExpenses: double.parse(data['expenses'].toString()),
        monthsInBusiness: data['months_in_business'],
        employees: employees,
        cashFlowHistory: cashFlowHistory,
        fixedCosts: Map<String, double>.from(fixedCostsData),
        variableCosts: Map<String, double>.from(variableCostsData),
        availableDecisions: [],
      );
    } catch (e) {
      AppLogger.info('Error loading business state: $e');
      return null;
    }
  }

  /// Save business state to Supabase
  Future<void> saveBusinessState(BusinessState state) async {
    try {
      await _repository.saveBusinessState({
        'stage': state.stage.name,
        'cash': state.cash,
        'revenue': state.monthlyRevenue,
        'fixed_costs': state.totalFixedCosts,
        'variable_costs': state.totalVariableCosts,
        'expenses': state.monthlyExpenses,
        'months_in_business': state.monthsInBusiness,
        'employees_data': state.employees
            .map((e) => {
                  'id': e.id,
                  'name': e.name,
                  'role': e.role,
                  'monthly_salary': e.monthlySalary,
                  'hired_date': e.hiredDate.toIso8601String(),
                })
            .toList(),
        'cash_flow_history': state.cashFlowHistory
            .map((c) => {
                  'date': c.date.toIso8601String(),
                  'revenue': c.revenue,
                  'expenses': c.expenses,
                  'net_cash_flow': c.netCashFlow,
                  'ending_balance': c.endingBalance,
                })
            .toList(),
      });
    } catch (e) {
      AppLogger.info('Error saving business state: $e');
    }
  }
}
