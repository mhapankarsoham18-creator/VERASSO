import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/learning/presentation/codedex/python_editor_screen.dart';

/// Codedex Menu Screen - Curriculum hub for Python learning
class CodedexMenuScreen extends StatelessWidget {
  /// Creates a [CodedexMenuScreen] instance.
  const CodedexMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Codedex - Python Hub'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
          children: [
            _CodedexModuleCard(
              title: 'Module 1: Python Basics',
              subtitle: 'Variables, Types & Syntax',
              icon: LucideIcons.terminalSquare,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PythonEditorScreen(
                    moduleTitle: 'Python Basics',
                    initialCode: 'print("Hello, World!")\n',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CodedexModuleCard(
              title: 'Module 2: Loops & Logic',
              subtitle: 'If/Else, Arrays & Iterators',
              icon: LucideIcons.gitBranch,
              color: Colors.greenAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PythonEditorScreen(
                    moduleTitle: 'Loops & Logic',
                    initialCode: 'for i in range(5):\n    print(i)\n',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CodedexModuleCard(
              title: 'Module 3: Functions & Sandbox',
              subtitle: 'Build your own logic with secure execution',
              icon: LucideIcons.code2,
              color: Colors.purpleAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PythonEditorScreen(
                    moduleTitle: 'Sandbox Mode',
                    initialCode:
                        'def calculate_area(radius):\n    import math\n    return math.pi * radius ** 2\n\nprint("Area:", calculate_area(5))\n',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodedexModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CodedexModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
