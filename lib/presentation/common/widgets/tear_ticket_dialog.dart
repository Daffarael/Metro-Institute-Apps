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

  static const double _ticketHeight = 76.0;
  static const double _notchRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onConfirm();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHapticStep(double progress) {
    const int totalHoles = 6;
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

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isTorn) return;
    final dy = details.primaryDelta ?? 0;
    if (dy > 0) {
      setState(() {
        _dragProgress = math.min(1.0, _dragProgress + (dy / 80.0));
      });
      _triggerHapticStep(_dragProgress);
      if (_dragProgress >= 0.85) {
        _finishTear();
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isTorn) return;
    if (_dragProgress >= 0.45) {
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 36,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Pill & Header
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 26),
            ),
            const SizedBox(height: 16),
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
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // THE TIKET SOBEK COMPONENT
            SizedBox(
              height: _ticketHeight + 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LEFT TICKET BODY
                      ClipPath(
                        clipper: _TicketBodyClipper(notchRadius: _notchRadius),
                        child: Container(
                          width: 200,
                          height: _ticketHeight,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626), // Solid Metro Red
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33DC2626),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _isTorn ? Icons.check_rounded : Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isTorn ? 'Keluar...' : widget.ticketLabel,
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
                                      _isTorn ? 'Sampai jumpa!' : widget.ticketSubtitle,
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
                              ? (_tearAnimation.value * (35 * math.pi / 180))
                              : (_dragProgress * (20 * math.pi / 180));
                          final double fallDy = _isTorn ? (_fallAnimation.value * 70.0) : (_dragProgress * 10.0);
                          final double fallDx = _isTorn ? (_fallAnimation.value * 15.0) : 0.0;
                          final double opacity = _isTorn ? _opacityAnimation.value : 1.0;

                          return Transform.translate(
                            offset: Offset(fallDx, fallDy),
                            child: Transform(
                              alignment: Alignment.bottomLeft,
                              transform: Matrix4.rotationZ(tearAngle),
                              child: Opacity(
                                opacity: opacity,
                                child: GestureDetector(
                                  onVerticalDragUpdate: _onVerticalDragUpdate,
                                  onVerticalDragEnd: _onVerticalDragEnd,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    _finishTear();
                                  },
                                  child: ClipPath(
                                    clipper: _TicketStubClipper(notchRadius: _notchRadius),
                                    child: Container(
                                      width: 80,
                                      height: _ticketHeight,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFB91C1C), // Slightly darker red for tear stub
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x28000000),
                                            blurRadius: 8,
                                            offset: Offset(2, 4),
                                          ),
                                        ],
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

            const SizedBox(height: 8),

            // Hint text
            Text(
              'Tarik atau sentuh "SOBEK" untuk mengonfirmasi',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 18),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
    const double radius = 16.0;
    final path = Path();

    // Start at top-left
    path.moveTo(radius, 0);
    // Top edge to top-right notch
    path.lineTo(size.width - notchRadius, 0);
    // Top-right notch (inward arc)
    path.arcToPoint(
      Offset(size.width, notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Right seam edge
    path.lineTo(size.width, size.height - notchRadius);
    // Bottom-right notch (inward arc)
    path.arcToPoint(
      Offset(size.width - notchRadius, size.height),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Bottom edge to bottom-left
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius), radius: const Radius.circular(radius));
    // Left edge
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
    const double radius = 16.0;
    final path = Path();

    // Start at top-left notch
    path.moveTo(0, notchRadius);
    // Top-left notch (inward arc)
    path.arcToPoint(
      Offset(notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Top edge to top-right
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius));
    // Right edge to bottom-right
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height), radius: const Radius.circular(radius));
    // Bottom edge to bottom-left notch
    path.lineTo(notchRadius, size.height);
    // Bottom-left notch (inward arc)
    path.arcToPoint(
      Offset(0, size.height - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Left seam edge back to start
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
    double startY = 10.0;
    final double endY = size.height - 10.0;

    while (startY < endY) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
