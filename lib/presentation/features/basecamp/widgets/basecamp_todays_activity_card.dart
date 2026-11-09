import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampTodaysActivityCard — Widget Ringkasan 'Aktivitas Hari Ini' di Basecamp.
/// Mengadopsi visual persis kartu atas referensi Learning Timeline:
/// • Background Butter Cream Pastel (#FFF3C2)
/// • Progres harian 73% dengan slider progress bar & thumb
/// • Trophy container bulat putih di sisi kanan
/// • Klik langsung membuka halaman penuh LearningTimelineScreen.
class BasecampTodaysActivityCard extends StatelessWidget {
  final Map<String, dynamic>? dailyMissions;
  final Map<String, dynamic>? basecampData;

  const BasecampTodaysActivityCard({
    super.key,
    this.dailyMissions,
    this.basecampData,
  });

  @override
  Widget build(BuildContext context) {
    // Hitung persentase dinamis dari dailyMissions jika ada
    final missionsList = (dailyMissions?['missions'] as List?) ?? [];
    int completedCount = 0;
    for (final m in missionsList) {
      if (m is Map && m['completed'] == true) completedCount++;
    }
    final int percent = missionsList.isNotEmpty
        ? ((completedCount / missionsList.length) * 100).round()
        : 73; // Fallback 73% persis referensi

    final progressFraction = (percent / 100).clamp(0.05, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C2), // Butter Cream Pastel
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              AppRoutes.learningTimeline,
              extra: basecampData,
            );
          },
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Background Waffle Grid Watermark on Right
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 140,
                child: CustomPaint(
                  painter: _CardWafflePainter(
                    color: const Color(0xFFFCE69B).withValues(alpha: 0.55),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Icon + Title + Percent + Slider + Hint Link
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: Color(0xFF1E242B),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Todays Activity',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E242B),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Big Percentage 73%
                          Text(
                            '$percent%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E242B),
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Slider Progress Bar
                          SizedBox(
                            width: 160,
                            height: 14,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressFraction,
                                  child: Container(
                                    height: 5.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E242B),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: (160 * progressFraction) - 6,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E242B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Small hint row: 'Buka Learning Timeline' + Arrow
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Buka Learning Timeline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: Color(0xFF475569),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right Column: White Circular Trophy Container
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events_outlined,
                          size: 25,
                          color: Color(0xFF1E242B),
                        ),
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
}

class _CardWafflePainter extends CustomPainter {
  final Color color;

  const _CardWafflePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double cellSize = 26.0;
    const double radius = 7.0;
    const double spacing = 6.0;

    final cols = (size.width / (cellSize + spacing)).ceil() + 1;
    final rows = (size.height / (cellSize + spacing)).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final left = size.width - ((c + 1) * (cellSize + spacing));
        final top = r * (cellSize + spacing) + 4;

        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, cellSize, cellSize),
          const Radius.circular(radius),
        );
        canvas.drawRRect(rrect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardWafflePainter oldDelegate) =>
      oldDelegate.color != color;
}
