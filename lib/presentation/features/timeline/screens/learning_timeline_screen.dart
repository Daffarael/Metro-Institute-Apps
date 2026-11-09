import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/basecamp_remote_datasource.dart';

/// LearningTimelineScreen — Terintegrasi Penuh dengan Database Backend (/users/timeline).
/// Menampilkan HANYA sesi live (Live Bootcamp & Live Inspire Talk/Webinar) dari program yang dibeli mentee.
/// Mengadopsi visual persis 1:1 dari referensi desain:
/// • Top Bar: Back button, Title, Filter button
/// • Top Card: 'Todays Activity' (persentase dinamis dari aktivitas/sesi live hari ini)
/// • Strip Kalender: M, T, W, T, F, S, S dengan navigasi minggu & indikator titik pada tanggal berjadwal
/// • Section Timeline: Menampilkan sesi live nyata dari database, lengkap dengan jam, durasi, dan link live.
class LearningTimelineScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const LearningTimelineScreen({super.key, this.initialData});

  @override
  State<LearningTimelineScreen> createState() => _LearningTimelineScreenState();
}

class _LearningTimelineScreenState extends State<LearningTimelineScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allLiveSessions = [];
  int _todayPercent = 0;
  int _totalSessionsToday = 0;
  int _completedSessionsToday = 0;

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
        _error = null;
      });

      final ds = sl<BasecampRemoteDataSource>();
      final data = await ds.getTimelineData();

      final rawTimeline = (data['timeline'] as List?) ?? [];
      final liveSessions = rawTimeline
          .whereType<Map<String, dynamic>>()
          .toList();

      final todaysActivity = data['todaysActivity'] as Map<String, dynamic>?;
      final percent = (todaysActivity?['percent'] as num?)?.toInt() ?? 0;
      final totalToday = (todaysActivity?['totalSessionsToday'] as num?)?.toInt() ?? 0;
      final completedToday = (todaysActivity?['completedSessionsToday'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          _allLiveSessions = liveSessions;
          _todayPercent = percent;
          _totalSessionsToday = totalToday;
          _completedSessionsToday = completedToday;
          _isLoading = false;
        });

        // Jika hari ini tidak ada sesi, tapi user punya sesi terdaftar di minggu lain,
        // kita bisa otomatis set tanggal yang memiliki sesi terdekat agar mentee langsung melihat jadwalnya
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
            // Cari sesi terdekat (bisa yang akan datang atau yang terakhir)
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
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

                  // Refresh / Filter Button
                  GestureDetector(
                    onTap: _fetchTimeline,
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

                            // ── Card Atas: 'Todays Activity' (Dinamis dari DB) ──
                            _buildTodaysActivityCard(),

                            const SizedBox(height: 20),

                            // ── Strip Hari dalam Seminggu dengan Navigasi ──
                            _buildWeekDayStrip(),

                            const SizedBox(height: 26),

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
                                      DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
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

                            // ── List Sesi Live pada Hari yang Dipilih ────────
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
  // 1. TOP CARD: TODAYS ACTIVITY (100% Dinamis dari Database)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTodaysActivityCard() {
    final progressFraction = (_todayPercent / 100).clamp(0.02, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C2), // Butter Cream Pastel
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
          // Background Waffle Grid Watermark
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

                      // Big Real Percentage
                      Text(
                        '$_todayPercent%',
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

                // Right Column: Circular Trophy Container
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
                  child: Center(
                    child: Icon(
                      _todayPercent >= 100
                          ? Icons.emoji_events_rounded
                          : Icons.emoji_events_outlined,
                      size: 26,
                      color: _todayPercent >= 100
                          ? const Color(0xFFD97706)
                          : const Color(0xFF1E242B),
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
  // 2. DAY SELECTOR STRIP (Navigasi Hari & Indikator Titik pada Hari Berjadwal)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildWeekDayStrip() {
    final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris Header Bulan & Tombol Navigasi Minggu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy', 'id_ID').format(_currentMonday),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _changeWeek(-1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF1E242B)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _changeWeek(1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF1E242B)),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final date = _currentMonday.add(Duration(days: index));
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final hasSession = _dateHasSession(date);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDate = date);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 66,
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
                      dayLetters[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : const Color(0xFF1E242B),
                      ),
                    ),
                    // Indikator Titik jika ada sesi live
                    const SizedBox(height: 2),
                    Container(
                      width: 4.5,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: hasSession
                            ? (isSelected ? const Color(0xFFFAE653) : const Color(0xFF018556))
                            : Colors.transparent,
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
  // 3. LIVE SESSION CARD (Data Nyata dari Database)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLiveSessionCard(Map<String, dynamic> session, int index, {bool showFullDate = false}) {
    // 4 Varian Warna Pastel Persis Referensi
    final palettes = [
      {
        'bg': const Color(0xFFD6EBFC), // Sky Blue
        'grid': const Color(0xFFC2E1FA),
        'tagBorder': const Color(0xFFB5DBFA),
        'tagBg': const Color(0xFFCAE5FC),
      },
      {
        'bg': const Color(0xFFFDE1EE), // Blossom Pink
        'grid': const Color(0xFFF9CADE),
        'tagBorder': const Color(0xFFF6C0D9),
        'tagBg': const Color(0xFFFAD4E6),
      },
      {
        'bg': const Color(0xFFE0F6EC), // Mint Green
        'grid': const Color(0xFFC7EFDC),
        'tagBorder': const Color(0xFFB5E8CE),
        'tagBg': const Color(0xFFD0F0DF),
      },
      {
        'bg': const Color(0xFFEDE9FE), // Soft Lavender
        'grid': const Color(0xFFDDD6FE),
        'tagBorder': const Color(0xFFC4B5FD),
        'tagBg': const Color(0xFFE0E7FF),
      },
    ];

    final theme = palettes[index % palettes.length];

    final title = (session['title'] as String?) ?? 'Sesi Live Mentoring';
    final programTitle = (session['programTitle'] as String?) ?? 'Bootcamp Metro';
    final description = (session['description'] as String?) ?? 'Sesi live interaktif bersama mentor.';
    final durationMinutes = (session['durationMinutes'] as num?)?.toInt() ?? 90;
    final liveUrl = (session['liveUrl'] as String?) ?? '';
    final category = (session['category'] as String?) ?? 'Live Session';
    final isCompleted = session['isCompleted'] == true;

    // Format Jam
    String timeRange = '13:00 - 14:30';
    String dateLabel = '';
    final rawScheduled = session['scheduledAt'] as String?;
    if (rawScheduled != null) {
      final scheduledDate = DateTime.tryParse(rawScheduled)?.toLocal();
      if (scheduledDate != null) {
        final startTimeStr = DateFormat('HH:mm').format(scheduledDate);
        final endDate = scheduledDate.add(Duration(minutes: durationMinutes));
        final endTimeStr = DateFormat('HH:mm').format(endDate);
        timeRange = '$startTimeStr - $endTimeStr';
        dateLabel = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(scheduledDate);
      }
    }

    final durationFormatted = durationMinutes >= 60
        ? '${durationMinutes ~/ 60}h ${durationMinutes % 60 > 0 ? '${durationMinutes % 60}m' : ''}'.trim()
        : '$durationMinutes min';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme['bg'],
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
                color: theme['grid']!.withValues(alpha: 0.65),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Time Pill & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                          Icon(
                            isCompleted ? Icons.check_rounded : Icons.access_time_rounded,
                            size: 13,
                            color: isCompleted ? const Color(0xFFFAE653) : Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            timeRange,
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

                    if (showFullDate && dateLabel.isNotEmpty)
                      Text(
                        dateLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Program Title Badge
                Text(
                  programTitle.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF018556),
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 4),

                // Session Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E242B),
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle / Description
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 18),

                // Bottom Tags & Join Button Row
                Row(
                  children: [
                    // Duration Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: theme['tagBg']!.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme['tagBorder']!, width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            durationFormatted,
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

                    const SizedBox(width: 8),

                    // Category Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: theme['tagBg']!.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme['tagBorder']!, width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category,
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

                    const Spacer(),

                    // Tombol Gabung Live
                    if (liveUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openLiveUrl(liveUrl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E242B),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_rounded,
                                size: 15,
                                color: Color(0xFFFAE653),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Masuk',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
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
                : 'Tidak ada sesi live pada tanggal ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)}. Pilih tanggal lain yang bertitik hijau di kalender.',
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

/// CustomPainter untuk Waffle Grid di sisi kanan kartu
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
