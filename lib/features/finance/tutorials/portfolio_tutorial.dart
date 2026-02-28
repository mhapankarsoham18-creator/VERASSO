import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/ui/tutorial_overlay.dart';

/// Tutorial steps for Portfolio Tracker
final List<TutorialStep> portfolioTutorialSteps = [
  const TutorialStep(
    title: 'Welcome to Portfolio Tracker!',
    description:
        'Build and manage your investment portfolio with real-time tracking. Learn about diversification and trading strategies!',
    icon: LucideIcons.pieChart,
  ),
  const TutorialStep(
    title: 'Your Portfolio Dashboard',
    description:
        'The Portfolio tab shows your total value, cash balance, invested amount, and overall return percentage. This is your financial snapshot!',
    icon: LucideIcons.layoutDashboard,
  ),
  const TutorialStep(
    title: 'Diversification Chart',
    description:
        'The pie chart visualizes your asset allocation. Good diversification spreads risk across different sectors and asset types.',
    icon: LucideIcons.target,
  ),
  const TutorialStep(
    title: 'Browse the Market',
    description:
        'Switch to the Market tab to see available assets. Each asset shows current price, sector, and a mini price history chart.',
    icon: LucideIcons.store,
  ),
  const TutorialStep(
    title: 'Buy Assets',
    description:
        'Click the Buy button to purchase assets. Enter the number of units you want. Each purchase earns you XP!',
    icon: LucideIcons.shoppingCart,
  ),
  const TutorialStep(
    title: 'Sell for Profit',
    description:
        'When you own an asset, you can sell it. Sell at a higher price than you bought to make a profit and earn bonus XP!',
    icon: LucideIcons.trendingUp,
  ),
  const TutorialStep(
    title: 'Stay Informed',
    description:
        'Check the News tab for market events that might affect asset prices. Use this information to make smart trading decisions!',
    icon: LucideIcons.newspaper,
  ),
  const TutorialStep(
    title: 'Transaction History',
    description:
        'The History tab logs all your buys and sells. Track your trading activity and learn from your investment decisions!',
    icon: LucideIcons.history,
  ),
];
