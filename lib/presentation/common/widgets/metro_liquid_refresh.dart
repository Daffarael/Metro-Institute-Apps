import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// MetroLiquidRefresh — Cat Paw Dynamic Island Pull-to-Refresh
///
/// Reproduksi 1:1 dari animasi video referensi @zain_dev_:
/// • Dynamic Island Pill hitam di bagian atas layar.
/// • Saat ditarik ke bawah (pull down), lengan & telapak cakar kucing (Cat Paw)
///   berwarna midnight navy / black dengan highlight 3D lembut meregang keluar
///   langsung dari Dynamic Island.
/// • 4 bantalan jari cakar kucing (4 rounded paw pads/toes) dengan kontur organik.
/// • Soft drop shadow di belakang cakar yang memberi kedalaman visual 3D realistis.
/// • Konten halaman bergerak ke bawah dengan resistensi alami iOS (offset: 0.35x),
///   sehingga UI tetap proporsional dan tidak meninggalkan ruang kosong berlebih.
/// • Efek recoil pegas (Curves.easeOutBack) saat dilepas dan saat refresh selesai.
/// • Haptic tactile feedback saat mencapai batas tarikan (threshold).
class MetroLiquidRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final double threshold;

  const MetroLiquidRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.threshold = 90.0,
  });

  @override
  State<MetroLiquidRefresh> createState() => _MetroLiquidRefreshState();
}

enum _RefreshState { idle, dragging, armed, refreshing, retracting }

