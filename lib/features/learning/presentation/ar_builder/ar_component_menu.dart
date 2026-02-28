import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

/// Component selection menu for AR builder
class ArComponentMenu extends StatefulWidget {
  /// Callback triggered when a component is selected from the menu.
  final Function(String componentId, String name, String category)
      onComponentSelected;

  /// Callback triggered when the menu is closed.
  final VoidCallback onClose;

  /// Creates an [ArComponentMenu] instance.
  const ArComponentMenu({
    super.key,
    required this.onComponentSelected,
    required this.onClose,
  });

  @override
  State<ArComponentMenu> createState() => _ArComponentMenuState();
}

/// Component menu item model
/// Model representing an item in the component selection menu.
class ComponentMenuItem {
  /// Unique identifier for the component library item.
  final String id;

  /// Display name of the component.
  final String name;

  /// Visual icon for the component.
  final IconData icon;

  /// Geometric color associated with the component category.
  final Color color;

  /// Creates a [ComponentMenuItem] instance.
  const ComponentMenuItem(this.id, this.name, this.icon, this.color);
}

class _ArComponentMenuState extends State<ArComponentMenu>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<ComponentMenuItem>> _categories = {
    'Power': [
      const ComponentMenuItem(
          'battery_aa', 'AA Battery', LucideIcons.battery, Colors.redAccent),
      const ComponentMenuItem(
          'battery_9v', '9V Battery', LucideIcons.battery, Colors.red),
    ],
    'Resistors': [
      const ComponentMenuItem(
          'resistor_100', '100Ω', LucideIcons.wind, Colors.orangeAccent),
      const ComponentMenuItem(
          'resistor_220', '220Ω', LucideIcons.wind, Colors.orange),
      const ComponentMenuItem(
          'resistor_1k', '1kΩ', LucideIcons.wind, Colors.deepOrange),
      const ComponentMenuItem(
          'resistor_10k', '10kΩ', LucideIcons.wind, Colors.deepOrangeAccent),
    ],
    'LEDs': [
      const ComponentMenuItem(
          'led_red', 'Red LED', LucideIcons.lightbulb, Colors.redAccent),
      const ComponentMenuItem(
          'led_green', 'Green LED', LucideIcons.lightbulb, Colors.greenAccent),
      const ComponentMenuItem(
          'led_blue', 'Blue LED', LucideIcons.lightbulb, Colors.blueAccent),
    ],
    'Others': [
      const ComponentMenuItem('capacitor_100u', '100µF Cap',
          LucideIcons.database, Colors.purpleAccent),
      const ComponentMenuItem(
          'capacitor_10u', '10µF Cap', LucideIcons.database, Colors.purple),
      const ComponentMenuItem(
          'switch_spst', 'Switch', LucideIcons.toggleRight, Colors.greenAccent),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: EdgeInsets.zero,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Component',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: _categories.keys
                  .map((category) => Tab(text: category))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Component grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.entries.map((entry) {
                  return _buildComponentGrid(entry.key, entry.value);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1.0, end: 0.0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  Widget _buildComponentCard(
      ComponentMenuItem item, String category, int index) {
    return GestureDetector(
      onTap: () => widget.onComponentSelected(item.id, item.name, category),
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: item.color.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 32, color: item.color),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate().scale(delay: (index * 50).ms),
    );
  }

  Widget _buildComponentGrid(String category, List<ComponentMenuItem> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildComponentCard(item, category.toLowerCase(), index);
      },
    );
  }
}
