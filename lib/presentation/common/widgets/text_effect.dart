import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Available animation presets matching Framer Motion TextEffect presets:
/// - [blur]: Gaussian optical blur with luminous white transition and subtle float-up
/// - [slide]: Slide up from y: 20 with fade
/// - [scale]: Scale up from 0 to 1 with fade
/// - [fade]: Pure opacity fade from 0 to 1
/// - [shake]: Micro-shake kinetic settlement
enum TextEffectPreset {
  blur,
  slide,
  scale,
  fade,
  shake,
}

/// Unit of segmentation for animation:
/// - [char]: Each character animates with stagger
/// - [word]: Each word animates with stagger
/// - [line]: Each line animates with stagger
enum TextEffectPer {
  char,
  word,
  line,
}

/// A Flutter adaptation of the Framer Motion / Motion Primitives `TextEffect`.
///
/// Can be used either:
/// 1. Self-animated: drives itself via an internal [AnimationController] when [trigger] is true.
/// 2. Controlled: driven externally via a normalized [progress] (0.0 to 1.0),
///    ideal for complex orchestrated timelines like Splash Screens.
class TextEffect extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextEffectPreset preset;
  final TextEffectPer per;
  final double? progress;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool trigger;
  final VoidCallback? onAnimationComplete;
  final TextAlign textAlign;
  final double overlap;
  final Color blurColor;

  const TextEffect({
    super.key,
    required this.text,
    this.style,
    this.preset = TextEffectPreset.blur,
    this.per = TextEffectPer.char,
    this.progress,
    this.duration = const Duration(milliseconds: 1000),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.trigger = true,
    this.onAnimationComplete,
    this.textAlign = TextAlign.start,
    this.overlap = 0.55,
    this.blurColor = Colors.white,
  });

  @override
  State<TextEffect> createState() => _TextEffectState();
}

