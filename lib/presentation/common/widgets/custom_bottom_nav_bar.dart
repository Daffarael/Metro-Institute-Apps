// ============================================================================
// File: custom_bottom_nav_bar.dart
// Deskripsi: Floating Bottom Navigation Bar dengan fisika Framer Motion Spring
//            (stiffness: 350, damping: 32), whileTap scale 0.97, dock putih bersih,
//            dan transisi matematis konstan (zero jitter, zero layout wobble).
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
    return (1.0 - envelope * term).clamp(0.0, 1.0);
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

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late int _activeIndex;
  late int _previousIndex;

  late final AnimationController _animController;
  late final Animation<double> _springAnimation;

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
    _previousIndex = widget.defaultIndex;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _springAnimation = CurvedAnimation(
      parent: _animController,
      curve: const FramerSpringCurve(),
    );
    _animController.value = 1.0; // Mulai dalam posisi settled
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultIndex != oldWidget.defaultIndex &&
        widget.defaultIndex != _activeIndex) {
      _selectTab(widget.defaultIndex, notify: false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectTab(int newIndex, {bool notify = true}) {
    if (newIndex == _activeIndex && _animController.isCompleted) return;
    setState(() {
      _previousIndex = _activeIndex;
      _activeIndex = newIndex;
    });
    _animController.forward(from: 0.0);
    if (notify) {
      widget.onItemSelected?.call(newIndex);
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
            child: Container(
              height: 52,
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
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final t = _springAnimation.value;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_navItems.length, (idx) {
                      final item = _navItems[idx];

                      // Hitung nilai progress matematis (0.0 sampai 1.0)
                      // untuk tab ini secara sinkron:
                      double progress;
                      if (_animController.isCompleted) {
                        progress = (idx == _activeIndex) ? 1.0 : 0.0;
                      } else {
                        if (idx == _activeIndex) {
                          progress = t; // Membuka dengan Framer Spring
                        } else if (idx == _previousIndex) {
                          progress = 1.0 - t; // Menutup dengan invers presisi
                        } else {
                          progress = 0.0; // Diam tidak aktif
                        }
                      }

                      // Lebar dinamis label & margin:
                      // Jumlah lebar tab_membuka + tab_menutup = _mobileLabelWidth konstan sempurna!
                      final double dynamicLabelWidth =
                          (_mobileLabelWidth * progress).clamp(0.0, _mobileLabelWidth);
                      final double dynamicMarginLeft =
                          (8.0 * progress).clamp(0.0, 8.0);

                      // Opasitas teks: sesuai Framer Motion duration 0.19 (190ms / 320ms = ~0.59)
                      final double textOpacity;
                      if (idx == _activeIndex) {
                        textOpacity = Curves.easeOut
                            .transform((progress / 0.59).clamp(0.0, 1.0));
                      } else if (idx == _previousIndex) {
                        textOpacity = Curves.easeIn
                            .transform(((progress - 0.41) / 0.59).clamp(0.0, 1.0));
                      } else {
                        textOpacity = 0.0;
                      }

                      // Warna kapsul latar belakang & konten:
                      final Color pillBgColor = Color.lerp(
                          Colors.transparent, activePillColor, progress)!;
                      final Color contentColor = Color.lerp(
                          inactiveIconColor, activeContentColor, progress)!;
                      final IconData iconData =
                          progress >= 0.5 ? item.activeIcon : item.icon;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: _NavButton(
                          key: ValueKey(item.label),
                          label: item.label,
                          icon: iconData,
                          pillBgColor: pillBgColor,
                          contentColor: contentColor,
                          activeContentColor: activeContentColor,
                          dynamicLabelWidth: dynamicLabelWidth,
                          dynamicMarginLeft: dynamicMarginLeft,
                          textOpacity: textOpacity,
                          onTap: () => _selectTab(idx),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Navigasi individual dengan whileTap scale 0.97
class _NavButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color pillBgColor;
  final Color contentColor;
  final Color activeContentColor;
  final double dynamicLabelWidth;
  final double dynamicMarginLeft;
  final double textOpacity;
  final VoidCallback onTap;

  const _NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.pillBgColor,
    required this.contentColor,
    required this.activeContentColor,
    required this.dynamicLabelWidth,
    required this.dynamicMarginLeft,
    required this.textOpacity,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // whileTap: scale 0.97 halus dan membal natural
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 40.0,
          constraints: const BoxConstraints(minWidth: 44.0),
          padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.pillBgColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ikon: Pinned di posisi awal, tidak bergeser
              Icon(
                widget.icon,
                size: 21,
                color: widget.contentColor,
              ),

              // Margin dinamis antara ikon dan label (0px ke 8px)
              SizedBox(width: widget.dynamicMarginLeft),

              // Wadah Label animasi dengan kliping rapi (0px ke 72px)
              ClipRect(
                child: SizedBox(
                  width: widget.dynamicLabelWidth,
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: 72.0,
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: widget.textOpacity,
                      child: Text(
                        widget.label,
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
