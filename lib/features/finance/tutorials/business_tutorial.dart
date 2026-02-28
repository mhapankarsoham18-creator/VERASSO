import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/ui/tutorial_overlay.dart';

/// Tutorial steps for Business Workflow
final List<TutorialStep> businessTutorialSteps = [
  const TutorialStep(
    title: 'Welcome to Business Workflow!',
    description:
        'Experience the complete business lifecycle from startup to maturity. Make strategic decisions and manage your cash flow!',
    icon: LucideIcons.briefcase,
  ),
  const TutorialStep(
    title: 'Business Stages',
    description:
        'Your business progresses through stages: Startup → Growth → Maturity → Decline. Each stage has unique challenges and opportunities!',
    icon: LucideIcons.trendingUp,
  ),
  const TutorialStep(
    title: 'Dashboard Overview',
    description:
        'Monitor your key metrics: cash position, monthly revenue, expenses, and months in business. The dash says it all!',
    icon: LucideIcons.layoutDashboard,
  ),
  const TutorialStep(
    title: 'Manage Finances',
    description:
        'In the Finances tab, adjust revenue and costs with sliders. See how changes impact your net income in real-time!',
    icon: LucideIcons.dollarSign,
  ),
  const TutorialStep(
    title: 'Build Your Team',
    description:
        'The Team tab lets you hire employees. Each employee costs money but can help grow your business. Balance payroll with revenue!',
    icon: LucideIcons.users,
  ),
  const TutorialStep(
    title: 'Make Decisions',
    description:
        'Face critical business decisions in the Decisions tab. Each choice affects your cash and revenue. Choose wisely!',
    icon: LucideIcons.gitBranch,
  ),
  const TutorialStep(
    title: 'Advance Time',
    description:
        'Click "Next Month" to simulate time passing. Your business evolves based on your decisions. Beware: if cash hits zero, it\'s game over!',
    icon: LucideIcons.fastForward,
  ),
];
