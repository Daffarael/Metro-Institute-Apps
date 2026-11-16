import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interactive Destructive Confirmation Dialog with a "Tiket Sobek" (Tear Ticket)
/// Replicates the Web Admin TearButton confirmation with realistic ticket notches,
/// perforation line, swing physics, and haptic feedback.
class TearTicketDialog extends StatefulWidget {
  final String title;
  final String description;
  final String ticketLabel;
  final String ticketSubtitle;
  final String stubLabel;
  final VoidCallback onConfirm;

  const TearTicketDialog({
    super.key,
    this.title = 'Konfirmasi Keluar',
    this.description = 'Apakah Anda yakin ingin keluar dari akun Metro Institute Anda?',
    this.ticketLabel = 'Keluar Akun',
    this.ticketSubtitle = 'Sobek tiket untuk keluar',
    this.stubLabel = 'SOBEK',
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Konfirmasi Keluar',
    String description = 'Apakah Anda yakin ingin keluar dari akun Metro Institute Anda?',
    String ticketLabel = 'Keluar Akun',
    String ticketSubtitle = 'Sobek tiket untuk keluar',
    String stubLabel = 'SOBEK',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => TearTicketDialog(
        title: title,
        description: description,
        ticketLabel: ticketLabel,
        ticketSubtitle: ticketSubtitle,
        stubLabel: stubLabel,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  State<TearTicketDialog> createState() => _TearTicketDialogState();
}

class _TearTicketDialogState extends State<TearTicketDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tearAnimation;
  late Animation<double> _fallAnimation;
  late Animation<double> _opacityAnimation;

  double _dragProgress = 0.0;
  bool _isTorn = false;
  int _lastVibratedHole = -1;

  static const double _ticketHeight = 74.0;
  static const double _notchRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _tearAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeInQuad),
    );

    _fallAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeInCubic),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) widget.onConfirm();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHapticStep(double progress) {
    const int totalHoles = 5;
    final int currentHole = (progress * totalHoles).floor();
    if (currentHole != _lastVibratedHole && currentHole >= 0 && currentHole < totalHoles) {
      _lastVibratedHole = currentHole;
      HapticFeedback.selectionClick();
    }
  }

  void _finishTear() {
    if (_isTorn) return;
    setState(() => _isTorn = true);
    HapticFeedback.heavyImpact();
    _controller.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isTorn) return;
    final dy = details.delta.dy;
    final dx = details.delta.dx;
    // Allow tearing by dragging down or slightly sideways
    final delta = (dy > 0 ? dy : 0) + (dx > 0 ? dx * 0.4 : 0);
    if (delta > 0) {
      setState(() {
        _dragProgress = math.min(1.0, _dragProgress + (delta / 35.0));
      });
      _triggerHapticStep(_dragProgress);
      if (_dragProgress >= 0.60) {
        _finishTear();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isTorn) return;
    final velocity = details.velocity.pixelsPerSecond;
    if (_dragProgress >= 0.20 || velocity.dy > 100 || velocity.dx > 100) {
      _finishTear();
    } else {
      setState(() {
        _dragProgress = 0.0;
        _lastVibratedHole = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Pill & Header
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626), // Solid Red Metro
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // THE TIKET SOBEK COMPONENT (100% Responsive, Zero Overflow)
            SizedBox(
              height: _ticketHeight + 24,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      // LEFT TICKET BODY (Expanded to fill available dialog width, remains authentic red)
                      Expanded(
                        child: ClipPath(
                          clipper: _TicketBodyClipper(notchRadius: _notchRadius),
                          child: Container(
                            height: _ticketHeight,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626), // Tetap merah solid, tidak berubah
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.ticketLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.ticketSubtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // DOTTED PERFORATION LINE
                      CustomPaint(
                        size: const Size(2, _ticketHeight),
                        painter: _PerforationPainter(),
                      ),

                      // RIGHT TICKET STUB (TEARABLE)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final double tearAngle = _isTorn
                              ? (_tearAnimation.value * (45 * math.pi / 180))
                              : (_dragProgress * (20 * math.pi / 180));
                          final double fallDy = _isTorn ? (_fallAnimation.value * 110.0) : (_dragProgress * 12.0);
                          final double fallDx = _isTorn ? (_fallAnimation.value * 28.0) : 0.0;
                          final double opacity = _isTorn ? _opacityAnimation.value : 1.0;

                          return Transform.translate(
                            offset: Offset(fallDx, fallDy),
                            child: Transform(
                              alignment: Alignment.bottomLeft,
                              transform: Matrix4.rotationZ(tearAngle),
                              child: Opacity(
                                opacity: opacity,
                                child: GestureDetector(
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  onTap: () {
                                    HapticFeedback.heavyImpact();
                                    _finishTear();
                                  },
                                  child: ClipPath(
                                    clipper: _TicketStubClipper(notchRadius: _notchRadius),
                                    child: Container(
                                      width: 72,
                                      height: _ticketHeight,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFB91C1C), // Solid darker red for tear stub
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 16),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.stubLabel,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Hint text
            Text(
              'Tarik atau sentuh "SOBEK" untuk konfirmasi',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Clipper for Ticket Body (Left portion with top-right & bottom-right circular notches)
class _TicketBodyClipper extends CustomClipper<Path> {
  final double notchRadius;
  const _TicketBodyClipper({required this.notchRadius});

  @override
  Path getClip(Size size) {
    const double radius = 14.0;
    final path = Path();

    path.moveTo(radius, 0);
    path.lineTo(size.width - notchRadius, 0);
    path.arcToPoint(
      Offset(size.width, notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - notchRadius);
    path.arcToPoint(
      Offset(size.width - notchRadius, size.height),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius), radius: const Radius.circular(radius));
    path.lineTo(0, radius);
    path.arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TicketBodyClipper oldClipper) => oldClipper.notchRadius != notchRadius;
}

/// Custom Clipper for Ticket Stub (Right portion with top-left & bottom-left circular notches)
class _TicketStubClipper extends CustomClipper<Path> {
  final double notchRadius;
  const _TicketStubClipper({required this.notchRadius});

  @override
  Path getClip(Size size) {
    const double radius = 14.0;
    final path = Path();

    path.moveTo(0, notchRadius);
    path.arcToPoint(
      Offset(notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius));
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height), radius: const Radius.circular(radius));
    path.lineTo(notchRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, notchRadius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TicketStubClipper oldClipper) => oldClipper.notchRadius != notchRadius;
}

/// Custom Painter for Perforated Seam Line
class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 4.0;
    const double dashSpace = 4.0;
    double startY = 8.0;
    final double endY = size.height - 8.0;

    while (startY < endY) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
