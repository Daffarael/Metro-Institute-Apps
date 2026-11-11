import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// TactileMetroButton
///
/// 3D tactile push-down button inspired by kids.metroinstitute.site / Duolingo:
/// • Solid extruded 3D base shadow (4px)
/// • Dynamic physical press animation (translates 3px down, compresses base to 1px in 70ms)
/// • Crisp haptic feedback on press (HapticFeedback.lightImpact())
/// • Retains Metro Institute corporate palette: Primary Green (#018556), White, Slate, and Yellow
class TactileMetroButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final IconData? icon;
  final Color backgroundColor;
  final Color baseColor;
  final Color? borderColor;
  final Color textColor;
  final double height;
  final BorderRadius? borderRadius;
  final bool isFullWidth;
  final bool isDisabled;
  final bool isLoading;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const TactileMetroButton({
    super.key,
    required this.onPressed,
    this.child,
    this.text,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.baseColor = const Color(0xFF015F3D),
    this.borderColor,
    this.textColor = Colors.white,
    this.height = 48,
    this.borderRadius,
    this.isFullWidth = true,
    this.isDisabled = false,
    this.isLoading = false,
    this.fontSize = 14,
    this.padding,
  }) : assert(child != null || text != null, 'Either child or text must be provided');

  /// Primary Metro Green with dark forest green 3D base
  factory TactileMetroButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    String? text,
    Widget? child,
    IconData? icon,
    double height = 48,
    double fontSize = 14,
    BorderRadius? borderRadius,
    bool isFullWidth = true,
    bool isDisabled = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
  }) {
    return TactileMetroButton(
      key: key,
      onPressed: onPressed,
      text: text,
      child: child,
      icon: icon,
      backgroundColor: AppColors.primary,
      baseColor: const Color(0xFF015F3D),
      textColor: Colors.white,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      isLoading: isLoading,
      padding: padding,
    );
  }

  /// Dark / charcoal button with pure black 3D base
  factory TactileMetroButton.dark({
    Key? key,
    required VoidCallback? onPressed,
    String? text,
    Widget? child,
    IconData? icon,
    double height = 48,
    double fontSize = 14,
    BorderRadius? borderRadius,
    bool isFullWidth = true,
    bool isDisabled = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
  }) {
    return TactileMetroButton(
      key: key,
      onPressed: onPressed,
      text: text,
      child: child,
      icon: icon,
      backgroundColor: const Color(0xFF0F172A),
      baseColor: const Color(0xFF000000),
      textColor: Colors.white,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      isLoading: isLoading,
      padding: padding,
    );
  }

  /// Secondary clean white button with slate 3D base & border
  factory TactileMetroButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    String? text,
    Widget? child,
    IconData? icon,
    double height = 48,
    double fontSize = 14,
    BorderRadius? borderRadius,
    bool isFullWidth = true,
    bool isDisabled = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
  }) {
    return TactileMetroButton(
      key: key,
      onPressed: onPressed,
      text: text,
      child: child,
      icon: icon,
      backgroundColor: Colors.white,
      baseColor: const Color(0xFFCBD5E1),
      borderColor: const Color(0xFFE2E8F0),
      textColor: const Color(0xFF334155),
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      isLoading: isLoading,
      padding: padding,
    );
  }

  /// Success state: white surface, primary green outline, mint base
  factory TactileMetroButton.success({
    Key? key,
    required VoidCallback? onPressed,
    String? text,
    Widget? child,
    IconData? icon,
    double height = 48,
    double fontSize = 14,
    BorderRadius? borderRadius,
    bool isFullWidth = true,
    bool isDisabled = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
  }) {
    return TactileMetroButton(
      key: key,
      onPressed: onPressed,
      text: text,
      child: child,
      icon: icon,
      backgroundColor: Colors.white,
      baseColor: const Color(0xFFA7F3D0),
      borderColor: AppColors.primary,
      textColor: AppColors.primary,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      isLoading: isLoading,
      padding: padding,
    );
  }

  /// Accent yellow button with amber base
  factory TactileMetroButton.accent({
    Key? key,
    required VoidCallback? onPressed,
    String? text,
    Widget? child,
    IconData? icon,
    double height = 48,
    double fontSize = 14,
    BorderRadius? borderRadius,
    bool isFullWidth = true,
    bool isDisabled = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
  }) {
    return TactileMetroButton(
      key: key,
      onPressed: onPressed,
      text: text,
      child: child,
      icon: icon,
      backgroundColor: const Color(0xFFFFDD00),
      baseColor: const Color(0xFFD97706),
      textColor: const Color(0xFF0F172A),
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      isLoading: isLoading,
      padding: padding,
    );
  }

  /// Danger / error red button with deep crimson base
  factory TactileMetroButton.danger({
    Key? key,
    required VoidCallback? onPressed,
    String? text,
    Widget? child,
    IconData? icon,
    double height = 48,
    double fontSize = 14,
    BorderRadius? borderRadius,
    bool isFullWidth = true,
    bool isDisabled = false,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
  }) {
    return TactileMetroButton(
      key: key,
      onPressed: onPressed,
      text: text,
      child: child,
      icon: icon,
      backgroundColor: const Color(0xFFEF4444),
      baseColor: const Color(0xFFB91C1C),
      textColor: Colors.white,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      isLoading: isLoading,
      padding: padding,
    );
  }

  @override
  State<TactileMetroButton> createState() => _TactileMetroButtonState();
}

class _TactileMetroButtonState extends State<TactileMetroButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(14);
    final bool canPress = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    final double pushDepth = _isPressed && canPress ? 3.0 : 0.0;
    final double baseDepth = _isPressed && canPress ? 1.0 : 4.0;

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
        ),
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: widget.fontSize + 4, color: widget.textColor),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text ?? '',
            style: TextStyle(
              fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
              fontFamilyFallback: const ['Roboto', 'sans-serif'],
              fontWeight: FontWeight.w800,
              fontSize: widget.fontSize,
              color: widget.textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: canPress
          ? (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: canPress
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: canPress
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOutQuad,
        height: widget.height,
        width: widget.isFullWidth ? double.infinity : null,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
        transform: Matrix4.translationValues(0, pushDepth, 0),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: radius,
          border: widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: widget.baseColor,
              offset: Offset(0, baseDepth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(child: content),
      ),
    );
  }
}

/// TactileMetroIconButton
///
/// 3D tactile push-down icon button for navigation, action, and floating controls
class TactileMetroIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color baseColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final BorderRadius? borderRadius;
  final bool isDisabled;

  const TactileMetroIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconColor = Colors.white,
    this.backgroundColor = AppColors.primary,
    this.baseColor = const Color(0xFF015F3D),
    this.borderColor,
    this.size = 46,
    this.iconSize = 22,
    this.borderRadius,
    this.isDisabled = false,
  });

  @override
  State<TactileMetroIconButton> createState() => _TactileMetroIconButtonState();
}

class _TactileMetroIconButtonState extends State<TactileMetroIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(14);
    final bool canPress = !widget.isDisabled && widget.onPressed != null;
    final double pushDepth = _isPressed && canPress ? 3.0 : 0.0;
    final double baseDepth = _isPressed && canPress ? 1.0 : 4.0;

    return GestureDetector(
      onTapDown: canPress
          ? (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: canPress
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: canPress
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOutQuad,
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(0, pushDepth, 0),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: radius,
          border: widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: widget.baseColor,
              offset: Offset(0, baseDepth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(widget.icon, color: widget.iconColor, size: widget.iconSize),
        ),
      ),
    );
  }
}
