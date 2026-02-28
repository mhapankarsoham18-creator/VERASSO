/// Barrel file for the Finance feature.
///
/// Exposes the main public API for finance-related data, services, and UI.
library;

export 'data/broker_simulation_service.dart';
export 'data/finance_repository.dart';
export 'data/forecasting_ai_service.dart';
export 'data/transaction_model.dart';
export 'domain/models.dart';
export 'models/accounting_model.dart';
export 'models/business_model.dart';
export 'presentation/accounting_simulator.dart';
export 'presentation/analytics_screen.dart';
export 'presentation/business_workflow.dart';
export 'presentation/earnings_wallet_screen.dart';
export 'presentation/economics_hub.dart';
export 'presentation/finance_controller.dart';
export 'presentation/finance_dashboard_screen.dart';
export 'presentation/finance_hub.dart';
export 'presentation/portfolio_tracker.dart';
export 'presentation/roi_simulator.dart';
export 'presentation/tax_estimator_screen.dart';
export 'presentation/widgets/widgets.dart';
export 'services/business_service.dart';
export 'services/pnl_calculator.dart';
export 'services/portfolio_service.dart';
