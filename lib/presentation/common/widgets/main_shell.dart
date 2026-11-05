// ============================================================================
// File: main_shell.dart
// Deskripsi: Persistent bottom navigation shell for Metro Institute Mobile.
//            Menggunakan PageView halus dengan KeepAlive sehingga perpindahan
//            halaman berjalan dengan efek geser horizontal yang sangat smooth
//            (tanpa jeda, tanpa kejutan, 120 FPS).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../features/basecamp/screens/basecamp_screen.dart';
import '../../features/learn/screens/learn_screen.dart';
import '../../features/challenge/screens/challenge_screen.dart';
import '../../features/certificate/screens/certificate_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'custom_bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const List<String> _routes = [
    AppRoutes.basecamp,
    AppRoutes.learn,
    AppRoutes.challenge,
    AppRoutes.certificate,
    AppRoutes.profile,
  ];

  PageController? _pageController;
  int _currentIndex = 0;
  bool _isAnimating = false;

  int _getIndexForLocation(String location) {
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return -1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.toString();
    final index = _getIndexForLocation(location);

    if (index != -1) {
      if (_pageController == null) {
        _currentIndex = index;
        _pageController = PageController(initialPage: index);
      } else if (index != _currentIndex && !_isAnimating) {
        _currentIndex = index;
        if (_pageController!.hasClients) {
          _pageController!.jumpToPage(index);
        }
      }
    } else {
      _pageController ??= PageController();
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index >= 0 && index < _routes.length && index != _currentIndex && !_isAnimating) {
      _isAnimating = true;
      setState(() {
        _currentIndex = index;
      });

      _pageController?.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ).then((_) {
        _isAnimating = false;
      });

      if (context.mounted) {
        context.go(_routes[index]);
      }
    }
  }

  void _onPageChanged(int index) {
    if (!_isAnimating && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      if (context.mounted) {
        context.go(_routes[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isTabRoute = _getIndexForLocation(location) != -1;

    return Scaffold(
      extendBody: true,
      body: isTabRoute
          ? PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              children: const [
                _KeepAliveTab(child: BasecampScreen()),
                _KeepAliveTab(child: LearnScreen()),
                _KeepAliveTab(child: ChallengeScreen()),
                _KeepAliveTab(child: CertificateScreen()),
                _KeepAliveTab(child: ProfileScreen()),
              ],
            )
          : widget.child,
      bottomNavigationBar: isTabRoute
          ? CustomBottomNavBar(
              defaultIndex: _currentIndex,
              onItemSelected: _onBottomNavTapped,
            )
          : null,
    );
  }
}

/// Menjaga state masing-masing tab tetap aktif di memori
/// agar proses transisi geser horizontal tidak mengalami reload atau jank.
class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
