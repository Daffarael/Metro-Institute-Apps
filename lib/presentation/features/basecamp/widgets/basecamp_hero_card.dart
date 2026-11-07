import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampHeroCard — "UX Lab: Motion Edition" / Continue Learning Card.
/// Styled 1:1 with the reference design:
/// • Soft pastel periwinkle blue container with smooth rounded corners (r = 28).
/// • Top-left white circular badge with stylized lens/target icon.
/// • Top-right circular progress tracker with ring arc and "2/3" indicator.
/// • Bold course title and mentor subtitle ("UX Lab: Motion Edition" / "Joseph Smith").
/// • Clean dark pill CTA button ("JOIN NOW").
/// • Bottom-right overlapping avatar portraits with whimsical background line-art (lightbulb, ruler, gear).
class BasecampHeroCard extends StatelessWidget {
  final Map<String, dynamic>? continueLearning;

  const BasecampHeroCard({super.key, this.continueLearning});

  @override
  Widget build(BuildContext context) {
    // If continueLearning is available, bind its dynamic data; otherwise use reference design defaults
    final hasData = continueLearning != null;
    final title = hasData && (continueLearning!['title'] as String?)?.trim().isNotEmpty == true
        ? continueLearning!['title'] as String
        : 'UX Lab: Motion Edition';

    final subtitle = hasData && (continueLearning!['sessionTitle'] as String?)?.trim().isNotEmpty == true
        ? continueLearning!['sessionTitle'] as String
        : (continueLearning?['mentorName'] as String? ?? 'Joseph Smith');

    final rawProgress = (continueLearning?['progress'] as num?)?.toDouble() ?? 66.7;
    final progress = (rawProgress / 100).clamp(0.0, 1.0);
    final completedCount = (continueLearning?['completedSessions'] as num?)?.toInt() ?? 2;
    final totalCount = (continueLearning?['totalSessions'] as num?)?.toInt() ?? 3;
    final progressText = hasData && totalCount > 0 ? '$completedCount/$totalCount' : '2/3';

    final courseId = continueLearning?['id']?.toString() ?? '';
    final sessionId = continueLearning?['sessionId']?.toString() ?? '';

    void handleTap() {
      if (hasData && courseId.isNotEmpty) {
        if (sessionId.isNotEmpty) {
          context.push('/learn/player/');
        } else {
          context.push('/learn/course/');
        }
      } else {
        context.go(AppRoutes.learn);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFA2BCFB), // Soft pastel periwinkle blue from reference design
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: handleTap,
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // ── LAYER 0: Background Whimsical Line Art (Lightbulb, Ruler, Gear) ──
              Positioned.fill(
                child: CustomPaint(
                  painter: const _HeroIllustrationPainter(),
                ),
              ),

              // ── LAYER 1: Card Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: White Circular Badge (Left) & Circular Progress (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: White Circular Badge with Target Mark
                        _buildTargetBadge(),

                        // Right: Circular Progress Ring (e.g. "2/3")
                        _buildProgressRing(
                          progress: hasData ? progress : (2 / 3),
                          text: progressText,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle (Mentor / Session)
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 20),

                    // Bottom Row: "JOIN NOW" Pill Button (Left) & Overlapping Avatars (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // CTA Pill Button: "JOIN NOW"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A), // Dark navy pill matching screenshot
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x220F172A),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'JOIN NOW',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),

