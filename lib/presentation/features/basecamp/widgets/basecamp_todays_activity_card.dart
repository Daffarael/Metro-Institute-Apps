import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampTodaysActivityCard — Widget Ringkasan 'Today's Activity' di Basecamp.
/// Mengadopsi visual persis kartu referensi:
/// • Background Warm Yellow Pastel Polos (#FDF0A6) — Bersih tanpa polkadot / waffle
/// • Progres harian dengan slider progress bar & knob lingkaran
/// • 3D Tilted Calendar Block 'NOV 02 SENIN' dengan bayangan keemasan + floating trophy badge
/// • Responsif dan bebas dari overflow di berbagai ukuran layar.
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
        color: const Color(0xFFFDF0A6), // Soft warm pastel yellow (Clean solid)
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFACC15).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                            Icons.menu_book_outlined,
                            size: 19,
                            color: Color(0xFF1E242B),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              "Today's Activity",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E242B),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Big Percentage
                      Text(
                        '$percent%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E242B),
                          letterSpacing: -1.2,
                          height: 1.0,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Slider Progress Bar with Knob
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final trackWidth = constraints.maxWidth.clamp(100.0, 170.0);
                          const knobSize = 17.0;
                          final knobLeft = ((trackWidth - knobSize) * progressFraction)
                              .clamp(0.0, trackWidth - knobSize);

                          return SizedBox(
                            width: trackWidth,
                            height: knobSize,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // White rounded track
                                Container(
                                  height: 6.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                // Active progress fill
                                FractionallySizedBox(
                                  widthFactor: progressFraction,
                                  child: Container(
                                    height: 6.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E242B),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                // Circular knob
                                Positioned(
                                  left: knobLeft,
                                  child: Container(
                                    width: knobSize,
                                    height: knobSize,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E242B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFCE788),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Status text
                      Text(
                        percent == 0
                            ? 'Belum ada aktivitas selesai hari ini'
                            : '$percent% aktivitas hari ini selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF786227),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right Column: 3D Tilted Calendar Block with Trophy Badge
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
                  child: Transform.rotate(
                    angle: -0.06, // ~ -3.5 degrees counter-clockwise tilt
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Golden 3D Cast Shadow / Base Extrusion
                        Positioned(
                          left: 5,
                          top: 7,
                          right: -5,
                          bottom: -7,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2B93B).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCA8A04).withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(3, 7),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Calendar Block Body
                        Container(
                          width: 90,
                          height: 108,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 7,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top Dark Navy Banner
                              Container(
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E242B),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  monthShort,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),

                              // Big Date Number
                              Expanded(
                                child: Center(
                                  child: Text(
                                    dayStr,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E242B),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),

                              // Day Subtitle
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  dayNameUpper,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Overlapping Floating Trophy Badge at bottom-right corner
                        Positioned(
                          bottom: -5,
                          right: -7,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFEF08A), // Thick soft yellow ring
                                width: 3.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCA8A04).withValues(alpha: 0.35),
                                  blurRadius: 7,
                                  offset: const Offset(1, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.emoji_events_outlined,
                                size: 18,
                                color: Color(0xFF1E242B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
