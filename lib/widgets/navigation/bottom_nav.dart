// ============================================================
// RAWBY — Bottom Navigation (Mobile)
// Floating translucent bar with 5 (or 6 for admin) items
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../providers/router_provider.dart';
import '../../theme/app_colors.dart';

class RawbyBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isAdmin;

  const RawbyBottomNav({
    super.key,
    required this.currentIndex,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = _buildItems(isAdmin);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? RawbyPalette.darkSurface.withOpacity(0.96)
            : RawbyPalette.lightSurface.withOpacity(0.96),
        border: Border(
          top: BorderSide(
            color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              final color = isSelected
                  ? theme.colorScheme.primary
                  : (isDark
                      ? RawbyPalette.textMutedDark
                      : RawbyPalette.textMutedLight);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.go(item.route);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static List<_NavItem> _buildItems(bool isAdmin) {
    final items = [
      _NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        route: Routes.home,
      ),
      _NavItem(
        label: 'Prompts',
        icon: Icons.lightbulb_outline,
        activeIcon: Icons.lightbulb,
        route: Routes.prompts,
      ),
      _NavItem(
        label: 'Board',
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard,
        route: Routes.leaderboard,
      ),
      _NavItem(
        label: 'Gear',
        icon: Icons.camera_outlined,
        activeIcon: Icons.camera,
        route: Routes.gear,
      ),
      _NavItem(
        label: 'Skills',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        route: Routes.skill,
      ),
    ];

    if (isAdmin) {
      items.add(_NavItem(
        label: 'Admin',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        route: Routes.admin,
      ));
    }

    return items;
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