class _MetroLiquidRefreshState extends State<MetroLiquidRefresh>
    with TickerProviderStateMixin {
  late final AnimationController _recoilController;
  late final AnimationController _retractController;

  _RefreshState _state = _RefreshState.idle;
  double _dragDistance = 0.0;
  bool _hapticFired = false;
  double _recoilFrom = 0.0;
  double _retractFrom = 0.0;

  static const double _restHeight = 70.0;

  @override
  void initState() {
    super.initState();

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

    // Retract controller (after refresh completes, paw returns smoothly into island)
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
    if (_state == _RefreshState.refreshing ||
        _state == _RefreshState.retracting) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _hapticFired = false;
    } else if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.axis == Axis.vertical && metrics.pixels <= 0) {
        final scrollDelta = notification.scrollDelta ?? 0.0;
        if (scrollDelta < 0) {
          // Pulling down: smooth fluid drag
          final raw = _dragDistance + (-scrollDelta * 0.65);
          final clamped = raw.clamp(0.0, widget.threshold * 1.6);
          setState(() {
            _dragDistance = clamped;
            if (_dragDistance >= widget.threshold) {
              _state = _RefreshState.armed;
              if (!_hapticFired) {
                HapticFeedback.mediumImpact();
                _hapticFired = true;
              }
            } else if (_dragDistance > 0) {
              _state = _RefreshState.dragging;
            }
          });
        } else if (scrollDelta > 0 && _dragDistance > 0) {
          // Sliding back up
          setState(() {
            _dragDistance = math.max(0.0, _dragDistance - scrollDelta);
            if (_dragDistance < widget.threshold &&
                _state == _RefreshState.armed) {
              _state = _RefreshState.dragging;
              _hapticFired = false;
            } else if (_dragDistance == 0) {
              _state = _RefreshState.idle;
            }
          });
        }
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        final raw = _dragDistance + (-notification.overscroll * 0.65);
        final clamped = raw.clamp(0.0, widget.threshold * 1.6);
        setState(() {
          _dragDistance = clamped;
          if (_dragDistance >= widget.threshold) {
            _state = _RefreshState.armed;
            if (!_hapticFired) {
              HapticFeedback.mediumImpact();
              _hapticFired = true;
            }
          } else if (_dragDistance > 0) {
            _state = _RefreshState.dragging;
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      _onRelease();
    }

    return false;
  }

  void _onRelease() {
    if (_state == _RefreshState.armed) {
      setState(() {
        _state = _RefreshState.refreshing;
        _recoilFrom = _dragDistance;
      });
      _recoilController.forward(from: 0.0).then((_) {
        _executeRefresh();
      });
    } else if (_dragDistance > 0) {
      setState(() {
        _retractFrom = _dragDistance;
        _state = _RefreshState.retracting;
      });
      _retractController.forward(from: 0.0).then((_) {
        setState(() {
          _state = _RefreshState.idle;
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
          _state = _RefreshState.retracting;
        });
        await _retractController.forward(from: 0.0);
        if (mounted) {
          setState(() {
            _state = _RefreshState.idle;
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
          // 1. Content Translation (Natural iOS overscroll resistance: 0.35x)
          Transform.translate(
            offset: Offset(0, _dragDistance * 0.35),
            child: widget.child,
          ),

          // 2. Exact Cat Paw & Dynamic Island Custom Painter
          if (isVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    topPadding + _dragDistance + 90.0,
                  ),
                  painter: _CatPawDynamicIslandPainter(
                    dragDistance: _dragDistance,
                    progress: effectiveProgress,
                    isRefreshing: _state == _RefreshState.refreshing,
                    topPadding: topPadding,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// CustomPainter rendering the exact Cat Paw emerging from Dynamic Island
class _CatPawDynamicIslandPainter extends CustomPainter {
  final double dragDistance;
  final double progress;
  final bool isRefreshing;
  final double topPadding;

  _CatPawDynamicIslandPainter({
    required this.dragDistance,
    required this.progress,
    required this.isRefreshing,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragDistance <= 0.5) return;

    final cx = size.width / 2.0;

    // Dynamic Island geometry: top notch position
    final islandTop = math.max(10.0, topPadding > 0 ? (topPadding - 30) / 2 : 11.0);
    const islandW = 88.0;
    const islandH = 28.0;
    const islandR = 14.0;
    final islandBottom = islandTop + islandH;

    // Paw extension reaches down smoothly with drag
    final pawY = islandBottom + 20.0 + (dragDistance * 0.85);

    // Anatomical cat leg & paw dimensions
    const armTopW = 34.0;
    const midW = 28.0;
    final midY = islandBottom + (pawY - islandBottom) * 0.45;
    const palmR = 25.0;

    // ── 1. Build the Unified Path (Island + Arm + Palm + Toes) ───────────────
    final path = Path();

    // Dynamic Island top-left start
    path.moveTo(cx - islandW / 2 + islandR, islandTop);
    path.lineTo(cx + islandW / 2 - islandR, islandTop);
    // Top-right corner arc
    path.arcToPoint(
      Offset(cx + islandW / 2, islandTop + islandR),
      radius: const Radius.circular(islandR),
    );
    // Bottom-right corner arc
    path.arcToPoint(
      Offset(cx + islandW / 2 - islandR, islandBottom),
      radius: const Radius.circular(islandR),
    );

    // Right fillet curve into arm
    path.lineTo(cx + armTopW, islandBottom);
    // Right arm curve down to palm
    path.cubicTo(
      cx + midW + 2,
      midY,
      cx + palmR + 1,
      pawY - 10,
      cx + palmR,
      pawY,
    );

    // 4 Rounded Paw Toes at the bottom
    // Right outer toe (toe 4)
    path.arcToPoint(
      Offset(cx + 14.0, pawY + 9.0),
      radius: const Radius.circular(7.5),
      clockwise: false,
    );
    // Right inner toe (toe 3)
    path.arcToPoint(
      Offset(cx, pawY + 12.0),
      radius: const Radius.circular(8.0),
      clockwise: false,
    );
    // Left inner toe (toe 2)
    path.arcToPoint(
      Offset(cx - 14.0, pawY + 9.0),
      radius: const Radius.circular(8.0),
      clockwise: false,
    );
    // Left outer toe (toe 1)
    path.arcToPoint(
      Offset(cx - palmR, pawY),
      radius: const Radius.circular(7.5),
      clockwise: false,
    );

    // Left arm curve back up to island
    path.cubicTo(
      cx - palmR - 1,
      pawY - 10,
      cx - midW - 2,
      midY,
      cx - armTopW,
      islandBottom,
    );

    // Left fillet into island bottom
    path.lineTo(cx - islandW / 2 + islandR, islandBottom);
    // Bottom-left corner arc
    path.arcToPoint(
      Offset(cx - islandW / 2, islandBottom - islandR),
      radius: const Radius.circular(islandR),
    );
    // Top-left corner arc
    path.arcToPoint(
      Offset(cx - islandW / 2 + islandR, islandTop),
      radius: const Radius.circular(islandR),
    );

    path.close();

    // ── 2. Soft Realistic Drop Shadow ─────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // ── 3. Solid Midnight Body Paint ─────────────────────────────────────────
    final bodyPaint = Paint()
      ..color = const Color(0xFF0F172A) // Deep Midnight Navy/Black matching video
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, bodyPaint);

    // Also draw solid circular fills for toes & palm to ensure organic roundness
    canvas.drawCircle(Offset(cx, pawY), palmR, bodyPaint);
    canvas.drawCircle(Offset(cx - 18.0, pawY + 5.0), 7.5, bodyPaint);
    canvas.drawCircle(Offset(cx - 6.0, pawY + 11.0), 8.0, bodyPaint);
    canvas.drawCircle(Offset(cx + 6.0, pawY + 11.0), 8.0, bodyPaint);
    canvas.drawCircle(Offset(cx + 18.0, pawY + 5.0), 7.5, bodyPaint);

    // ── 4. 3D Volumetric Specular Highlight (As Seen in Video) ───────────────
    // Spherical highlight at palm center
    final palmGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.32),
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, pawY), radius: 16))
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(cx, pawY), 16, palmGlowPaint);

    // Subtle 3D cylindrical sheen along the leg
    if (pawY - islandBottom > 30) {
      final legGlowHeight = (pawY - islandBottom) * 0.45;
      final legGlowRect = Rect.fromCenter(
        center: Offset(cx, midY),
        width: 12,
        height: legGlowHeight,
      );
      final legGlowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF38BDF8).withValues(alpha: 0.0),
            const Color(0xFF38BDF8).withValues(alpha: 0.22),
            const Color(0xFF38BDF8).withValues(alpha: 0.0),
          ],
        ).createShader(legGlowRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
        ..isAntiAlias = true;
      canvas.drawRect(legGlowRect, legGlowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CatPawDynamicIslandPainter oldDelegate) {
    return oldDelegate.dragDistance != dragDistance ||
        oldDelegate.progress != progress ||
        oldDelegate.isRefreshing != isRefreshing ||
        oldDelegate.topPadding != topPadding;
  }
}
