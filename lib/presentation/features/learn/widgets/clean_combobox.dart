import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens inspired by Halaska UI kit
class _ComboboxTokens {
  static const radiusMd = 14.0;
  static const radiusSm = 10.0;
  static const bgInput = Color(0xFFF8FAFC);
  static const bgElevated = Color(0xFFFFFFFF);
  static const bgSubtle = Color(0xFFF1F5F9);
  static const borderSubtle = Color(0xFFE2E8F0);
  static const borderFocus = Color(0xFF0F172A);
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const shadowLg = Color(0x1F0F172A);
}

class ComboboxOption {
  final String value;
  final String label;

  const ComboboxOption({
    required this.value,
    required this.label,
  });
}

/// CleanCombobox — Premium Halaska UI-inspired Combobox for Flutter:
/// • Uses native Flutter OverlayPortal (100% crash-proof lifecycle, zero markNeedsBuild errors)
/// • Pixel-perfect trigger with focus state and smoothly rotating chevron (180°)
/// • Anchored directly below the trigger using LayerLink
/// • Frosted glassmorphism backdrop filter blur (16px)
/// • Smooth scale-in & fade-in spring animation (Halaska motion)
/// • Live search filter for options > 5
/// • Clean checkmark on active option
class CleanCombobox extends StatefulWidget {
  final String value;
  final String placeholder;
  final List<ComboboxOption> options;
  final ValueChanged<String> onChanged;
  final double height;
  final bool? showSearch;

  const CleanCombobox({
    super.key,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.onChanged,
    this.height = 44,
    this.showSearch,
  });

  @override
  State<CleanCombobox> createState() => _CleanComboboxState();
}

class _CleanComboboxState extends State<CleanCombobox> with SingleTickerProviderStateMixin {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isOpen = false;
  String _searchQuery = '';
  double _triggerWidth = 200.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.34, 1.3, 0.64, 1.0), // Halaska spring curve
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();

    _searchQuery = '';
    _portalController.show();
    setState(() => _isOpen = true);
    _animController.forward(from: 0.0);
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _animController.reverse().then((_) {
      if (!_isOpen && mounted) {
        _portalController.hide();
      }
    });
  }

  Widget _buildDropdownOverlay(BuildContext context) {
    final shouldShowSearch = widget.showSearch ?? (widget.options.length > 5);

    return Stack(
      children: [
        // 1. Transparent barrier to catch outside clicks and close smoothly
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeDropdown,
            child: const SizedBox.expand(),
          ),
        ),

        // 2. Positioned dropdown follower directly below the trigger
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, widget.height + 6),
          child: SizedBox(
            width: _triggerWidth,
            child: Material(
              type: MaterialType.transparency,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: StatefulBuilder(
                  builder: (ctx, setLocalState) {
                    final filtered = widget.options.where((opt) {
                      if (_searchQuery.trim().isEmpty) return true;
                      return opt.label.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(_ComboboxTokens.radiusMd + 2),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: _ComboboxTokens.bgElevated.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(_ComboboxTokens.radiusMd + 2),
                            border: Border.all(
                              color: _ComboboxTokens.borderSubtle,
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: _ComboboxTokens.shadowLg,
                                blurRadius: 28,
                                offset: Offset(0, 12),
                                spreadRadius: -2,
                              ),
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Optional Halaska Filter Input Header
                              if (shouldShowSearch) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: _ComboboxTokens.borderSubtle, width: 1.0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        size: 16,
                                        color: _ComboboxTokens.textTertiary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          autofocus: true,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: _ComboboxTokens.text,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            hintText: 'Cari opsi...',
                                            hintStyle: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              color: _ComboboxTokens.textTertiary,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            setLocalState(() {
                                              _searchQuery = val;
                                            });
                                          },
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            setLocalState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 15,
                                            color: _ComboboxTokens.textTertiary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              // Options List
                              Flexible(
                                child: filtered.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                        child: Center(
                                          child: Text(
                                            'Tidak ada hasil',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              color: _ComboboxTokens.textTertiary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(5),
                                        shrinkWrap: true,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: filtered.length,
                                        itemBuilder: (ctx, i) {
                                          final opt = filtered[i];
                                          final isSelected = opt.value == widget.value;

                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: InkWell(
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                widget.onChanged(opt.value);
                                                _closeDropdown();
                                              },
                                              borderRadius: BorderRadius.circular(_ComboboxTokens.radiusSm),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? _ComboboxTokens.bgSubtle
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(_ComboboxTokens.radiusSm),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        opt.label,
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 12.5,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w700
                                                              : FontWeight.w500,
                                                          color: isSelected
                                                              ? _ComboboxTokens.text
                                                              : const Color(0xFF334155),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      const Icon(
                                                        Icons.check_rounded,
                                                        size: 16,
                                                        color: _ComboboxTokens.borderFocus,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMatch = widget.options.any((o) => o.value == widget.value);
    final selectedOption = hasMatch
        ? widget.options.firstWhere((o) => o.value == widget.value)
        : (widget.options.isNotEmpty ? widget.options.first : null);

    final isDefault = selectedOption == null ||
        selectedOption.value.isEmpty ||
        selectedOption.value == 'ALL' ||
        selectedOption.value == 'Semua';

    return LayoutBuilder(
      builder: (context, constraints) {
        _triggerWidth = constraints.maxWidth;

        return OverlayPortal(
          controller: _portalController,
          overlayChildBuilder: _buildDropdownOverlay,
          child: CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _ComboboxTokens.bgInput,
                  borderRadius: BorderRadius.circular(_ComboboxTokens.radiusMd),
                  border: Border.all(
                    color: _isOpen
                        ? _ComboboxTokens.borderFocus
                        : (!isDefault ? const Color(0xFF94A3B8) : _ComboboxTokens.borderSubtle),
                    width: _isOpen ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    if (_isOpen)
                      BoxShadow(
                        color: _ComboboxTokens.borderFocus.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    else
                      const BoxShadow(
                        color: Color(0x050F172A),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Selected text label
                    Expanded(
                      child: Text(
                        selectedOption?.label ?? widget.placeholder,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: isDefault ? FontWeight.w500 : FontWeight.w700,
                          color: isDefault ? _ComboboxTokens.textSecondary : _ComboboxTokens.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Halaska smoothly rotating chevron (turns 180° when open)
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: _isOpen ? _ComboboxTokens.borderFocus : _ComboboxTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
