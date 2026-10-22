import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/challenge_remote_datasource.dart';
import '../../learn/widgets/clean_combobox.dart';
import 'challenge_arena_screen.dart';

/// ChallengeScreen — Metro Challenge Bank & Leaderboard.
/// Redesigned with the ultra-clean, modern squircle aesthetic matching Basecamp and Belajar (Learn):
/// • Warm soft ivory canvas (#FAF9F5)
/// • Clean typography with Plus Jakarta Sans & refined spacing
/// • CleanCombobox filters (Halaska UI kit style) for Bidang & Level
/// • Clean hero stats row (Total, Selesai, XP Tersedia)
/// • Sleek challenge cards with clean badges, clear XP pills, and dark navy buttons
/// • Refined podium & leaderboard list with medal accents
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  static void clearCache() => _ChallengeScreenState.clearCache();

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChallengeRemoteDataSource _challengeDs = sl<ChallengeRemoteDataSource>();

  static List<dynamic>? _cachedChallenges;
  static List<dynamic>? _cachedLeaderboard;

  static void clearCache() {
    _cachedChallenges = null;
    _cachedLeaderboard = null;
  }

  late bool _isLoadingChallenges = _cachedChallenges == null;
  late bool _isLoadingLeaderboard = _cachedLeaderboard == null;
  List<dynamic> _challenges = _cachedChallenges ?? [];
  List<dynamic> _leaderboard = _cachedLeaderboard ?? [];

  String _selectedField = 'ALL';
  String _selectedLevel = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChallenges();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    if (_cachedChallenges == null) {
      setState(() => _isLoadingChallenges = true);
    }
    try {
      final list = await _challengeDs.getChallenges(
        field: _selectedField == 'ALL' ? null : _selectedField,
        level: _selectedLevel == 'ALL' ? null : _selectedLevel,
      );
      _cachedChallenges = list;
      if (!mounted) return;
      setState(() {
        _challenges = list;
        _isLoadingChallenges = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingChallenges = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_cachedLeaderboard == null) {
      setState(() => _isLoadingLeaderboard = true);
    }
    try {
      final list = await _challengeDs.getLeaderboard();
      _cachedLeaderboard = list;
      if (!mounted) return;
      setState(() {
        _leaderboard = list;
        _isLoadingLeaderboard = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingLeaderboard = false);
    }
  }

  void _openChallenge(Map<String, dynamic> challenge) {
    HapticFeedback.lightImpact();
    final id = challenge['id']?.toString() ?? '';
    final title = challenge['title'] ?? 'Tantangan';
    final xp = (challenge['xpReward'] as num?)?.toInt() ?? 100;
    final timeLimit = (challenge['timeLimitMinutes'] as num?)?.toInt() ?? 15;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeArenaScreen(
          challengeId: id,
          title: title,
          timeLimitMinutes: timeLimit,
          xpReward: xp,
        ),
      ),
    ).then((_) {
      _loadChallenges();
      _loadLeaderboard();
    });
  }

  List<dynamic> get _filteredChallenges {
    return _challenges.where((ch) {
      // 1. Field filter
      if (_selectedField != 'ALL') {
        final f = (ch['field'] ?? '').toString().toUpperCase();
        if (f != _selectedField) return false;
      }
      // 2. Level filter
      if (_selectedLevel != 'ALL') {
        final l = (ch['level'] ?? '').toString().toUpperCase();
        if (l != _selectedLevel) return false;
      }
      // 3. Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final t = (ch['title'] ?? '').toString().toLowerCase();
        final d = (ch['description'] ?? '').toString().toLowerCase();
        if (!t.contains(q) && !d.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // ── DYNAMIC COMBOBOX OPTIONS ──────────────────────────────────────────────
  List<ComboboxOption> get _fieldOptions {
    final Map<String, String> fieldMap = {
      'ALL': 'Semua Bidang',
      'FRONTEND': 'Frontend',
      'BACKEND': 'Backend',
      'UI_UX': 'UI/UX',
      'MOBILE': 'Mobile',
    };

    // Dynamically add any other field found in items
    for (final it in _challenges) {
      final f = it['field']?.toString().toUpperCase();
      if (f != null && f.isNotEmpty && f != 'NULL' && !fieldMap.containsKey(f)) {
        fieldMap[f] = f.replaceAll('_', ' ');
      }
    }

    return fieldMap.entries
        .map((e) => ComboboxOption(value: e.key, label: e.value))
        .toList();
  }

  List<ComboboxOption> get _levelOptions {
    return const [
      ComboboxOption(value: 'ALL', label: 'Semua Level'),
      ComboboxOption(value: 'BEGINNER', label: 'Pemula (Beginner)'),
      ComboboxOption(value: 'INTERMEDIATE', label: 'Menengah (Intermediate)'),
      ComboboxOption(value: 'ADVANCED', label: 'Lanjutan (Advanced)'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5), // Warm ivory canvas
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Subtitle (matching Basecamp & Belajar)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tantangan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uji kemampuan kode, raih XP & naikkan peringkat.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Clean Segmented Tab Pill (Tantangan vs Peringkat - text only, clean design)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x060F172A),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F0F172A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF64748B),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'Tantangan'),
                            Tab(text: 'Peringkat'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChallengesTab(),
            _buildLeaderboardTab(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. TAB TANTANGAN (CHALLENGE BANK)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildChallengesTab() {
    final filtered = _filteredChallenges;
    final totalChallenges = _challenges.length;
    final completedCount = _challenges.where((c) => c['isCompleted'] == true).length;
    final totalXpEarnable = _challenges
        .where((c) => c['isCompleted'] != true && c['isUnlocked'] != false)
        .fold<int>(0, (sum, c) => sum + ((c['xpReward'] as num?)?.toInt() ?? 0));

    return RefreshIndicator(
      color: const Color(0xFF0F172A),
      onRefresh: () async {
        await _loadChallenges();
        await _loadLeaderboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Clean Unified Summary Card (Zero overflow & uncluttered) ─────
            _buildUnifiedStatsCard(
              total: totalChallenges,
              completed: completedCount,
              xpEarnable: totalXpEarnable,
            ),
            const SizedBox(height: 16),

            // ── Search Bar (Synchronized 1:1 with Basecamp Spotlight Search Pill) ────
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      cursorColor: const Color(0xFF0F172A),
                      cursorWidth: 1.5,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        hintText: 'Cari tantangan, topik, atau materi...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Side-by-Side CleanCombobox (Halaska UI kit style) ────────────
            Row(
              children: [
                Expanded(
                  child: CleanCombobox(
                    value: _selectedField,
                    placeholder: 'Semua Bidang',
                    options: _fieldOptions,
                    onChanged: (val) {
                      setState(() => _selectedField = val);
                      _loadChallenges();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CleanCombobox(
                    value: _selectedLevel,
                    placeholder: 'Semua Level',
                    options: _levelOptions,
                    onChanged: (val) {
                      setState(() => _selectedLevel = val);
                      _loadChallenges();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Section Header ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Latihan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${filtered.length} ditemukan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Challenges List ──────────────────────────────────────────────
            if (_isLoadingChallenges)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                ),
              )
            else if (filtered.isEmpty)
              _buildCleanEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final ch = filtered[idx] as Map<String, dynamic>;
                  return _buildCleanChallengeCard(ch);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── UNIFIED STATS CARD (Zero overflow, clean typography, no symbol clutter) ──
  Widget _buildUnifiedStatsCard({
    required int total,
    required int completed,
    required int xpEarnable,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatColumn(
              label: 'Total',
              value: '$total',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFF1F5F9),
          ),
          Expanded(
            child: _buildStatColumn(
              label: 'Selesai',
              value: '$completed / $total',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFF1F5F9),
          ),
          Expanded(
            child: _buildStatColumn(
              label: 'XP Tersedia',
              value: '+$xpEarnable',
              valueColor: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── CHALLENGE CARD ────────────────────────────────────────────────────────
  Widget _buildCleanChallengeCard(Map<String, dynamic> ch) {
    final title = ch['title'] ?? 'Tantangan Modul';
    final description = ch['description'] ?? ch['shortDescription'] ?? '';
    final field = ch['field']?.toString().replaceAll('_', ' ') ?? 'General';
    final level = ch['level']?.toString() ?? 'BEGINNER';
    final xp = ch['xpReward'] ?? 50;
    final timeLimit = ch['timeLimitMinutes'] ?? 15;
    final attemptsCount = ch['_count']?['attempts'] ?? 0;
    final isUnlocked = ch['isUnlocked'] != false;
    final isCompleted = ch['isCompleted'] == true;

    // Level badges & colors
    Color levelBg = const Color(0xFFF0FDF4);
    Color levelText = const Color(0xFF16A34A);
    String levelLabel = 'Pemula';

    if (level == 'INTERMEDIATE') {
      levelBg = const Color(0xFFFFFBEB);
      levelText = const Color(0xFFD97706);
      levelLabel = 'Menengah';
    } else if (level == 'ADVANCED') {
      levelBg = const Color(0xFFFEF2F2);
      levelText = const Color(0xFFDC2626);
      levelLabel = 'Lanjutan';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: isUnlocked ? () => _openChallenge(ch) : null,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      field.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      levelLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: levelText,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // XP Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                    ),
                    child: Text(
                      '+$xp XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),

              // Description
              if (description.toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Meta Info Row (clean, minimal symbols)
              Row(
                children: [
                  Text(
                    '$timeLimit Menit · $attemptsCount Percobaan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Action Button (matching Belajar & Basecamp button)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: isUnlocked
                    ? ElevatedButton(
                        onPressed: () => _openChallenge(ch),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          isCompleted ? 'Kerjakan Ulang' : 'Kerjakan Sekarang',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Terkunci (Selesaikan Materi Kelas)',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.quiz_outlined, size: 26, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isNotEmpty || _selectedField != 'ALL' || _selectedLevel != 'ALL'
                ? 'Tidak Ada Tantangan Ditemukan'
                : 'Belum Ada Tantangan Aktif',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty || _selectedField != 'ALL' || _selectedLevel != 'ALL'
                ? 'Coba atur ulang kata kunci atau filter bidang/level Anda.'
                : 'Tantangan baru akan terbuka seiring kamu menyelesaikan materi pada kelas aktifmu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedField != 'ALL' || _selectedLevel != 'ALL') ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedField = 'ALL';
                  _selectedLevel = 'ALL';
                });
                _loadChallenges();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                'Reset Filter',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. TAB PERINGKAT (LEADERBOARD)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      color: const Color(0xFF0F172A),
      onRefresh: _loadLeaderboard,
      child: _isLoadingLeaderboard
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F172A)),
            )
          : _leaderboard.isEmpty
              ? _buildCleanLeaderboardEmpty()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top 3 Podium
                      if (_leaderboard.length >= 3) _buildCleanPodium(),
                      const SizedBox(height: 20),

                      Text(
                        'Papan Peringkat Mingguan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rank list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leaderboard.length,
                        itemBuilder: (ctx, idx) {
                          final item = _leaderboard[idx] as Map<String, dynamic>;
                          final name = item['name'] ?? 'Peserta';
                          final xp = item['totalXp'] ?? 0;
                          final badge = item['badgeLevel'] ?? 'ROOKIE';
                          final rank = idx + 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x040F172A),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Rank Badge
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    '#$rank',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: rank == 1
                                          ? const Color(0xFFF59E0B)
                                          : rank == 2
                                              ? const Color(0xFF94A3B8)
                                              : rank == 3
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),

                                // Avatar
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Name & Badge
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        badge.toString().replaceAll('METRO_', ''),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // XP Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                                  ),
                                  child: Text(
                                    '$xp XP',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  // ── PODIUM ────────────────────────────────────────────────────────────────
  Widget _buildCleanPodium() {
    final first = _leaderboard[0] as Map<String, dynamic>;
    final second = _leaderboard[1] as Map<String, dynamic>;
    final third = _leaderboard[2] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumColumn(second, 2, 70, const Color(0xFF94A3B8)),
          _buildPodiumColumn(first, 1, 98, const Color(0xFFF59E0B)),
          _buildPodiumColumn(third, 3, 56, const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(Map<String, dynamic> user, int rank, double pedestalHeight, Color crownColor) {
    final name = user['name'] ?? 'Peserta';
    final xp = user['totalXp'] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 26 : 21,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: rank == 1 ? 18 : 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Positioned(
              top: -12,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: rank == 1 ? 24 : 18,
                color: crownColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 82,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$xp XP',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: pedestalHeight,
          decoration: BoxDecoration(
            color: rank == 1 ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank == 1 ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.spaceMono(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: rank == 1 ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanLeaderboardEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 28, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Text(
              'Papan Peringkat Belum Tersedia',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selesaikan tantangan untuk mengumpulkan XP dan raih posisi teratas di leaderboard minggu ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
