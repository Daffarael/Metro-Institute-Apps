import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// BasecampHeroCard — Menampilkan HANYA kelas yang sudah dibeli / diikuti oleh mentee.
/// Mengadopsi visual persis dari referensi desain:
/// • Background warna soft pastel rose/pink (#FDECEF) dengan border halus
/// • Aksen starburst lime-green (#C6F24D) dan ilustrasi estetik di sisi kanan
/// • Headline judul kelas tebal & tegas
/// • Teks sebutan progres lesson: "X/Y Lesson Selesai" (e.g. "37/40 Lesson Selesai")
/// • Indikator persentase circular gelap di pojok kanan atas dengan ring pink (e.g. "78%")
/// • Avatar stack peserta & nama instruktur "By [Mentor]"
/// • Jika user belum beli kelas (continueLearning == null), widget tidak menampilkan apa-apa.
class BasecampHeroCard extends StatelessWidget {
  final Map<String, dynamic>? continueLearning;

  const BasecampHeroCard({super.key, this.continueLearning});

  @override
  Widget build(BuildContext context) {
    if (continueLearning == null) {
      return const SizedBox.shrink();
    }

    final data = continueLearning!;
    final title = (data['title'] as String?)?.trim().isNotEmpty == true
        ? data['title'] as String
        : 'Bootcamp Metro Institute';

    final mentorName = (data['mentorName'] as String?)?.trim().isNotEmpty == true
        ? data['mentorName'] as String
        : 'Mentor Metro';

    final rawProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
    final progress = (rawProgress / 100).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    int totalSessions = (data['totalSessions'] as num?)?.toInt() ?? 0;
    int completedSessions = (data['completedSessions'] as num?)?.toInt() ?? 0;

    // Fallback realistis jika backend belum menghitung session count
    if (totalSessions == 0) {
      totalSessions = 40;
      completedSessions = ((percent / 100) * totalSessions).round();
      if (percent > 0 && completedSessions == 0) completedSessions = 1;
    }

    final courseId = data['id']?.toString() ?? '';
    final sessionId = data['sessionId']?.toString() ?? '';

    void handleTap() {
      if (sessionId.isNotEmpty) {
        context.push('/learn/player/$sessionId');
      } else if (courseId.isNotEmpty) {
        context.push('/learn/course/$courseId');
      } else {
        context.go(AppRoutes.learn);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEF), // Soft pastel blossom pink dari referensi
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: const Color(0xFFFCDCE3), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
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
              // ── LAYER 0: Background Artwork (Lime Starburst + Whimsical Learner Art) ──
              Positioned.fill(
                child: CustomPaint(
                  painter: const _HeroLearnerArtPainter(),
                ),
              ),

              // ── LAYER 1: Card Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Title + Lesson Count (Left) & Circular Progress Tracker (Right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Title & Lesson count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  letterSpacing: -0.4,
                                  height: 1.22,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$completedSessions/$totalSessions Lesson Selesai',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4B5563),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Right: Circular Dark Progress Indicator with Pink Arc (Persis Referensi)
                        _buildCircularProgressIndicator(progress, percent),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Avatar stack + "+33" (Persis Referensi)
                    Row(
                      children: [
                        _buildAvatarStack(totalSessions),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Bottom Row: "By [Mentor]" + "LANJUT BELAJAR" Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'By $mentorName',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x28018556),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'LANJUT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  /// Circular dark badge with outer pink/coral ring arc (e.g. 78%)
  Widget _buildCircularProgressIndicator(double progress, int percent) {
    return SizedBox(
      width: 66,
      height: 66,
      child: CustomPaint(
        painter: _CircularProgressPainter(progress: progress),
        child: Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$percent',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: '%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stack of small colorful circular avatar bubbles (+33 badge) persis referensi
  Widget _buildAvatarStack(int totalCount) {
    final avatarColors = [
      const Color(0xFFFED7AA), // warm peach
      const Color(0xFFDDD6FE), // pastel lavender
      const Color(0xFFFEF08A), // pastel yellow
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 78,
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < avatarColors.length; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: avatarColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        i == 0
                            ? Icons.face_rounded
                            : (i == 1 ? Icons.face_3_rounded : Icons.face_6_rounded),
                        size: 16,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 3 * 16.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E242B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '+${totalCount > 3 ? totalCount - 3 : 12}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// CustomPainter untuk circular progress badge: Dark disk center dengan outer pink arc
class _CircularProgressPainter extends CustomPainter {
  final double progress;

  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dark center disk
    final diskPaint = Paint()
      ..color = const Color(0xFF1E242B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4.5, diskPaint);

    // 2. Track background ring
    final trackPaint = Paint()
      ..color = const Color(0xFFFF3377).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2;
    canvas.drawCircle(center, radius - 2.5, trackPaint);

    // 3. Active Progress Arc (Bright Coral/Pink #FF3377 dari referensi)
    final arcPaint = Paint()
      ..color = const Color(0xFFFF3377)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (progress.clamp(0.02, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// CustomPainter untuk Starburst Lime-Green & Whimsical Learner Artwork di sisi kanan
class _HeroLearnerArtPainter extends CustomPainter {
  const _HeroLearnerArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Starburst Lime-Green Shape di latar kanan (#C6F24D / #D4F768)
    final starPaint = Paint()
      ..color = const Color(0xFFD4F768).withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    final starCenter = Offset(w - 38, h - 35);
    final starPath = Path();
    const int points = 10;
    const double outerR = 64.0;
    const double innerR = 36.0;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points - (math.pi / 2);
      final r = (i % 2 == 0) ? outerR : innerR;
      final x = starCenter.dx + r * math.cos(angle);
      final y = starCenter.dy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);

    // 2. Whimsical Pie Chart Outline (near student)
    final pieLinePaint = Paint()
      ..color = const Color(0xFF1E242B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final pieFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pieCenter = Offset(w - 110, h - 85);
    const pieR = 14.0;
    canvas.drawCircle(pieCenter, pieR, pieFillPaint);
    canvas.drawCircle(pieCenter, pieR, pieLinePaint);
    canvas.drawLine(pieCenter, Offset(pieCenter.dx, pieCenter.dy - pieR), pieLinePaint);
    canvas.drawLine(pieCenter, Offset(pieCenter.dx + pieR * 0.8, pieCenter.dy + pieR * 0.4), pieLinePaint);

    // 3. Laptop outline di meja
    final laptopPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final laptopStroke = Paint()
      ..color = const Color(0xFF1E242B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final laptopPath = Path()
      ..moveTo(w - 95, h - 18)
      ..lineTo(w - 65, h - 48)
      ..lineTo(w - 32, h - 45)
      ..lineTo(w - 62, h - 15)
      ..close();
    canvas.drawPath(laptopPath, laptopPaint);
    canvas.drawPath(laptopPath, laptopStroke);

    // Laptop base / keyboard line
    canvas.drawLine(Offset(w - 98, h - 15), Offset(w - 55, h - 12), laptopStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
