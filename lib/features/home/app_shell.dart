import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  
  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      body: navigationShell,
      bottomNavigationBar: isKeyboardOpen ? const SizedBox.shrink() : Container(
        decoration: const BoxDecoration(
          color: AppColors.neutralBg,
          border: Border(top: BorderSide(color: AppColors.blockEdge, width: 2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              offset: Offset(0, -4),
              blurRadius: 0,
            )
          ]
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.home_filled, 'Home', 0),
                _buildNavItem(context, Icons.backpack, 'Study Tools', 1),
                _buildNavItem(context, Icons.auto_awesome, 'Astro', 2),
                _buildNavItem(context, Icons.explore, 'Discovery', 3),
                _buildNavItem(context, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = navigationShell.currentIndex == index;
    return GestureDetector(
      onTap: () => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 10, 
            color: isSelected ? AppColors.primary : AppColors.textSecondary, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }
}
