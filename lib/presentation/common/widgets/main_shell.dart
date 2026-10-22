import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import 'custom_bottom_nav_bar.dart';

/// MainShell — Persistent bottom navigation shell for Metro Institute Mobile.
/// Uses CustomBottomNavBar (Clean White Floating Pill with minimalist neutral grey
/// active focus, fixed active width, and calm smooth text animation).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const List<String> _routes = [
    AppRoutes.basecamp,
    AppRoutes.learn,
    AppRoutes.challenge,
    AppRoutes.certificate,
    AppRoutes.profile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        defaultIndex: currentIndex,
        onItemSelected: (index) {
          if (index >= 0 && index < _routes.length) {
            context.go(_routes[index]);
          }
        },
      ),
    );
  }
}
