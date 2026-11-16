import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/basecamp_remote_datasource.dart';

/// LearningTimelineScreen — Terintegrasi Penuh dengan Database Backend (/users/timeline).
/// Menampilkan jadwal sesi live mentee dengan visual presisi 1:1 sesuai desain:
/// • Card Atas: 'Today's Activity' dengan kalender 3D blok 'NOV 02 SENIN' + floating trophy icon
/// • Section Jadwal Mingguan: Header 'JADWAL MINGGUAN', Bulan/Tahun besar, nav panah, pill hari 'Sen 2', 'Sel 3', dll.
/// • Timeline Card: Kartu biru dengan watermark '02 NOV', mini calendar badge (kuning-putih), deskripsi, dan tombol 'Masuk kelas'.
class LearningTimelineScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const LearningTimelineScreen({super.key, this.initialData});

  @override
  State<LearningTimelineScreen> createState() => _LearningTimelineScreenState();
}

class _LearningTimelineScreenState extends State<LearningTimelineScreen> {
  static const List<String> _monthNamesShort = [
    'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
  ];

  static const List<String> _monthNamesFull = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _dayNamesShort = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];

  static const List<String> _dayNamesFull = [
    'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'
  ];

  bool _isLoading = true;
  List<Map<String, dynamic>> _allLiveSessions = [];
  int _todayPercent = 0;

  late DateTime _selectedDate;
  late DateTime _currentMonday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Senin minggu ini
    _currentMonday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final ds = sl<BasecampRemoteDataSource>();
      final data = await ds.getTimelineData();

      final rawTimeline = (data['timeline'] as List?) ?? [];
      final liveSessions = rawTimeline
          .whereType<Map<String, dynamic>>()
          .toList();

      final todaysActivity = data['todaysActivity'] as Map<String, dynamic>?;
      final percent = (todaysActivity?['percent'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          _allLiveSessions = liveSessions;
          _todayPercent = percent;
          _isLoading = false;
        });

        // Cari sesi live terdekat jika hari ini belum ada
        if (_allLiveSessions.isNotEmpty) {
          final hasSessionToday = _allLiveSessions.any((s) {
            final dateStr = s['scheduledAt'] as String?;
            if (dateStr == null) return false;
            final d = DateTime.tryParse(dateStr)?.toLocal();
            if (d == null) return false;
            return d.year == _selectedDate.year &&
                d.month == _selectedDate.month &&
                d.day == _selectedDate.day;
          });

          if (!hasSessionToday) {
            DateTime? nearestDate;
            for (final s in _allLiveSessions) {
              final dateStr = s['scheduledAt'] as String?;
              if (dateStr == null) continue;
              final d = DateTime.tryParse(dateStr)?.toLocal();
              if (d != null) {
                nearestDate = DateTime(d.year, d.month, d.day);
                break;
              }
            }
            if (nearestDate != null) {
              _selectedDate = nearestDate;
              _currentMonday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
            }
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeWeek(int deltaWeeks) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonday = _currentMonday.add(Duration(days: deltaWeeks * 7));
      _selectedDate = _currentMonday;
    });
  }

  List<Map<String, dynamic>> _getSessionsForDate(DateTime targetDate) {
    return _allLiveSessions.where((s) {
      final dateStr = s['scheduledAt'] as String?;
      if (dateStr == null) return false;
      final d = DateTime.tryParse(dateStr)?.toLocal();
      if (d == null) return false;
      return d.year == targetDate.year &&
          d.month == targetDate.month &&
          d.day == targetDate.day;
    }).toList();
  }

  bool _dateHasSession(DateTime date) {
    return _allLiveSessions.any((s) {
      final dateStr = s['scheduledAt'] as String?;
      if (dateStr == null) return false;
      final d = DateTime.tryParse(dateStr)?.toLocal();
      if (d == null) return false;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    });
  }

  Future<void> _openLiveUrl(String url) async {
    if (url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sessionsToday = _getSessionsForDate(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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

                  // Refresh Button
                  GestureDetector(
                    onTap: _fetchTimeline,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 20,
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
              child: RefreshIndicator(
                color: const Color(0xFF1E242B),
                onRefresh: _fetchTimeline,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF018556),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),

                            // ── Card Atas: 'Today's Activity' (Persis Referensi ca94f604.jpg) ──
                            _buildTodaysActivityCard(),

                            const SizedBox(height: 22),

                            // ── Strip Hari dalam Seminggu: 'JADWAL MINGGUAN' ──
                            _buildWeekDayStrip(),

                            const SizedBox(height: 24),

                            // ── Timeline Section Header ────────────────────
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
                                Row(
                                  children: [
                                    Text(
                                      '${_selectedDate.day} ${_monthNamesFull[_selectedDate.month - 1]} ${_selectedDate.year}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0), width: 1.2),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.calendar_month_outlined,
                                          size: 18,
                                          color: Color(0xFF1E242B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ── List Sesi Live pada Hari yang Dipilih (Persis Referensi b5b71a91.jpg) ──
                            if (sessionsToday.isNotEmpty) ...[
                              for (int i = 0; i < sessionsToday.length; i++) ...[
                                _buildLiveSessionCard(sessionsToday[i], i),
                                const SizedBox(height: 16),
                              ],
                            ] else ...[
                              // Empty state untuk hari yang dipilih
                              _buildEmptyStateForSelectedDate(),
                              const SizedBox(height: 24),

                              // Tampilkan seluruh sesi live yang terdaftar agar mentee mudah melihat agendanya
                              if (_allLiveSessions.isNotEmpty) ...[
                                Text(
                                  'Semua Sesi Live Terdaftar (${_allLiveSessions.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E242B),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                for (int i = 0; i < _allLiveSessions.length; i++) ...[
                                  _buildLiveSessionCard(_allLiveSessions[i], i, showFullDate: true),
                                  const SizedBox(height: 14),
                                ],
                              ],
                            ],

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. TOP CARD: TODAY'S ACTIVITY (Persis Referensi: Kuning Pastel, Tilted 3D Calendar, Trophy Badge)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTodaysActivityCard() {
    final progressFraction = (_todayPercent / 100).clamp(0.02, 1.0);
    final now = DateTime.now();
    final monthShort = _monthNamesShort[now.month - 1];
    final dayStr = now.day.toString().padLeft(2, '0');
    final dayNameUpper = _dayNamesFull[now.weekday - 1];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0A6), // Soft warm pastel yellow
        borderRadius: BorderRadius.circular(32),
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
      child: Stack(
        children: [
          // Subtle Dot Pattern (Menggantikan waffle kotak-kotak)
          Positioned.fill(
            child: CustomPaint(
              painter: _DotPatternPainter(
                color: const Color(0xFFB45309).withValues(alpha: 0.13),
                spacing: 22.0,
                dotRadius: 1.25,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
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
                            size: 20,
                            color: Color(0xFF1E242B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Today's Activity",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Big Real Percentage
                      Text(
                        '$_todayPercent%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E242B),
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Slider Progress Bar with Circular Knob
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final trackWidth = constraints.maxWidth.clamp(140.0, 200.0);
                          const knobSize = 18.0;
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
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                // Dark active progress bar
                                FractionallySizedBox(
                                  widthFactor: progressFraction,
                                  child: Container(
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E242B),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                // Circular knob with centered yellow dot
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
                                        width: 5.5,
                                        height: 5.5,
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

                      const SizedBox(height: 14),

                      // Status Text
                      Text(
                        _todayPercent == 0
                            ? 'Belum ada aktivitas selesai hari ini'
                            : '$_todayPercent% aktivitas hari ini selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF786227),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

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
                          left: 6,
                          top: 8,
                          right: -6,
                          bottom: -8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2B93B).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCA8A04).withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(4, 8),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Calendar Block Body
                        Container(
                          width: 104,
                          height: 124,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top Dark Navy Banner
                              Container(
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E242B),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  monthShort,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                              ),

                              // Big Date Number
                              Expanded(
                                child: Center(
                                  child: Text(
                                    dayStr,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E242B),
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),

                              // Day Subtitle
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  dayNameUpper,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Overlapping Floating Trophy Badge at bottom-right corner
                        Positioned(
                          bottom: -6,
                          right: -8,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFEF08A), // Thick soft yellow ring
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCA8A04).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(1, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.emoji_events_outlined,
                                size: 20,
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. DAY SELECTOR STRIP: 'JADWAL MINGGUAN' (Sesuai Desain Referensi ca94f604.jpg)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildWeekDayStrip() {
    final fullMonthYear = '${_monthNamesFull[_currentMonday.month - 1]} ${_currentMonday.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "JADWAL MINGGUAN" label + Month Year + Nav Arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JADWAL MINGGUAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fullMonthYear,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E242B),
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _changeWeek(-1),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: const Center(
                      child: Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF1E242B)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _changeWeek(1),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: const Center(
                      child: Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF1E242B)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Day Pills: Sen, Sel, Rab, Kam, Jum, Sab, Min
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final date = _currentMonday.add(Duration(days: index));
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final hasSession = _dateHasSession(date);
            final dayLabel = _dayNamesShort[index];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDate = date);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 72,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E242B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E242B) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
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
                      dayLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : const Color(0xFF1E242B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFAE653)
                            : (hasSession ? const Color(0xFF018556) : Colors.transparent),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. LIVE SESSION CARD (Sesuai Desain Referensi b5b71a91.jpg)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLiveSessionCard(Map<String, dynamic> session, int index, {bool showFullDate = false}) {
    final title = (session['title'] as String?) ?? 'Introduction to UI/UX';
    final rawProgramTitle = (session['programTitle'] as String?) ?? 'Bootcamp Metro Institute';
    final programTitle = rawProgramTitle.toUpperCase().contains('SEASON')
        ? rawProgramTitle.toUpperCase()
        : '${rawProgramTitle.toUpperCase()} · SEASON 2';
    final description = (session['description'] as String?) ??
        'Fokus Pembelajaran: Mengenal UI/UX dan memahami masalah pengguna.';
    final durationMinutes = (session['durationMinutes'] as num?)?.toInt() ?? 90;
    final liveUrl = (session['liveUrl'] as String?) ?? '';
    final category = (session['category'] as String?) ?? 'Bootcamp Live';
    final isCompleted = session['isCompleted'] == true;

    // Formatting date & time
    String timeRange = '20:00 - 20:02';
    String dayNumStr = '02';
    String monthStr = 'NOV';
    final rawScheduled = session['scheduledAt'] as String?;
    if (rawScheduled != null) {
      final scheduledDate = DateTime.tryParse(rawScheduled)?.toLocal();
      if (scheduledDate != null) {
        final startTimeStr = DateFormat('HH:mm').format(scheduledDate);
        final endDate = scheduledDate.add(Duration(minutes: durationMinutes));
        final endTimeStr = DateFormat('HH:mm').format(endDate);
        timeRange = '$startTimeStr - $endTimeStr';
        dayNumStr = scheduledDate.day.toString().padLeft(2, '0');
        monthStr = _monthNamesShort[scheduledDate.month - 1];
      }
    } else {
      dayNumStr = _selectedDate.day.toString().padLeft(2, '0');
      monthStr = _monthNamesShort[_selectedDate.month - 1];
    }

    final durationFormatted = '$durationMinutes min';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD6EEFF), // Soft Sky Blue
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Grid Blueprint Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _GridBlueprintPainter(
                color: const Color(0xFFBAE6FD).withValues(alpha: 0.55),
              ),
            ),
          ),

          // Big Translucent Watermark (e.g. 02 NOV) in bottom-right corner
          Positioned(
            right: 12,
            bottom: -6,
            child: IgnorePointer(
              child: Text(
                '$dayNumStr\n$monthStr',
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 78,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFBAE6FD).withValues(alpha: 0.45),
                  height: 0.88,
                  letterSpacing: -2.0,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Time Pill & Mini Calendar Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E242B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_rounded : Icons.check_rounded,
                            size: 13,
                            color: const Color(0xFFFAE653),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeRange,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mini Calendar Card on Top-Right
                    Container(
                      width: 54,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
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
                          // Yellow top header bar
                          Container(
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAB308),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                dayNumStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1E242B),
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              monthStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Program Title (Green uppercase)
                Text(
                  programTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF018556),
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 5),

                // Session Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E242B),
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 18),

                // Badges Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Duration Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBAE6FD).withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF93C5FD), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            durationFormatted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Color(0xFF1E242B),
                          ),
                        ],
                      ),
                    ),

                    // Category Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBAE6FD).withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF93C5FD), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: Color(0xFF1E242B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Join Button: "🎥 Masuk kelas"
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (liveUrl.isNotEmpty) {
                      _openLiveUrl(liveUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tautan kelas live akan dibuka menjelang sesi dimulai.',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF1E242B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E242B),
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
                          Icons.videocam_rounded,
                          size: 16,
                          color: Color(0xFFFAE653), // Yellow video icon
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Masuk kelas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
  // 4. EMPTY STATE KETIKA TIDAK ADA SESI PADA HARI TERSEBUT
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyStateForSelectedDate() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.calendar_today_rounded,
                size: 22,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak Ada Sesi Live Hari Ini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E242B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _allLiveSessions.isEmpty
                ? 'Belum ada jadwal sesi live untuk kelas yang kamu ikuti. Sesi live akan muncul saat kamu membeli Bootcamp atau Inspire Talk.'
                : 'Tidak ada sesi live pada tanggal ${_selectedDate.day} ${_monthNamesFull[_selectedDate.month - 1]} ${_selectedDate.year}. Pilih tanggal lain di kalender.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk Dot Pattern di kartu Today's Activity (menggantikan waffle kotak-kotak)
class _DotPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double dotRadius;

  const _DotPatternPainter({
    required this.color,
    this.spacing = 22.0,
    this.dotRadius = 1.25,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.spacing != spacing ||
      oldDelegate.dotRadius != dotRadius;
}

/// Grid Blueprint lines painter untuk kartu sesi biru
class _GridBlueprintPainter extends CustomPainter {
  final Color color;
  const _GridBlueprintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double step = 28.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBlueprintPainter oldDelegate) =>
      oldDelegate.color != color;
}
