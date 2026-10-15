import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';

/// MainShell â€” persistent Bottom Navigation Bar shell.
/// Wraps Tab 1 (Basecamp) through Tab 5 (Profil).
/// No sidebar. This is pure native mobile navigation.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Basecamp',   icon: Icons.cottage_outlined,      activeIcon: Icons.cottage,           route: AppRoutes.basecamp),
    _NavItem(label: 'Belajar',    icon: Icons.explore_outlined,       activeIcon: Icons.explore,           route: AppRoutes.learn),
    _NavItem(label: 'Tantangan',  icon: Icons.bolt_outlined,          activeIcon: Icons.bolt,              route: AppRoutes.challenge),
    _NavItem(label: 'Sertifikat', icon: Icons.workspace_premium_outlined, activeIcon: Icons.workspace_premium, route: AppRoutes.certificate),
    _NavItem(label: 'Profil',     icon: Icons.person_outline,         activeIcon: Icons.person,            route: AppRoutes.profile),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = currentIndex == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(item.route),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primaryLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive ? AppColors.primary : AppColors.textTertiary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? AppColors.primary : AppColors.textTertiary,
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
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.route});
}

