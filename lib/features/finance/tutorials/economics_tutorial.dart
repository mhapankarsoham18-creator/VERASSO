import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/ui/tutorial_overlay.dart';

/// Tutorial steps for Economics Hub
final List<TutorialStep> economicsTutorialSteps = [
  const TutorialStep(
    title: 'Macroeconomic Analysis Unit',
    description:
        'Understand supply and demand dynamics with interactive graphs. See how markets reach equilibrium and respond to shocks!',
    icon: LucideIcons.barChart,
  ),
  const TutorialStep(
    title: 'Economic Indicators',
    description:
        'Track key economic metrics at the top: GDP Growth, Inflation Rate, and Unemployment Rate. These shape the economic landscape!',
    icon: LucideIcons.activity,
  ),
  const TutorialStep(
    title: 'Supply & Demand Graph',
    description:
        'The graph shows supply (upward) and demand (downward) curves. Where they intersect is the equilibrium price and quantity!',
    icon: LucideIcons.gitMerge,
  ),
  const TutorialStep(
    title: 'Shift the Curves',
    description:
        'Use the Demand Shift and Supply Shift sliders to see how changes affect equilibrium. Notice how price and quantity adjust!',
    icon: LucideIcons.move,
  ),
  const TutorialStep(
    title: 'Market Scenarios',
    description:
        'Try preset scenarios like Recession, Boom, Pandemic, or Crisis. Each simulates real-world economic events and their market impacts!',
    icon: LucideIcons.zap,
  ),
  const TutorialStep(
    title: 'Real-World Applications',
    description:
        'These concepts explain how prices change in real markets. Supply shocks (like oil shortages) or demand surges (like Black Friday) work the same way!',
    icon: LucideIcons.globe,
  ),
];
