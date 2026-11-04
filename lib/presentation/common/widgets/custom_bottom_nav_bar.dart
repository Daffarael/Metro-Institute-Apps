// ============================================================================
// File: custom_bottom_nav_bar.dart
// Deskripsi: Floating Bottom Navigation Bar dengan fisika Framer Motion Spring
//            (stiffness: 350, damping: 32), whileTap scale 0.97, dock putih bersih,
//            dan kapsul aktif abu-abu minimalis super clean.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kurva pegas fisika Framer Motion persis:
/// `type: "spring", stiffness: 350, damping: 32`
class FramerSpringCurve extends Curve {
  const FramerSpringCurve();

  @override
  double transformInternal(double t) {
    if (t >= 1.0) return 1.0;
    if (t <= 0.0) return 0.0;
    final timeSec = t * 0.320;
    const zeta = 0.855236; // 32 / (2 * sqrt(350))
    const omega0 = 18.7083; // sqrt(350)
    const omegaD = 9.6961; // omega0 * sqrt(1 - zeta^2)
    final envelope = math.exp(-zeta * omega0 * timeSec);
    final term = math.cos(omegaD * timeSec) + (zeta * omega0 / omegaD) * math.sin(omegaD * timeSec);
    return 1.0 - envelope * term;
  }
}

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class CustomBottomNavBar extends StatefulWidget {
  final int defaultIndex;
  final ValueChanged<int>? onItemSelected;
  final List<NavItem>? items;

  const CustomBottomNavBar({
    super.key,
    this.defaultIndex = 0,
    this.onItemSelected,
    this.items,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  late int _activeIndex;

  // Lebar maksimal label animasi sesuai acuan Framer Motion MOBILE_LABEL_WIDTH = 72
  static const double _mobileLabelWidth = 72.0;

  // --- MENU NAVIGASI METRO INSTITUTE ---
  static const List<NavItem> _defaultNavItems = [
    NavItem(
      label: "Basecamp",
      icon: Icons.cottage_outlined,
      activeIcon: Icons.cottage_rounded,
    ),
    NavItem(
      label: "Belajar",
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    NavItem(
      label: "Tantangan",
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
    ),
    NavItem(
      label: "Sertifikat",
      icon: Icons.workspace_premium_outlined,
      activeIcon: Icons.workspace_premium_rounded,
    ),
    NavItem(
      label: "Profil",
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  List<NavItem> get _navItems => widget.items ?? _defaultNavItems;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.defaultIndex;
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultIndex != oldWidget.defaultIndex) {
      if (_activeIndex != widget.defaultIndex) {
        setState(() {
          _activeIndex = widget.defaultIndex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- PALET WARNA SUPER CLEAN & MINIMALIS ---
    const Color navBgColor = Colors.white; // Background dock putih bersih
    const Color borderColor = Color(0xFFE2E8F0); // Border garis halus abu-abu
    const Color activePillColor = Color(0xFFE5E7EB); // Kapsul aktif: abu-abu lembut clean (#E5E7EB)
    const Color activeContentColor = Color(0xFF0F172A); // Ikon & teks aktif: Charcoal / Slate-900 elegan
    const Color inactiveIconColor = Color(0xFF64748B); // Ikon tidak aktif: Slate-500 neutral

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 12.0, right: 12.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: RepaintBoundary(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: navBgColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_navItems.length, (idx) {
                    final item = _navItems[idx];
                    final isActive = _activeIndex == idx;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: _NavButton(
                        key: ValueKey(item.label),
                        item: item,
                        isActive: isActive,
                        activePillColor: activePillColor,
                        activeContentColor: activeContentColor,
                        inactiveIconColor: inactiveIconColor,
                        labelWidth: _mobileLabelWidth,
                        onTap: () {
                          if (_activeIndex != idx) {
                            setState(() {
                              _activeIndex = idx;
                            });
                            widget.onItemSelected?.call(idx);
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Navigasi individual dengan whileTap scale 0.97 dan transisi Framer Motion Spring
class _NavButton extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Color activePillColor;
  final Color activeContentColor;
  final Color inactiveIconColor;
  final double labelWidth;

  const _NavButton({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.activePillColor,
    required this.activeContentColor,
    required this.inactiveIconColor,
    required this.labelWidth,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        // whileTap={{ scale: 0.97 }} persis Framer Motion
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          // transition-colors duration-200 persis Framer Motion
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 40.0,
          constraints: const BoxConstraints(minWidth: 44.0),
          padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.isActive ? widget.activePillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ikon: Pinned di kiri, tidak bergeser atau bergetar
              Icon(
                widget.isActive ? widget.item.activeIcon : widget.item.icon,
                size: 21,
                color: widget.isActive ? widget.activeContentColor : widget.inactiveIconColor,
              ),

              // Div Animasi Label: width spring (stiffness: 350, damping: 32), opacity & marginLeft 190ms
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: const FramerSpringCurve(),
                width: widget.isActive ? widget.labelWidth : 0.0,
                margin: EdgeInsets.only(left: widget.isActive ? 8.0 : 0.0),
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: widget.labelWidth,
                    alignment: Alignment.centerLeft,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOut,
                      opacity: widget.isActive ? 1.0 : 0.0,
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: GoogleFonts.plusJakartaSans(
                          color: widget.activeContentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.0,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