                        // Overlapping Avatars Stack (Right)
                        _buildAvatarStack(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// White circular badge at top-left with target mark
  Widget _buildTargetBadge() {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(22, 22),
          painter: const _TargetLogoPainter(),
        ),
      ),
    );
  }

  /// Circular Progress Ring at top-right
  Widget _buildProgressRing({
    required double progress,
    required String text,
  }) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(46, 46),
            painter: _ProgressRingPainter(
              progress: progress,
              trackColor: Colors.black.withValues(alpha: 0.10),
              progressColor: const Color(0xFF0F172A),
              strokeWidth: 2.8,
            ),
          ),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 3 Overlapping Avatar Portraits at bottom-right
  Widget _buildAvatarStack() {
    const avatars = [
      (
        url: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
        color: Color(0xFF38BDF8),
        icon: Icons.person_rounded,
      ),
      (
        url: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120&auto=format&fit=crop&q=80',
        color: Color(0xFFA855F7),
        icon: Icons.face_rounded,
      ),
      (
        url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&auto=format&fit=crop&q=80',
        color: Color(0xFFFB7185),
        icon: Icons.face_4_rounded,
      ),
    ];

    return SizedBox(
      width: 82,
      height: 36,
      child: Stack(
        children: List.generate(avatars.length, (index) {
          final item = avatars[index];
          return Positioned(
            left: index * 22.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.2),
                color: item.color,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: item.color,
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
                errorWidget: (context, url, error) => Container(
                  color: item.color,
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// CustomPainter for the target/eye logo in the top-left circle badge
class _TargetLogoPainter extends CustomPainter {
  const _TargetLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final ringPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // Outer stylized ring
    canvas.drawCircle(Offset(cx, cy), r - 1.2, ringPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.40, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter for the circular progress ring at top-right
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 2.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active Progress Arc (starts at top, sweeps clockwise)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor;
}

/// CustomPainter for whimsical background line-art illustrations (lightbulb, ruler, gear)
class _HeroIllustrationPainter extends CustomPainter {
  const _HeroIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Lightbulb (near x = w - 42, y = h - 90)
    final bulbCenterX = w - 42.0;
    final bulbCenterY = h - 92.0;
    const bulbR = 15.0;

    // Bulb glass outline
    canvas.drawCircle(Offset(bulbCenterX, bulbCenterY), bulbR, linePaint);

    // Bulb base
    canvas.drawLine(
      Offset(bulbCenterX - 7, bulbCenterY + bulbR),
      Offset(bulbCenterX + 7, bulbCenterY + bulbR),
      linePaint,
    );
    canvas.drawLine(
      Offset(bulbCenterX - 5, bulbCenterY + bulbR + 4),
      Offset(bulbCenterX + 5, bulbCenterY + bulbR + 4),
      linePaint,
    );

    // Radiating rays
    canvas.drawLine(
      Offset(bulbCenterX, bulbCenterY - bulbR - 7),
      Offset(bulbCenterX, bulbCenterY - bulbR - 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(bulbCenterX - bulbR - 5, bulbCenterY - 4),
      Offset(bulbCenterX - bulbR - 1, bulbCenterY - 1),
      linePaint,
    );
    canvas.drawLine(
      Offset(bulbCenterX + bulbR + 1, bulbCenterY - 1),
      Offset(bulbCenterX + bulbR + 5, bulbCenterY - 4),
      linePaint,
    );

    // 2. Drafting Ruler Triangle (near x = w - 120, y = h - 2)
    final rulerPath = Path()
      ..moveTo(w - 145, h + 5)
      ..lineTo(w - 118, h - 55)
      ..lineTo(w - 95, h + 5)
      ..close();
    canvas.drawPath(rulerPath, linePaint);

    // Inner cutout
    final innerRuler = Path()
      ..moveTo(w - 136, h - 2)
      ..lineTo(w - 118, h - 38)
      ..lineTo(w - 105, h - 2)
      ..close();
    canvas.drawPath(innerRuler, linePaint);

    // 3. Gear / Cogwheel (near x = w - 85, y = h - 10)
    final gearCenterX = w - 85.0;
    final gearCenterY = h - 10.0;
    const gearR = 10.0;
    canvas.drawCircle(Offset(gearCenterX, gearCenterY), gearR, linePaint);
    canvas.drawCircle(Offset(gearCenterX, gearCenterY), 4.0, linePaint);

    // Gear teeth
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final x1 = gearCenterX + (gearR - 1) * math.cos(angle);
      final y1 = gearCenterY + (gearR - 1) * math.sin(angle);
      final x2 = gearCenterX + (gearR + 3.5) * math.cos(angle);
      final y2 = gearCenterY + (gearR + 3.5) * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
