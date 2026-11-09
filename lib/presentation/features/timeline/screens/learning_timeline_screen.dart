import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/basecamp_remote_datasource.dart';
import '../../../../core/di/injection_container.dart';

/// LearningTimelineScreen — Layar Jadwal & Linimasa Belajar Harian Mentee.
/// Mengadopsi visual persis 1:1 dari referensi desain:
/// • Header: Back circular button + 'Learning Timeline' + Filter circular button
/// • Card Atas: 'Todays Activity' (kuning pastel, persen tebal 73%, slider bar, trophy icon, waffle grid)
/// • Strip Kalender: M, T, W, T, F, S, S (pill squircle, dark pill untuk hari aktif)
/// • Timeline Header: 'Timeline' + icon calendar
/// • Kartu Jadwal: Pastel Blue (Math Tutorials), Pastel Pink (AI Classes), Pastel Mint (Live Mentoring)
///   lengkap dengan time pill gelap '✓ 9:00 - 10.30', subtitle, tag durasi '1h 10 min 🕒', dan level 'Intensive ⚡'.
class LearningTimelineScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const LearningTimelineScreen({super.key, this.initialData});

  @override
  State<LearningTimelineScreen> createState() => _LearningTimelineScreenState();
}

class _LearningTimelineScreenState extends State<LearningTimelineScreen> {
  int _selectedDayIndex = 3; // Default pada 'T 17' persis referensi
  bool _isLoading = false;
  Map<String, dynamic>? _basecampData;

  // 7 hari dalam seminggu persis referensi (M 14, T 15, W 16, T 17, F 18, S 19, S 20)
  late final List<Map<String, dynamic>> _weekDays;

