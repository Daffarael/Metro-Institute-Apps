// ============================================================================
// File: custom_bottom_nav_bar.dart
// Deskripsi: Floating Bottom Navigation Bar dengan transisi lembut, tenang,
//            dan elegan (Framer Motion style). Lebar total konstan matematis
//            (zero wobble, zero jitter, tanpa getar/kaget).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavItem {
  final String label;
  final IconData icon;

  const NavItem({
    required this.label,
    required this.icon,
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
  late final Animation<double> _animation;

  // Lebar maksimal area teks label animasi (72px sesuai acuan)
  static const double _mobileLabelWidth = 72.0;

  // Spasi antara ikon dan label saat aktif (8px)
  static const double _labelMarginLeft = 8.0;

  // --- MENU NAVIGASI METRO INSTITUTE (Ikon Outline Elegan & Bersih) ---
  static const List<NavItem> _defaultNavItems = [
    NavItem(
      label: "Basecamp",
      icon: Icons.cottage_outlined,
    ),
    NavItem(
      label: "Belajar",
      icon: Icons.explore_outlined,
    ),
    NavItem(
      label: "Tantangan",
      icon: Icons.emoji_events_outlined,
    ),
    NavItem(
      label: "Sertifikat",
      icon: Icons.workspace_premium_outlined,
    ),
    NavItem(
      label: "Profil",
      icon: Icons.person_outline_rounded,
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
    // Curves.easeOutCubic: kurva deselerasi halus alami (tanpa sentakan/hentakan)
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.value = 1.0; // Mulai settled di posisi awal
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
                  final t = _animation.value;

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
                          progress = t; // Membuka dengan halus
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
                          (_labelMarginLeft * progress).clamp(0.0, _labelMarginLeft);

                      // Opasitas teks mengalir sinkron dengan lebar:
                      final double textOpacity = progress.clamp(0.0, 1.0);

                      // Warna kapsul latar belakang & konten:
                      final Color pillBgColor = Color.lerp(
                          Colors.transparent, activePillColor, progress)!;
                      final Color contentColor = Color.lerp(
                          inactiveIconColor, activeContentColor, progress)!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectTab(idx),
                          child: Container(
                            height: 40.0,
                            constraints: const BoxConstraints(minWidth: 44.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: pillBgColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Ikon: Bentuk tetap stabil (tidak berubah glyph),
                                // hanya warna yang bertransisi halus
                                Icon(
                                  item.icon,
                                  size: 21,
                                  color: contentColor,
                                ),

                                // Margin dinamis antara ikon dan label (0px ke 8px)
                                SizedBox(width: dynamicMarginLeft),

                                // Wadah Label animasi dengan kliping rapi (0px ke 72px)
                                ClipRect(
                                  child: SizedBox(
                                    width: dynamicLabelWidth,
                                    child: OverflowBox(
                                      minWidth: 0,
                                      maxWidth: _mobileLabelWidth,
                                      alignment: Alignment.centerLeft,
                                      child: Opacity(
                                        opacity: textOpacity,
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
                              ],
                            ),
                          ),
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
