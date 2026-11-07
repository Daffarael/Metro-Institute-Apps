import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// BasecampHeroCard — "Bootcamp Metro Institute Season 2" / Continue Learning Card.
/// Styled 1:1 with the reference design (r = 44) adapted to authentic Metro Institute content:
/// • Soft pastel periwinkle blue container with smooth rounded corners (r = 44).
/// • Top-left white circular badge with Metro Institute Shield Logo.
/// • Top-right circular progress tracker with ring arc and "S2" or actual progress indicator.
/// • Bold course title and mentor subtitle ("Bootcamp Metro Institute Season 2" / "Intensif UI/UX Design & Mobile Apps").
/// • Clean Hijau Metro pill CTA button ("MULAI BELAJAR" / "LANJUT BELAJAR").
/// • Bottom-right overlapping track badges (UI/UX, Mobile, Engineering) with whimsical line-art.
class BasecampHeroCard extends StatelessWidget {
  final Map<String, dynamic>? continueLearning;

  const BasecampHeroCard({super.key, this.continueLearning});

  @override
  Widget build(BuildContext context) {
    // If continueLearning is available, bind its dynamic data; otherwise use Metro Institute Season 2 defaults
    final hasData = continueLearning != null;
    final title = hasData && (continueLearning!['title'] as String?)?.trim().isNotEmpty == true
        ? continueLearning!['title'] as String
        : 'Bootcamp Metro Institute Season 2';

    final subtitle = hasData && (continueLearning!['sessionTitle'] as String?)?.trim().isNotEmpty == true
        ? continueLearning!['sessionTitle'] as String
        : (continueLearning?['mentorName'] as String? ?? 'Intensif UI/UX Design & Mobile Apps');

    final rawProgress = (continueLearning?['progress'] as num?)?.toDouble() ?? 0.0;
    final progress = (rawProgress / 100).clamp(0.0, 1.0);
    final completedCount = (continueLearning?['completedSessions'] as num?)?.toInt() ?? 0;
    final totalCount = (continueLearning?['totalSessions'] as num?)?.toInt() ?? 0;
    final progressText = hasData
        ? (totalCount > 0 ? '$completedCount/$totalCount' : '${(progress * 100).toInt()}%')
        : 'S2';

    final courseId = continueLearning?['id']?.toString() ?? '';
    final sessionId = continueLearning?['sessionId']?.toString() ?? '';

    void handleTap() {
      if (hasData && courseId.isNotEmpty) {
        if (sessionId.isNotEmpty) {
          context.push('/learn/player/$sessionId');
        } else {
          context.push('/learn/course/$courseId');
        }
      } else {
        context.go(AppRoutes.learn);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: const Color(0xFFA2BCFB), // Soft pastel periwinkle blue from reference design
        borderRadius: BorderRadius.circular(44),
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
          borderRadius: BorderRadius.circular(44),
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
                    // Top Row: Metro Shield Badge (Left)
                    _buildTargetBadge(),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF063D2A), // Deep Emerald Dark Metro
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle (Mentor / Session / Track)
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A2F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 18),

                    // Bottom Row: "MULAI BELAJAR" Pill Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.primary, // Hijau Metro
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33018556),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasData ? 'LANJUT BELAJAR' : 'MULAI BELAJAR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
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

  /// White circular badge at top-left with Metro Institute Logo
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
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
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