  @override
  void initState() {
    super.initState();
    _basecampData = widget.initialData;

    final now = DateTime.now();
    // Cari hari Senin minggu ini
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    _weekDays = List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return {
        'label': dayLabels[i],
        'date': date.day,
        'fullDate': date,
      };
    });

    // Pilih hari ini secara default jika dalam range, atau index 3
    final todayWeekdayIndex = now.weekday - 1;
    if (todayWeekdayIndex >= 0 && todayWeekdayIndex < 7) {
      _selectedDayIndex = todayWeekdayIndex;
    }

    if (_basecampData == null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final ds = sl<BasecampRemoteDataSource>();
      final data = await ds.getBasecampData();
      if (mounted) {
        setState(() {
          _basecampData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung persentase aktivitas hari ini secara dinamis dari dailyMissions jika ada
    final dailyMissions = _basecampData?['dailyMissions'] as Map<String, dynamic>?;
    final missionsList = (dailyMissions?['missions'] as List?) ?? [];
    int completedCount = 0;
    for (final m in missionsList) {
      if (m is Map && m['completed'] == true) completedCount++;
    }
    final int dynamicPercent = missionsList.isNotEmpty
        ? ((completedCount / missionsList.length) * 100).round()
        : 73; // Fallback 73% persis referensi

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // Light soft pastel canvas
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Top Navigation Bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button Circular
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/basecamp');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Color(0xFF1E242B),
                        ),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Learning Timeline',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E242B),
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Filter / Settings Button Circular
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: Color(0xFF1E242B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Scrollable Content ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // ── Card Atas: 'Todays Activity' (Kuning Pastel) ────────
                    _buildTodaysActivityCard(dynamicPercent),

                    const SizedBox(height: 20),

                    // ── Strip Hari dalam Seminggu (M, T, W, T, F, S, S) ────
                    _buildWeekDayStrip(),

                    const SizedBox(height: 26),

                    // ── Timeline Section Header ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Timeline',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E242B),
                            letterSpacing: -0.4,
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.calendar_month_outlined,
                              size: 19,
                              color: Color(0xFF1E242B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Kartu 1: Math Tutorials (Sky Blue) ─────────────────
                    _buildTimelineCard(
                      bgColor: const Color(0xFFD6EBFC), // Soft Pastel Sky Blue
                      gridColor: const Color(0xFFC2E1FA),
                      pillBgColor: const Color(0xFF1E242B),
                      pillText: '✓  9:00 - 10.30',
                      title: 'Math Tutorials',
                      subtitle: 'Interactive lessons make learning math fun and easy',
                      durationTag: '1h 10 min',
                      badgeTag: 'Intensive',
                      tagBorderColor: const Color(0xFFB5DBFA),
                      tagBgColor: const Color(0xFFCAE5FC),
                    ),

                    const SizedBox(height: 16),

                    // ── Kartu 2: AI Classes (Blossom Pink) ─────────────────
                    _buildTimelineCard(
                      bgColor: const Color(0xFFFDE1EE), // Soft Pastel Blossom Pink
                      gridColor: const Color(0xFFF9CADE),
                      pillBgColor: const Color(0xFF1E242B),
                      pillText: '✓  9:00 - 10.30',
                      title: 'AI Classes',
                      subtitle: 'AI classes designed to boost your skills and understanding',
                      durationTag: '1h 30 min',
                      badgeTag: 'Intensive',
                      tagBorderColor: const Color(0xFFF6C0D9),
                      tagBgColor: const Color(0xFFFAD4E6),
                    ),

                    const SizedBox(height: 16),

                    // ── Kartu 3: UI/UX & Web Development (Pastel Mint) ─────
                    _buildTimelineCard(
                      bgColor: const Color(0xFFE0F6EC), // Soft Pastel Mint Green
                      gridColor: const Color(0xFFC7EFDC),
                      pillBgColor: const Color(0xFF1E242B),
                      pillText: '✓  14:00 - 15.30',
                      title: 'Frontend & UI Lab',
                      subtitle: 'Mastering modern interactive layouts and responsive web apps',
                      durationTag: '1h 45 min',
                      badgeTag: 'Hands-on',
                      tagBorderColor: const Color(0xFFB5E8CE),
                      tagBgColor: const Color(0xFFD0F0DF),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. TOP CARD: TODAYS ACTIVITY (Soft Butter Cream Pastel)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTodaysActivityCard(int percent) {
    final progressFraction = (percent / 100).clamp(0.05, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C2), // Butter Cream Pastel (#FFF3C2)
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Waffle Grid Watermark on Right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 150,
            child: CustomPaint(
              painter: _WaffleGridPainter(
                color: const Color(0xFFFCE69B).withValues(alpha: 0.55),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 20, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Icon + Title + Percent + Slider Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Book Icon + 'Todays Activity'
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: Color(0xFF1E242B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Todays Activity',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Big Percentage 73%
                      Text(
                        '$percent%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E242B),
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Slider Progress Bar with Rounded Thumb
                      SizedBox(
                        width: 175,
                        height: 14,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Track (White/cream)
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            // Active Progress Bar (Dark)
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
                            // Thumb Slider Pill
                            Positioned(
                              left: (175 * progressFraction) - 7,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E242B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right Column: White Circular Trophy Container
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 26,
                      color: Color(0xFF1E242B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. DAY SELECTOR STRIP (M 14, T 15, W 16, T 17, F 18, S 19, S 20)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildWeekDayStrip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_weekDays.length, (index) {
        final item = _weekDays[index];
        final isSelected = index == _selectedDayIndex;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDayIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E242B) : const Color(0xFFEBF1F6),
              borderRadius: BorderRadius.circular(22),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1E242B).withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['date']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF1E242B),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. TIMELINE CARD (Sky Blue, Blossom Pink, Pastel Mint)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineCard({
    required Color bgColor,
    required Color gridColor,
    required Color pillBgColor,
    required String pillText,
    required String title,
    required String subtitle,
    required String durationTag,
    required String badgeTag,
    required Color tagBorderColor,
    required Color tagBgColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Waffle Grid Watermark
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 140,
            child: CustomPaint(
              painter: _WaffleGridPainter(
                color: gridColor.withValues(alpha: 0.65),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Pill (✓ 9:00 - 10.30)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: pillBgColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        pillText.replaceFirst('✓  ', ''),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E242B),
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 18),

                // Bottom Tags (1h 10 min 🕒, Intensive ⚡)
                Row(
                  children: [
                    // Duration Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: tagBgColor.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tagBorderColor, width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            durationTag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF1E242B),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Badge Tag (Intensive ⚡)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: tagBgColor.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tagBorderColor, width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            badgeTag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.bolt_rounded,
                            size: 15,
                            color: Color(0xFF1E242B),
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
    );
  }
}

/// CustomPainter untuk Waffle / Soft Rounded Square Grid di sisi kanan kartu
class _WaffleGridPainter extends CustomPainter {
  final Color color;

  const _WaffleGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double cellSize = 28.0;
    const double radius = 8.0;
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
  bool shouldRepaint(covariant _WaffleGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