class _TextEffectState extends State<TextEffect> with SingleTickerProviderStateMixin {
  AnimationController? _internalController;
  late Animation<double> _internalAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.progress == null) {
      _internalController = AnimationController(
        vsync: this,
        duration: widget.duration,
      );
      _internalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _internalController!, curve: Curves.linear),
      );

      if (widget.trigger) {
        _startInternal();
      }
    }
  }

  void _startInternal() {
    if (_internalController == null) return;
    if (widget.delay == Duration.zero) {
      _internalController!.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    } else {
      Future.delayed(widget.delay, () {
        if (mounted && _internalController != null) {
          _internalController!.forward().then((_) {
            widget.onAnimationComplete?.call();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant TextEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress == null && _internalController != null) {
      if (widget.trigger != oldWidget.trigger) {
        if (widget.trigger) {
          _internalController!.forward(from: 0.0).then((_) {
            widget.onAnimationComplete?.call();
          });
        } else {
          _internalController!.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.progress != null) {
      return _buildContent(widget.progress!);
    }

    return AnimatedBuilder(
      animation: _internalAnimation,
      builder: (context, _) => _buildContent(_internalAnimation.value),
    );
  }

  Widget _buildContent(double progress) {
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;

    if (widget.per == TextEffectPer.line) {
      final lines = widget.text.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < lines.length; i++)
            _buildSegment(
              lines[i],
              _calcLocalT(i, lines.length, progress),
              effectiveStyle,
              isInline: false,
            ),
        ],
      );
    }

    if (widget.per == TextEffectPer.word) {
      final words = widget.text.split(' ');
      return Wrap(
        alignment: _wrapAlignment(widget.textAlign),
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 4,
        children: [
          for (int i = 0; i < words.length; i++) ...[
            _buildSegment(
              words[i],
              _calcLocalT(i, words.length, progress),
              effectiveStyle,
              isInline: true,
            ),
            if (i < words.length - 1)
              Text(' ', style: effectiveStyle),
          ],
        ],
      );
    }

    // Default: TextEffectPer.char (per character)
    final chars = widget.text.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (int i = 0; i < chars.length; i++)
          _buildSegment(
            chars[i],
            _calcLocalT(i, chars.length, progress),
            effectiveStyle,
            isInline: true,
          ),
      ],
    );
  }

  WrapAlignment _wrapAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }

  double _calcLocalT(int index, int totalCount, double progress) {
    if (totalCount <= 1) return progress.clamp(0.0, 1.0);

    // Staggered overlap math:
    // itemWindow defines what portion of total progress each segment animates.
    // An overlap of 0.55 means 55% overlap between adjacent items.
    final overlap = widget.overlap.clamp(0.1, 0.85);
    final itemWindow = 1.0 / (totalCount * (1.0 - overlap) + overlap);
    final step = itemWindow * (1.0 - overlap);

    final start = index * step;
    final end = start + itemWindow;

    if (progress <= start) return 0.0;
    if (progress >= end) return 1.0;
    return (progress - start) / (end - start);
  }

  Widget _buildSegment(
    String segment,
    double localT,
    TextStyle style, {
    required bool isInline,
  }) {
    // Preserve space characters without collapsing
    final isSpace = segment == ' ' || segment.isEmpty;
    final displayText = isSpace ? '\u00A0' : segment;

    // Invisible placeholder keeps 100% stable layout bounds (no horizontal jitters)
    if (localT <= 0.0) {
      return Opacity(
        opacity: 0.0,
        child: Text(displayText, style: style),
      );
    }

    // Fully settled: return crisp text with ZERO filter/transform overhead
    if (localT >= 1.0) {
      return Text(displayText, style: style);
    }

    // Active transition: apply easing curve
    final curvedT = widget.curve.transform(localT.clamp(0.0, 1.0));

    switch (widget.preset) {
      case TextEffectPreset.blur:
        // Luminous White Optical Blur:
        // Letter emerges from luminous white into rich crisp brand color,
        // completely eliminating dark ink smudges on white backgrounds.
        final opacity = curvedT.clamp(0.0, 1.0);
        final blur = (1.0 - curvedT) * 4.5;
        final y = (1.0 - curvedT) * 6.0;
        final scale = 0.95 + (0.05 * curvedT);

        final targetColor = style.color ?? const Color(0xFF063D2A);
        final animatedColor = Color.lerp(
          widget.blurColor,
          targetColor,
          math.pow(curvedT, 2.0).toDouble(),
        )!;

        final dynamicStyle = style.copyWith(
          color: animatedColor,
          shadows: [
            if (curvedT < 0.9)
              Shadow(
                color: widget.blurColor.withValues(alpha: (1.0 - curvedT).clamp(0.0, 1.0)),
                blurRadius: (1.0 - curvedT) * 10.0,
              ),
          ],
        );

        Widget child = Text(displayText, style: dynamicStyle);

        if (blur > 0.15) {
          child = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: child,
          );
        }

        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          ),
        );

      case TextEffectPreset.slide:
        // Framer Motion slide preset:
        // y: 20 -> 0, opacity: 0 -> 1
        final opacity = curvedT.clamp(0.0, 1.0);
        final y = (1.0 - curvedT) * 20.0;
        return Transform.translate(
          offset: Offset(0, y),
          child: Opacity(
            opacity: opacity,
            child: Text(displayText, style: style),
          ),
        );

      case TextEffectPreset.scale:
        // Framer Motion scale preset:
        // scale: 0 -> 1, opacity: 0 -> 1
        final opacity = curvedT.clamp(0.0, 1.0);
        final scale = curvedT.clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Text(displayText, style: style),
          ),
        );

      case TextEffectPreset.fade:
        // Framer Motion fade preset:
        // opacity: 0 -> 1
        return Opacity(
          opacity: curvedT.clamp(0.0, 1.0),
          child: Text(displayText, style: style),
        );

      case TextEffectPreset.shake:
        // Framer Motion shake preset:
        // x: [-5, 5, -5, 5, 0]
        final x = math.sin(curvedT * math.pi * 4) * (1.0 - curvedT) * 5.0;
        return Transform.translate(
          offset: Offset(x, 0),
          child: Opacity(
            opacity: curvedT.clamp(0.0, 1.0),
            child: Text(displayText, style: style),
          ),
        );
    }
  }
}
