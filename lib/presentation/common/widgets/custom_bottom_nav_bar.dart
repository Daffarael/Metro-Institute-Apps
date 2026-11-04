// ============================================================================
// File: custom_bottom_nav_bar.dart
// Deskripsi: Floating Bottom Navigation Bar dengan transisi lembut, dock putih,
//            dan aksen aktif abu-abu minimalis super clean (tanpa warna hijau).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // --- UKURAN TETAP (KONSISTEN & BEBAS GETAR — JANGAN DIUBAH) ---
  static const double _inactiveWidth = 44.0; // Lebar tombol saat tidak aktif
  static const double _activeWidth = 128.0;  // Lebar tombol saat aktif
  static const double _itemHeight = 42.0;    // Tinggi tombol

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
      setState(() {
        _activeIndex = widget.defaultIndex;
      });
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              height: 56,
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

                  return GestureDetector(
                    onTap: () {
                      if (_activeIndex != idx) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeIndex = idx;
                        });
                        widget.onItemSelected?.call(idx);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      // Durasi 320ms dengan easeInOutCubic: transisi lebar sangat mulus, responsif & stabil
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                      width: isActive ? _activeWidth : _inactiveWidth,
                      height: _itemHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedContainer(
                        // Warna latar kapsul bertransisi lembut (fade-in & fade-out halus tanpa pop seketika)
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isActive ? activePillColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 1. IKON MENU: Cross-fade halus dengan micro-scale saat aktif/inaktif
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  key: ValueKey('${item.label}_$isActive'),
                                  size: 21,
                                  color: isActive ? activeContentColor : inactiveIconColor,
                                ),
                              ),

                              // 2. TEKS LABEL: Melebar dan memudar secara kontinu (tanpa pemotongan SizedBox mendadak)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeInOutCubic,
                                width: isActive ? 68.0 : 0.0,
                                child: ClipRect(
                                  child: OverflowBox(
                                    minWidth: 0,
                                    maxWidth: 90,
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedOpacity(
                                      duration: Duration(milliseconds: isActive ? 260 : 160),
                                      curve: isActive ? Curves.easeOutCubic : Curves.easeInCubic,
                                      opacity: isActive ? 1.0 : 0.0,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6.0),
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.clip,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: activeContentColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.0,
                                            letterSpacing: -0.2,
                                          ),
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
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
