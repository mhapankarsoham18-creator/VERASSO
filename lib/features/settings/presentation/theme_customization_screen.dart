import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';

/// Screen allowing users to customize their visual experience (Theme Forge).
class ThemeCustomizationScreen extends ConsumerWidget {
  /// Creates a [ThemeCustomizationScreen].
  const ThemeCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Theme Forge'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Essence',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ThemeStyle.values.map((style) {
                    final isSelected = themeState.style == style;
                    return GestureDetector(
                      onTap: () => themeNotifier.setThemeStyle(style),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: themeState.primaryColor, width: 2)
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getStyleIcon(style),
                                color: isSelected
                                    ? themeState.primaryColor
                                    : Colors.white54,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                style.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Core Glow (Primary)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(
                context,
                themeState.primaryColor,
                (color) => themeNotifier.setPrimaryColor(color),
              ),
              const SizedBox(height: 32),
              const Text(
                'Accent Spark (Secondary)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(
                context,
                themeState.accentColor,
                (color) => themeNotifier.setAccentColor(color),
              ),
              const SizedBox(height: 48),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sun, color: Colors.amber),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('Theme Mode'),
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeState.mode,
                      underline: const SizedBox(),
                      dropdownColor: Colors.black,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeNotifier.setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    final List<Color> colors = [
      const Color(0xFF00F2FF), // Tron Cyan
      const Color(0xFFFF00FF), // Neon Pink
      const Color(0xFFFFB800), // Amber
      const Color(0xFF740001), // Burgundy
      const Color(0xFF9D50BB), // Deep Purple
      const Color(0xFF2E7D32), // Emerald
      const Color(0xFFFF4500), // Sunset Red
      const Color(0xFFFFFFFF), // Pure White
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = currentColor.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white12,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getStyleIcon(ThemeStyle style) {
    switch (style) {
      case ThemeStyle.liquid:
        return LucideIcons.droplets;
      case ThemeStyle.midnight:
        return LucideIcons.moon;
      case ThemeStyle.tron:
        return LucideIcons.cpu;
      case ThemeStyle.bladeRunner:
        return LucideIcons.wind;
      case ThemeStyle.enchanted:
        return LucideIcons.sparkles;
      case ThemeStyle.nature:
        return LucideIcons.leaf;
      case ThemeStyle.sunset:
        return LucideIcons.sun;
      case ThemeStyle.hellblazer:
        return LucideIcons
            .skull; // Assuming an appropriate IconData for Hellblazer
    }
  }
}
