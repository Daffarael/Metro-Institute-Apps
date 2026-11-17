import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// MetroLiquidRefresh — Cat Paw Dynamic Island Pull-to-Refresh
///
/// Reproduksi 1:1 dari animasi viral @zain_dev_ (animal_app_flutter):
/// • Dynamic Island Pill hitam di bagian atas layar.
/// • Saat ditarik ke bawah (pull down), lengan & telapak cakar kucing (Cat Paw)
///   berwarna hitam pekat meregang elastis keluar langsung dari Dynamic Island.
/// • 4 bantalan jari cakar kucing (4 rounded paw pads/toes) yang memanjang organik.
/// • Konten halaman bergerak ke bawah secara 1:1, sehingga cakar kucing berada
///   di ruang kosong di atas header tanpa pernah menutupi teks/avatar.
/// • Efek recoil pegas (Curves.easeOutBack) saat dilepas dan saat refresh selesai.
/// • Haptic tactile feedback saat mencapai batas tarikan (threshold).
class MetroLiquidRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color color;
  final double threshold;

  const MetroLiquidRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color = const Color(0xFF000000), // Solid Deep Black (Dynamic Island)
    this.threshold = 95.0,
  });

  @override
  State<MetroLiquidRefresh> createState() => _MetroLiquidRefreshState();
}

enum _LiquidRefreshMode { idle, drag, armed, refreshing, retracting }

class _MetroLiquidRefreshState extends State<MetroLiquidRefresh>
    with TickerProviderStateMixin {
  late final AnimationController _recoilController;
  late final AnimationController _retractController;

  _LiquidRefreshMode _mode = _LiquidRefreshMode.idle;
  double _dragDistance = 0.0;
  bool _hapticFired = false;
  double _recoilFrom = 0.0;
  double _retractFrom = 0.0;

  static const double _restHeight = 80.0;

  @override
  void initState() {
    super.initState();

    // Spring recoil controller (from release to _restHeight)
    _recoilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        setState(() {
          final t = Curves.easeOutBack.transform(_recoilController.value);
          _dragDistance = _recoilFrom + (_restHeight - _recoilFrom) * t;
        });
      });

    // Retract controller (after refresh completes, paw smoothly returns into island)
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
          // Pulling down
          final raw = _dragDistance + (-scrollDelta * 0.60);
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
          // Sliding back up
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
        final raw = _dragDistance + (-notification.overscroll * 0.60);
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
      setState(() {
        _mode = _LiquidRefreshMode.refreshing;
        _recoilFrom = _dragDistance;
      });
      _recoilController.forward(from: 0.0).then((_) {
        _executeRefresh();
      });
    } else if (_dragDistance > 0) {
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
    final topPadding = MediaQuery.of(context).padding.top;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Content Translation (Moves down 1:1 so cat paw never covers header)
          Transform.translate(
            offset: Offset(0, _dragDistance),
            child: widget.child,
          ),

          // 2. Cat Paw & Dynamic Island Custom Painter
          if (isVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    topPadding + _dragDistance + 60.0,
                  ),
                  painter: _CatPawDynamicIslandPainter(
                    dragDistance: _dragDistance,
                    progress: effectiveProgress,
                    isRefreshing: _mode == _LiquidRefreshMode.refreshing,
                    topPadding: topPadding,
                    color: widget.color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders the exact Cat Paw & Dynamic Island from Zain's video
class _CatPawDynamicIslandPainter extends CustomPainter {
  final double dragDistance;
  final double progress;
  final bool isRefreshing;
  final double topPadding;
  final Color color;

  _CatPawDynamicIslandPainter({
    required this.dragDistance,
    required this.progress,
    required this.isRefreshing,
    required this.topPadding,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragDistance <= 0.5) return;

    final cx = size.width / 2.0;

    // Dynamic Island geometry
    // Standard Dynamic Island sits in top status bar area
    final islandTop = topPadding > 0 ? math.max(10.0, topPadding * 0.22) : 12.0;
    const islandW = 120.0;
    const islandH = 34.0;
    const islandR = 17.0;
    final islandBottom = islandTop + islandH;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Dynamic Island Pill
    final islandRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, islandTop + islandH / 2),
        width: islandW,
        height: islandH,
      ),
      const Radius.circular(islandR),
    );
    canvas.drawRRect(islandRect, paint);

    // 2. Cat Paw calculations
    // Current paw Y position emerges below islandBottom as drag increases
    final currentPawY = islandBottom + (dragDistance * 0.76);
    if (currentPawY <= islandBottom + 2.0) return;

    const armTopW = 34.0; // Connection width at base of Dynamic Island
    const neckW = 21.0;   // Slight waist/narrowing of the arm
    final neckY = islandBottom + (currentPawY - islandBottom) * 0.44;
    const palmR = 26.0;   // Radius of the main paw palm

    final path = Path();

    // Start at bottom of island, left edge of arm
    path.moveTo(cx - armTopW, islandBottom);

    // Left cubic curve: from island connection inward to neck, then outward to palm left
    path.cubicTo(
      cx - armTopW * 0.9,
      islandBottom + (neckY - islandBottom) * 0.35,
      cx - neckW * 1.1,
      neckY,
      cx - palmR,
      currentPawY,
    );

    // Bottom paw line connecting around to the right
    path.lineTo(cx + palmR, currentPawY);

    // Right cubic curve: back up to island bottom
    path.cubicTo(
      cx + neckW * 1.1,
      neckY,
      cx + armTopW * 0.9,
      islandBottom + (neckY - islandBottom) * 0.35,
      cx + armTopW,
      islandBottom,
    );

    path.close();
    canvas.drawPath(path, paint);

    // 3. Paw Palm (solid center circle)
    canvas.drawCircle(Offset(cx, currentPawY), palmR, paint);

    // 4. Cat Paw 4 Toes / Pads (exact reproduction of cat claws/pads)
    // Leftmost toe (toe 1)
    canvas.drawCircle(Offset(cx - 20.0, currentPawY + 7.0), 9.0, paint);
    // Inner-left toe (toe 2)
    canvas.drawCircle(Offset(cx - 7.0, currentPawY + 15.0), 9.5, paint);
    // Inner-right toe (toe 3)
    canvas.drawCircle(Offset(cx + 7.0, currentPawY + 15.0), 9.5, paint);
    // Rightmost toe (toe 4)
    canvas.drawCircle(Offset(cx + 20.0, currentPawY + 7.0), 9.0, paint);
  }

  @override
  bool shouldRepaint(covariant _CatPawDynamicIslandPainter oldDelegate) {
    return oldDelegate.dragDistance != dragDistance ||
        oldDelegate.progress != progress ||
        oldDelegate.isRefreshing != isRefreshing ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.color != color;
  }
}
