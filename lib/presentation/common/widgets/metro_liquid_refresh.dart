import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// MetroLiquidRefresh
///
/// Custom liquid droplet pull-to-refresh inspired by Ramotion & Zain Mehmood's
/// fluid teardrop pull-to-refresh animation:
/// • Liquid teardrop stretches organically from the top edge with dynamic Bézier curves.
/// • Smooth viscous fluid neck narrows as drag distance increases.
/// • Integrated rotating spinner at the center of the liquid drop.
/// • Tactile haptic feedback when reaching the pull threshold.
/// • Spring recoil physics upon release and during refresh completion.
class MetroLiquidRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color color;
  final Color spinnerColor;
  final double threshold;

  const MetroLiquidRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color = AppColors.primary, // Metro Green (#018556)
    this.spinnerColor = Colors.white,
    this.threshold = 95.0,
  });

  @override
  State<MetroLiquidRefresh> createState() => _MetroLiquidRefreshState();
}

enum _LiquidRefreshMode { idle, drag, armed, refreshing, retracting }

class _MetroLiquidRefreshState extends State<MetroLiquidRefresh>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _recoilController;
  late final AnimationController _retractController;

  _LiquidRefreshMode _mode = _LiquidRefreshMode.idle;
  double _dragDistance = 0.0;
  bool _hapticFired = false;
  double _recoilFrom = 0.0;
  double _retractFrom = 0.0;

  static const double _restHeight = 52.0;

  @override
  void initState() {
    super.initState();

    // Spinner rotation controller (continuous while refreshing)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Spring recoil controller (from release position to _restHeight)
    _recoilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        setState(() {
          final t = Curves.easeOutBack.transform(_recoilController.value);
          _dragDistance = _recoilFrom + (_restHeight - _recoilFrom) * t;
        });
      });

    // Retract controller (after refresh completes, drop retracts to 0)
    _retractController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        setState(() {
          final t = Curves.easeInOutCubic.transform(_retractController.value);
          _dragDistance = _retractFrom * (1.0 - t);
        });
      });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _recoilController.dispose();
    _retractController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_mode == _LiquidRefreshMode.refreshing ||
        _mode == _LiquidRefreshMode.retracting) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _hapticFired = false;
    } else if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.axis == Axis.vertical && metrics.pixels <= 0) {
        final scrollDelta = notification.scrollDelta ?? 0.0;
        if (scrollDelta < 0) {
          // Pulling down: apply viscous fluid resistance
          final raw = _dragDistance + (-scrollDelta * 0.55);
          final clamped = raw.clamp(0.0, widget.threshold * 1.5);
          setState(() {
            _dragDistance = clamped;
            if (_dragDistance >= widget.threshold) {
              _mode = _LiquidRefreshMode.armed;
              if (!_hapticFired) {
                HapticFeedback.mediumImpact();
                _hapticFired = true;
              }
            } else if (_dragDistance > 0) {
              _mode = _LiquidRefreshMode.drag;
            }
          });
        } else if (scrollDelta > 0 && _dragDistance > 0) {
          // Pushing back up
          setState(() {
            _dragDistance = math.max(0.0, _dragDistance - scrollDelta);
            if (_dragDistance < widget.threshold &&
                _mode == _LiquidRefreshMode.armed) {
              _mode = _LiquidRefreshMode.drag;
              _hapticFired = false;
            } else if (_dragDistance == 0) {
              _mode = _LiquidRefreshMode.idle;
            }
          });
        }
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        final raw = _dragDistance + (-notification.overscroll * 0.55);
        final clamped = raw.clamp(0.0, widget.threshold * 1.5);
        setState(() {
          _dragDistance = clamped;
          if (_dragDistance >= widget.threshold) {
            _mode = _LiquidRefreshMode.armed;
            if (!_hapticFired) {
              HapticFeedback.mediumImpact();
              _hapticFired = true;
            }
          } else if (_dragDistance > 0) {
            _mode = _LiquidRefreshMode.drag;
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      _onRelease();
    }

    return false;
  }

  void _onRelease() {
    if (_mode == _LiquidRefreshMode.armed) {
      // Trigger refresh
      setState(() {
        _mode = _LiquidRefreshMode.refreshing;
        _recoilFrom = _dragDistance;
      });
      _spinController.repeat();
      _recoilController.forward(from: 0.0).then((_) {
        _executeRefresh();
      });
    } else if (_dragDistance > 0) {
      // Cancelled before threshold reached: snap back to 0
      setState(() {
        _retractFrom = _dragDistance;
        _mode = _LiquidRefreshMode.retracting;
      });
      _retractController.forward(from: 0.0).then((_) {
        setState(() {
          _mode = _LiquidRefreshMode.idle;
          _dragDistance = 0.0;
        });
      });
    }
  }

  Future<void> _executeRefresh() async {
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinController.stop();
        setState(() {
          _retractFrom = _dragDistance;
          _mode = _LiquidRefreshMode.retracting;
        });
        await _retractController.forward(from: 0.0);
        if (mounted) {
          setState(() {
            _mode = _LiquidRefreshMode.idle;
            _dragDistance = 0.0;
            _hapticFired = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = (_dragDistance / widget.threshold).clamp(0.0, 1.4);
    final isVisible = _dragDistance > 0.5;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Content Translation (Pushes down naturally with fluid pull)
          Transform.translate(
            offset: Offset(0, _dragDistance * 0.42),
            child: widget.child,
          ),

          // 2. Liquid Droplet Custom Painter (Positioned top-center)
          if (isVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _spinController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(
                      MediaQuery.of(context).size.width,
                      _dragDistance + 30.0,
                    ),
                    painter: _LiquidDropletPainter(
                      dropY: _dragDistance,
                      progress: effectiveProgress,
                      isRefreshing: _mode == _LiquidRefreshMode.refreshing,
                      spinValue: _spinController.value,
                      liquidColor: widget.color,
                      spinnerColor: widget.spinnerColor,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders the fluid liquid teardrop and inner spinner
class _LiquidDropletPainter extends CustomPainter {
  final double dropY;
  final double progress;
  final bool isRefreshing;
  final double spinValue;
  final Color liquidColor;
  final Color spinnerColor;

  _LiquidDropletPainter({
    required this.dropY,
    required this.progress,
    required this.isRefreshing,
    required this.spinValue,
    required this.liquidColor,
    required this.spinnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dropY <= 1.0) return;

    final cx = size.width / 2.0;
    const topY = 0.0;

    // Radius of the bulbous droplet at the bottom
    final dropRadius = 18.0 + (progress.clamp(0.0, 1.0) * 3.5);

    // Dynamic neck sizing: top is wider, neck narrows as drop pulls further
    final topHalfWidth = 26.0 + (progress.clamp(0.0, 1.0) * 6.0);
    final neckY = dropY * 0.45;
    final neckHalfWidth = math.max(
      6.0,
      topHalfWidth * math.max(0.24, 1.0 - (progress * 0.65)),
    );

    final liquidPaint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    if (dropY < dropRadius * 1.1) {
      // Small initial pull: smooth curved cap at top
      path.moveTo(cx - topHalfWidth, topY);
      path.quadraticBezierTo(cx, dropY * 1.8, cx + topHalfWidth, topY);
      path.close();
      canvas.drawPath(path, liquidPaint);
      return;
    }

    // Full liquid teardrop with organic Bézier tangents:
    // 1. Start top-left
    path.moveTo(cx - topHalfWidth, topY);

    // 2. Inward Bézier curve from top to droplet neck left edge
    path.cubicTo(
      cx - topHalfWidth * 0.85,
      neckY * 0.4,
      cx - neckHalfWidth * 1.15,
      neckY,
      cx - dropRadius,
      dropY,
    );

    // 3. Full bottom circle arc of the droplet
    path.arcToPoint(
      Offset(cx + dropRadius, dropY),
      radius: Radius.circular(dropRadius),
      clockwise: false,
    );

    // 4. Inward Bézier curve back up from droplet neck right edge to top-right
    path.cubicTo(
      cx + neckHalfWidth * 1.15,
      neckY,
      cx + topHalfWidth * 0.85,
      neckY * 0.4,
      cx + topHalfWidth,
      topY,
    );

    // 5. Close across top edge
    path.close();

    // Draw the liquid droplet
    canvas.drawPath(path, liquidPaint);

    // ── Draw Inside the Droplet: Spinner / Progress Arc ──────────────────────
    final center = Offset(cx, dropY);
    final spinnerRadius = dropRadius * 0.52;

    final spinnerPaint = Paint()
      ..color = spinnerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Faint track behind spinner
    final trackPaint = Paint()
      ..color = spinnerColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..isAntiAlias = true;

    canvas.drawCircle(center, spinnerRadius, trackPaint);

    if (isRefreshing) {
      // Spinning state: 280° arc rotating continuously
      final startAngle = spinValue * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: spinnerRadius),
        startAngle,
        1.5 * math.pi,
        false,
        spinnerPaint,
      );
    } else {
      // Pulling state: arc grows proportionally with drag progress
      final sweepAngle = (progress.clamp(0.0, 1.0)) * 1.65 * math.pi;
      const startAngle = -math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: spinnerRadius),
        startAngle,
        sweepAngle,
        false,
        spinnerPaint,
      );

      // Arrow head at the tip of the progressing arc when pulling
      if (progress > 0.25) {
        final tipAngle = startAngle + sweepAngle;
        final tipX = center.dx + spinnerRadius * math.cos(tipAngle);
        final tipY = center.dy + spinnerRadius * math.sin(tipAngle);

        final arrowPaint = Paint()
          ..color = spinnerColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        canvas.save();
        canvas.translate(tipX, tipY);
        canvas.rotate(tipAngle + math.pi / 2);
        final arrowPath = Path()
          ..moveTo(0, -3.5)
          ..lineTo(3.0, 2.5)
          ..lineTo(-3.0, 2.5)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidDropletPainter oldDelegate) {
    return oldDelegate.dropY != dropY ||
        oldDelegate.progress != progress ||
        oldDelegate.isRefreshing != isRefreshing ||
        oldDelegate.spinValue != spinValue ||
        oldDelegate.liquidColor != liquidColor;
  }
}
