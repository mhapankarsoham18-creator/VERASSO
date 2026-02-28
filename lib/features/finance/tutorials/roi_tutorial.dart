import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/ui/tutorial_overlay.dart';

/// Tutorial steps for ROI Simulator
final List<TutorialStep> roiTutorialSteps = [
  const TutorialStep(
    title: 'Welcome to ROI Simulator!',
    description:
        'Learn how to calculate investment returns over time with compound interest. This tool helps you understand the power of long-term investing.',
    icon: LucideIcons.trendingUp,
  ),
  const TutorialStep(
    title: 'Set Your Initial Investment',
    description:
        'Use the Principal slider to adjust your starting investment amount. This is the amount you\'re investing today.',
    icon: LucideIcons.dollarSign,
  ),
  const TutorialStep(
    title: 'Expected Return Rate',
    description:
        'Set your expected annual return rate. Historical stock market returns average around 7-10% per year.',
    icon: LucideIcons.percent,
  ),
  const TutorialStep(
    title: 'Investment Duration',
    description:
        'Choose how many years you plan to invest. The longer the timeframe, the more compound interest works in your favor!',
    icon: LucideIcons.clock,
  ),
  const TutorialStep(
    title: 'Monthly Contributions',
    description:
        'Add regular monthly contributions to accelerate your wealth building. Even small amounts add up over time!',
    icon: LucideIcons.calendar,
  ),
  const TutorialStep(
    title: 'Inflation Adjustment',
    description:
        'Toggle inflation adjustment to see your real purchasing power. This shows what your money will actually be worth in the future.',
    icon: LucideIcons.activity,
  ),
  const TutorialStep(
    title: 'Watch It Grow!',
    description:
        'The chart visualizes your investment growth over time. The higher the curve, the more your money compounds! Start experimenting with different values.',
    icon: LucideIcons.lineChart,
  ),
];
