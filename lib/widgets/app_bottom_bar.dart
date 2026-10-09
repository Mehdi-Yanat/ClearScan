import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared bottom navigation: Home · Documents · [Scan] · Settings · Profile.
/// Index: 0 Home, 1 Documents, 2 Settings, 3 Profile. The scan button is separate.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onScan,
  });

  final int selectedIndex;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    // Use the app palette (not colorScheme.outline / onSurfaceVariant, which
    // are tonal values derived from the seed color and differ from AppColors).
    final bgColor = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final primary = AppColors.primary(context);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 94,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 68,
              // Material (not a colored Container) so the nav item ripples
              // are visible.
              child: Material(
                color: bgColor,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          Icons.home_outlined,
                          Icons.home_rounded,
                          'Home',
                          0,
                          selectedIndex,
                          '/home',
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          Icons.description_outlined,
                          Icons.description_rounded,
                          'Documents',
                          1,
                          selectedIndex,
                          '/documents',
                        ),
                      ),
                      const SizedBox(width: 84),
                      Expanded(
                        child: _NavItem(
                          Icons.build_outlined,
                          Icons.build_rounded,
                          'Settings',
                          2,
                          selectedIndex,
                          '/settings',
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          Icons.person_outline_rounded,
                          Icons.person_rounded,
                          'Profile',
                          3,
                          selectedIndex,
                          '/profile',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onScan,
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.primaryLight(context),
                      size: 28,
                    ),
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

class _NavItem extends StatelessWidget {
  const _NavItem(
    this.icon,
    this.activeIcon,
    this.label,
    this.index,
    this.selectedIndex,
    this.route,
  );

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final String route;

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    final color = selected
        ? AppColors.primary(context)
        : AppColors.textMuted(context);

    return InkWell(
      onTap: () {
        if (!selected) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
