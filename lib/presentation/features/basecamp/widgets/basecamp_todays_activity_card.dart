import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampTodaysActivityCard — Widget Ringkasan 'Today's Activity' di Basecamp.
/// Mengadopsi visual persis kartu referensi:
/// • Background Warm Yellow Pastel (#FEEFA6)
/// • Progres harian dengan slider progress bar & knob kuning
/// • 3D Tear-off Calendar Block 'NOV 02 SENIN' + floating trophy circle
/// • Klik langsung membuka halaman penuh LearningTimelineScreen.
class BasecampTodaysActivityCard extends StatelessWidget {
  static const List<String> _monthNamesShort = [
    'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
  ];

  static const List<String> _dayNamesFull = [
    'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'
  ];

  final Map<String, dynamic>? dailyMissions;
  final Map<String, dynamic>? basecampData;

  const BasecampTodaysActivityCard({
    super.key,
    this.dailyMissions,
    this.basecampData,
  });

  @override
  Widget build(BuildContext context) {
    // Hitung persentase dinamis dari database (dailyMissions)
    final missionsList = (dailyMissions?['missions'] as List?) ?? [];
    int completedCount = 0;
    for (final m in missionsList) {
      if (m is Map && m['completed'] == true) completedCount++;
    }
    int percent = 0;
    if (missionsList.isNotEmpty) {
      percent = ((completedCount / missionsList.length) * 100).round();
    } else {
      int score = 0;
      if (dailyMissions?['watchedVideo'] == true) score++;
      if (dailyMissions?['didChallenge'] == true) score++;
      percent = ((score / 2) * 100).round();
    }

    final progressFraction = (percent / 100).clamp(0.02, 1.0);
    final now = DateTime.now();
    final monthShort = _monthNamesShort[now.month - 1];
    final dayStr = now.day.toString().padLeft(2, '0');
    final dayNameUpper = _dayNamesFull[now.weekday - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEEFA6), // Soft warm pastel yellow
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFDE047), width: 1.0),
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
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Background Waffle Grid Watermark on Right
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 150,
                child: CustomPaint(
                  painter: _CardWafflePainter(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.35),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Icon + Title + Percent + Slider + Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 17,
                                color: Color(0xFF1E242B),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                "Today's Activity",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E242B),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 7),

                          // Big Percentage
                          Text(
                            '$percent%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E242B),
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Slider Progress Bar with Knob
                          SizedBox(
                            width: 155,
                            height: 14,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressFraction,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E242B),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: ((155.0 - 13.0) * progressFraction).clamp(0.0, 155.0 - 13.0),
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E242B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFAE653),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Status text
                          Text(
                            percent == 0
                                ? 'Belum ada aktivitas selesai hari ini'
                                : '$percent% aktivitas hari ini selesai',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF57534E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right Column: 3D Tear-off Calendar Block with Trophy Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Calendar Block
                        Container(
                          width: 82,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top dark banner
                              Container(
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E242B),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  monthShort,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              // Big Date Number
                              Expanded(
                                child: Center(
                                  child: Text(
                                    dayStr,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E242B),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              // Day Subtitle
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Text(
                                  dayNameUpper,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Floating Trophy Icon Badge at bottom-right corner
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.emoji_events_outlined,
                                size: 16,
                                color: Color(0xFF1E242B),
                              ),
                            ),
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
