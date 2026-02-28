import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/ui/tutorial_overlay.dart';

/// A list of instructional steps for the social feed onboarding tutorial.
final feedTutorialSteps = [
  const TutorialStep(
    title: 'Welcome to the Feed!',
    description:
        'This is where you can see what your friends and classmates are up to.',
    icon: LucideIcons.layoutGrid,
  ),
  const TutorialStep(
    title: 'Share Your Journey',
    description:
        'Tap here to create a new post, share an achievement, or ask a question.',
    icon: LucideIcons.penTool,
  ),
  const TutorialStep(
    title: 'Connect with Others',
    description:
        'Like and save posts to build your network and earn social points.',
    icon: LucideIcons.heart,
  ),
];
