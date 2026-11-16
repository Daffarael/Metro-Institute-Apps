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
                          color: Color(0xFF063D2A), // Metro Deep Emerald
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
                      color: const Color(0xFF063D2A), // Metro Deep Emerald
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
                          color: Color(0xFF063D2A), // Metro Deep Emerald
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
                color: const Color(0xFF018556), // Metro Green
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
                                    color: const Color(0xFF063D2A), // Metro Deep Emerald
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
                                        color: const Color(0xFF018556), // Metro Green
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
                                          color: Color(0xFF018556), // Metro Green
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
                                    color: const Color(0xFF063D2A), // Metro Deep Emerald
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
  // 1. TOP CARD: TODAY'S ACTIVITY (Kuning Hijau Metro — Tanpa Pudar, Tanpa Navy/Biru)
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
        color: const Color(0xFFFAE653), // Metro Accent Yellow (Bukan kuning pudar)
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5CE2D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA8A04).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
                        color: Color(0xFF063D2A), // Metro Deep Emerald
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
                            color: const Color(0xFF063D2A), // Metro Deep Emerald
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Big Real Percentage
                  Text(
                    '$_todayPercent%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF063D2A), // Metro Deep Emerald
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Slider Progress Bar with Circular Knob
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final trackWidth = constraints.maxWidth.clamp(100.0, 180.0);
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
                            // Metro Green active progress bar
                            FractionallySizedBox(
                              widthFactor: progressFraction,
                              child: Container(
                                height: 6.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF018556), // Metro Green
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
                                  color: Color(0xFF018556), // Metro Green
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFAE653), // Metro Yellow
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

                  // Status Text
                  Text(
                    _todayPercent == 0
                        ? 'Belum ada aktivitas selesai hari ini'
                        : '$_todayPercent% aktivitas hari ini selesai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF063D2A).withValues(alpha: 0.85),
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
                          color: const Color(0xFF063D2A).withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCA8A04).withValues(alpha: 0.50),
                              blurRadius: 14,
                              offset: const Offset(3, 7),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Calendar Block Body
                    Container(
                      width: 92,
                      height: 110,
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
                          // Top Metro Green Banner (Bukan Navy)
                          Container(
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFF018556), // Metro Green
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              monthShort,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
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
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF063D2A), // Metro Deep Emerald
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
                                color: const Color(0xFF018556), // Metro Green
                                letterSpacing: 1.1,
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
          ],
        ),
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
                    color: const Color(0xFF018556), // Metro Green
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fullMonthYear,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF063D2A), // Metro Deep Emerald
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
                      child: Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF063D2A)),
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
                      child: Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF063D2A)),
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
                  color: isSelected ? const Color(0xFF018556) : Colors.white, // Metro Green saat dipilih
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF018556) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF018556).withValues(alpha: 0.30),
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
                        color: isSelected ? const Color(0xFFE6F4EF) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : const Color(0xFF063D2A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFAE653) // Metro Yellow dot indicator
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
    final now = DateTime.now();
    final durationMinutes = (session['durationMinutes'] as num?)?.toInt() ?? 90;
    final liveUrl = (session['liveUrl'] as String?) ?? '';
    final recordingUrl = (session['recordingUrl'] as String?) ??
        (session['replayUrl'] as String?) ??
        (session['recording'] as String?) ?? '';
    final category = (session['category'] as String?) ?? 'Bootcamp Live';
    final isCompleted = session['isCompleted'] == true;

    // Formatting date & time
    String timeRange = '20:00 - 20:02';
    String dayNumStr = '02';
    String monthStr = 'NOV';
    final rawScheduled = session['scheduledAt'] as String?;
    DateTime? scheduledDate;
    DateTime? sessionEndDate;

    if (rawScheduled != null) {
      scheduledDate = DateTime.tryParse(rawScheduled)?.toLocal();
      if (scheduledDate != null) {
        sessionEndDate = scheduledDate.add(Duration(minutes: durationMinutes));
        final startTimeStr = DateFormat('HH:mm').format(scheduledDate);
        final endTimeStr = DateFormat('HH:mm').format(sessionEndDate);
        timeRange = '$startTimeStr - $endTimeStr';
        dayNumStr = scheduledDate.day.toString().padLeft(2, '0');
        monthStr = _monthNamesShort[scheduledDate.month - 1];
      }
    } else {
      dayNumStr = _selectedDate.day.toString().padLeft(2, '0');
      monthStr = _monthNamesShort[_selectedDate.month - 1];
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final selMidnight = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      if (selMidnight.isBefore(todayMidnight)) {
        sessionEndDate = DateTime(selMidnight.year, selMidnight.month, selMidnight.day, 23, 59);
      }
    }

    // Integrasi Jadwal Nyata:
    // 1. isPast: Waktu sesi sudah berakhir atau tanggalnya sudah lewat
    final bool isPast = isCompleted ||
        (sessionEndDate != null && now.isAfter(sessionEndDate)) ||
        (scheduledDate != null && now.isAfter(scheduledDate.add(Duration(minutes: durationMinutes)))) ||
        (scheduledDate != null && scheduledDate.isBefore(DateTime(now.year, now.month, now.day)));

    // 2. isLiveNow: Sesi sedang berlangsung sekarang (atau dibuka 15 menit sebelum mulai)
    final bool isLiveNow = !isPast &&
        scheduledDate != null &&
        now.isAfter(scheduledDate.subtract(const Duration(minutes: 15))) &&
        (sessionEndDate == null || now.isBefore(sessionEndDate));

    // 3. isUpcoming: Sesi masih di masa mendatang (belum dimulai)
    final bool isUpcoming = !isPast && !isLiveNow;

    final durationFormatted = '$durationMinutes min';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF018556), // Solid Bold Hijau Metro (Bukan hijau pudar)
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF018556).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time Pill & Mini Calendar Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time pill (White pill with status indicator)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLiveNow) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), // Live red indicator
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$timeRange · LIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFEF4444),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ] else if (isPast) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Color(0xFF018556), // Metro Green
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$timeRange · Selesai',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF063D2A), // Deep Emerald text
                            letterSpacing: 0.2,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF018556), // Metro Green
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeRange,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF063D2A), // Deep Emerald text
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
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
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Metro Yellow top header bar
                      Container(
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAE653), // Metro Yellow
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
                              color: const Color(0xFF063D2A),
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
                            color: const Color(0xFF018556),
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

            // Program Title (Metro Yellow on Green)
            Text(
              programTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFAE653), // Metro Yellow
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 6),

            // Session Title (Crisp Pure White on Green)
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 8),

            // Description (Soft Mint White on Green)
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE6F4EF),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 18),

            // Badges Row (Translucent White Chips on Green)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Duration Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        durationFormatted,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFFFAE653), // Metro Yellow
                      ),
                    ],
                  ),
                ),

                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Color(0xFFFAE653), // Metro Yellow
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── ACTION BUTTON / STATUS INTEGRASI JADWAL ──
            Align(
              alignment: Alignment.centerLeft,
              child: isPast
                  ? (recordingUrl.isNotEmpty
                      // Jika sudah lewat & ada rekaman: Sediakan tombol Tonton Rekaman
                      ? GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _openLiveUrl(recordingUrl);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAE653), // Metro Yellow
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 18,
                                  color: Color(0xFF063D2A),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tonton Rekaman',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF063D2A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      // Jika sudah lewat & belum/tidak ada rekaman: Tampilkan status 'Sesi Telah Berakhir' (TIDAK ADA TOMBOL MASUK)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: Color(0xFFFAE653), // Metro Yellow
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Sesi Telah Berakhir',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ))
                  : (isLiveNow
                      // Sesi sedang berlangsung: Tombol 'Masuk kelas' aktif
                      ? GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            if (liveUrl.isNotEmpty) {
                              _openLiveUrl(liveUrl);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tautan kelas live sedang disiapkan mentor.',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: const Color(0xFF063D2A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAE653), // Bold Metro Yellow
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_rounded,
                                  size: 18,
                                  color: Color(0xFF063D2A),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Masuk kelas',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF063D2A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      // Sesi di masa mendatang (Belum Dimulai): Indikator belum dibuka
                      : GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final timeInfo = scheduledDate != null
                                ? 'pukul ${DateFormat('HH:mm').format(scheduledDate)} WIB'
                                : 'jadwal yang ditentukan';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sesi live belum dimulai. Tautan akan dibuka 15 menit sebelum $timeInfo.',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFF063D2A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_clock_rounded,
                                  size: 15,
                                  color: Color(0xFFFAE653),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Belum Dimulai',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
            ),
          ],
        ),
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
              color: const Color(0xFF063D2A), // Metro Deep Emerald
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
