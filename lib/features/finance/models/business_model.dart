/// Represents a strategic business decision presented to the user.
class BusinessDecision {
  /// Unique identifier of the decision.
  final String id;

  /// Title of the business scenario.
  final String title;

  /// Detailed description of the situation requiring a decision.
  final String description;

  /// The list of available options to resolve the situation.
  final List<DecisionOption> options;

  /// The business stage required for this decision to trigger.
  final BusinessStage requiredStage;

  /// Creates a [BusinessDecision].
  BusinessDecision({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
    required this.requiredStage,
  });
}

/// Preset business decisions
class BusinessDecisions {
  /// All predefined business decisions available in the simulation.
  static final List<BusinessDecision> all = [
    BusinessDecision(
      id: 'marketing_campaign',
      title: 'Marketing Campaign',
      description: 'Invest in marketing to boost revenue?',
      requiredStage: BusinessStage.startup,
      options: [
        DecisionOption(
          label: 'Social Media Ads (\$2000)',
          cashImpact: -2000,
          revenueImpact: 1500,
          outcome: 'Moderate reach, good ROI',
        ),
        DecisionOption(
          label: 'Traditional Marketing (\$5000)',
          cashImpact: -5000,
          revenueImpact: 3000,
          outcome: 'Wide reach, expensive',
        ),
        DecisionOption(
          label: 'Skip for now',
          cashImpact: 0,
          revenueImpact: 0,
          outcome: 'No change',
        ),
      ],
    ),
    BusinessDecision(
      id: 'expansion',
      title: 'Business Expansion',
      description: 'Ready to expand operations?',
      requiredStage: BusinessStage.growth,
      options: [
        DecisionOption(
          label: 'Open new location (\$20000)',
          cashImpact: -20000,
          revenueImpact: 8000,
          outcome: 'New revenue stream',
        ),
        DecisionOption(
          label: 'Online expansion (\$5000)',
          cashImpact: -5000,
          revenueImpact: 4000,
          outcome: 'Lower cost, steady growth',
        ),
        DecisionOption(
          label: 'Stay focused',
          cashImpact: 0,
          revenueImpact: 0,
          outcome: 'No change',
        ),
      ],
    ),
  ];
}

/// Represents the current lifecycle stage of a business.
enum BusinessStage {
  /// Initial stage where the business is being established.
  startup,

  /// Stage of rapid expansion and increasing revenue.
  growth,

  /// Stage where the business has reached its peak market share.
  maturity,

  /// Stage where revenue and market relevance are decreasing.
  decline,
}

/// Represents the comprehensive state of a business in the simulation.
class BusinessState {
  /// The current lifecycle stage of the business.
  final BusinessStage stage;

  /// Total liquid capital available to the business.
  final double cash;

  /// Projected revenue for the current month.
  final double monthlyRevenue;

  /// Projected operational expenses for the current month (excluding payroll).
  final double monthlyExpenses;

  /// List of current employees on the payroll.
  final List<Employee> employees;

  /// Historical record of monthly cash flow.
  final List<CashFlowEntry> cashFlowHistory;

  /// Cumulative months since the business started.
  final int monthsInBusiness;

  /// Breakdown of fixed operational costs.
  final Map<String, double> fixedCosts;

  /// Breakdown of variable operational costs.
  final Map<String, double> variableCosts;

  /// List of strategic decisions currently available to the user.
  final List<BusinessDecision> availableDecisions;

  /// Creates a [BusinessState].
  BusinessState({
    required this.stage,
    required this.cash,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.employees,
    required this.cashFlowHistory,
    required this.monthsInBusiness,
    required this.fixedCosts,
    required this.variableCosts,
    required this.availableDecisions,
  });

  /// Calculated net income (revenue minus expenses and payroll).
  double get netIncome => monthlyRevenue - monthlyExpenses - totalPayroll;

  /// Sum of all fixed operational costs.
  double get totalFixedCosts => fixedCosts.values.fold(0, (sum, v) => sum + v);

  /// Total monthly payroll expense for all employees.
  double get totalPayroll =>
      employees.fold(0, (sum, e) => sum + e.monthlySalary);

  /// Sum of all variable operational costs based on current activity.
  double get totalVariableCosts =>
      variableCosts.values.fold(0, (sum, v) => sum + v);

  /// Creates a copy of this [BusinessState] with optional field overrides.
  BusinessState copyWith({
    BusinessStage? stage,
    double? cash,
    double? monthlyRevenue,
    double? monthlyExpenses,
    List<Employee>? employees,
    List<CashFlowEntry>? cashFlowHistory,
    int? monthsInBusiness,
    Map<String, double>? fixedCosts,
    Map<String, double>? variableCosts,
    List<BusinessDecision>? availableDecisions,
  }) {
    return BusinessState(
      stage: stage ?? this.stage,
      cash: cash ?? this.cash,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      employees: employees ?? this.employees,
      cashFlowHistory: cashFlowHistory ?? this.cashFlowHistory,
      monthsInBusiness: monthsInBusiness ?? this.monthsInBusiness,
      fixedCosts: fixedCosts ?? this.fixedCosts,
      variableCosts: variableCosts ?? this.variableCosts,
      availableDecisions: availableDecisions ?? this.availableDecisions,
    );
  }

  /// Creates the initial state for a new business simulation.
  static BusinessState initial() {
    return BusinessState(
      stage: BusinessStage.startup,
      cash: 50000, // Starting capital
      monthlyRevenue: 5000,
      monthlyExpenses: 0,
      employees: [],
      cashFlowHistory: [],
      monthsInBusiness: 0,
      fixedCosts: {
        'Rent': 2000,
        'Utilities': 500,
        'Insurance': 300,
      },
      variableCosts: {
        'Marketing': 1000,
        'Supplies': 500,
      },
      availableDecisions: [],
    );
  }
}

/// Represents a record of cash flow for a specific billing period.
class CashFlowEntry {
  /// The date of the record.
  final DateTime date;

  /// Total revenue received during the period.
  final double revenue;

  /// Total expenses incurred during the period.
  final double expenses;

  /// The net change in cash (revenue minus expenses).
  final double netCashFlow;

  /// The total cash balance at the end of the period.
  final double endingBalance;

  /// Creates a [CashFlowEntry].
  CashFlowEntry({
    required this.date,
    required this.revenue,
    required this.expenses,
    required this.netCashFlow,
    required this.endingBalance,
  });
}

/// Represents an option within a [BusinessDecision] and its projected impacts.
class DecisionOption {
  /// Display label for the option.
  final String label;

  /// The immediate impact on liquid cash.
  final double cashImpact;

  /// The projected impact on monthly revenue.
  final double revenueImpact;

  /// A description of the likely outcome of choosing this option.
  final String outcome;

  /// Creates a [DecisionOption].
  DecisionOption({
    required this.label,
    required this.cashImpact,
    required this.revenueImpact,
    required this.outcome,
  });
}

/// Represents an individual employed by the business.
class Employee {
  /// Unique identifier of the employee.
  final String id;

  /// Full name of the employee.
  final String name;

  /// Professional role or title of the employee.
  final String role;

  /// The monthly salary paid to the employee.
  final double monthlySalary;

  /// The date the employee was hired.
  final DateTime hiredDate;

  /// Creates an [Employee] instance.
  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.monthlySalary,
    required this.hiredDate,
  });
}
