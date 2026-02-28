import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/ui/tutorial_overlay.dart';

/// Tutorial steps for Accounting Simulator
final List<TutorialStep> accountingTutorialSteps = [
  const TutorialStep(
    title: 'Welcome to Accounting!',
    description:
        'Master double-entry bookkeeping with this Tally-style simulator. Learn how businesses track their financial transactions.',
    icon: LucideIcons.calculator,
  ),
  const TutorialStep(
    title: 'Double-Entry System',
    description:
        'Every transaction has two sides: a debit and a credit. This ensures the books always balance (Assets = Liabilities + Equity).',
    icon: LucideIcons.scale,
  ),
  const TutorialStep(
    title: 'Create Journal Entries',
    description:
        'Use the + button to create journal entries. Describe the transaction, choose accounts to debit and credit, and enter the amount.',
    icon: LucideIcons.plus,
  ),
  const TutorialStep(
    title: 'View Ledgers',
    description:
        'The Ledgers tab shows T-accounts for each account. See all debits on the left and credits on the right, just like in traditional accounting!',
    icon: LucideIcons.book,
  ),
  const TutorialStep(
    title: 'Trial Balance',
    description:
        'The Trial Balance verifies that total debits equal total credits. If they match, your books are balanced correctly!',
    icon: LucideIcons.checkCircle,
  ),
  const TutorialStep(
    title: 'Financial Statements',
    description:
        'The Statements tab auto-generates an Income Statement and Balance Sheet from your journal entries. See your financial performance!',
    icon: LucideIcons.fileText,
  ),
  const TutorialStep(
    title: 'Tips for Success',
    description:
        'Remember: Debits increase assets & expenses. Credits increase liabilities & revenue. Practice with different transactions to master accounting!',
    icon: LucideIcons.lightbulb,
  ),
];
