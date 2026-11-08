import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/challenge_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../leaderboard/widgets/metro_leaderboard_view.dart';
import 'challenge_arena_screen.dart';

/// ChallengeScreen — Halaman Tantangan Metro Institute
/// Mengadopsi struktur & layout referensi visual dengan estetika khas Metro:
/// • Background kanvas putih bersih (Colors.white)
/// • Header card Kuning Metro (#FAE653) dengan sapaan user & headline "Tantangan apa yang ingin kamu taklukkan?"
/// • Pill search bar ("Cari tantangan, topik...") & tombol filter hitam pekat
/// • Stepped tabs "Tantangan" dan "Peringkat" (Leaderboard)
/// • Ringkasan statistik (Total Tantangan, Selesai, XP Tersedia)
/// • Daftar Latihan langsung terhubung ke API backend (menampilkan Empty State jika belum ada tantangan aktif)
/// • Tab Peringkat dengan Podium Juara 1-2-3 dan daftar ranking mingguan
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  static void clearCache() => _ChallengeScreenState.clearCache();

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
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

  int _activeTabIndex = 0; // 0 = Tantangan, 1 = Peringkat
  String _selectedField = 'ALL';
  String _selectedLevel = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _userName = 'Daffarael';
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadChallenges();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final authRepo = sl<AuthRepository>();
      final user = await authRepo.getSavedUser();
      if (user != null && mounted) {
        setState(() {
          if (user.name.trim().isNotEmpty) {
            _userName = user.name.trim().split(' ').first;
          }
          _userPhotoUrl = user.photoUrl;
        });
      }
    } catch (_) {}
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
      if (_selectedField != 'ALL') {
        final f = (ch['field'] ?? '').toString().toUpperCase();
        if (f != _selectedField) return false;
      }
      if (_selectedLevel != 'ALL') {
        final l = (ch['level'] ?? '').toString().toUpperCase();
        if (l != _selectedLevel) return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final t = (ch['title'] ?? '').toString().toLowerCase();
        final d = (ch['description'] ?? '').toString().toLowerCase();
        if (!t.contains(q) && !d.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void _openFilterBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String tempField = _selectedField;
        String tempLevel = _selectedLevel;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Filter Tantangan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bidang Keahlian',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Semua Bidang', 'ALL', tempField, (val) => setModalState(() => tempField = val)),
                      _buildFilterChip('Frontend', 'FRONTEND', tempField, (val) => setModalState(() => tempField = val)),
                      _buildFilterChip('Backend', 'BACKEND', tempField, (val) => setModalState(() => tempField = val)),
                      _buildFilterChip('UI/UX', 'UI_UX', tempField, (val) => setModalState(() => tempField = val)),
                      _buildFilterChip('Mobile', 'MOBILE', tempField, (val) => setModalState(() => tempField = val)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Tingkat Kesulitan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Semua Level', 'ALL', tempLevel, (val) => setModalState(() => tempLevel = val)),
                      _buildFilterChip('Pemula', 'BEGINNER', tempLevel, (val) => setModalState(() => tempLevel = val)),
                      _buildFilterChip('Menengah', 'INTERMEDIATE', tempLevel, (val) => setModalState(() => tempLevel = val)),
                      _buildFilterChip('Lanjutan', 'ADVANCED', tempLevel, (val) => setModalState(() => tempLevel = val)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedField = 'ALL';
                              _selectedLevel = 'ALL';
                            });
                            Navigator.pop(ctx);
                            _loadChallenges();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E1E1E),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Reset',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedField = tempField;
                              _selectedLevel = tempLevel;
                            });
                            Navigator.pop(ctx);
                            _loadChallenges();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF101010),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Terapkan',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue, Function(String) onSelect) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentDark : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── TAB 2: PERINGKAT (Leaderboard View — Direproduksi Persis Sesuai Desain) ──
    if (_activeTabIndex == 1) {
      return Scaffold(
        backgroundColor: const Color(0xFF08261B), // Deep Emerald Dark Metro
        body: MetroLeaderboardView(
          entries: _leaderboard,
          isLoading: _isLoadingLeaderboard,
          onRefresh: () async {
            await _loadLeaderboard();
          },
          tabHeader: _buildPeringkatTabHeader(),
        ),
      );
    }

    // ── TAB 1: TANTANGAN (Lessons View) ──
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih bersih
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF101010),
          onRefresh: () async {
            await _loadChallenges();
            await _loadLeaderboard();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. SIGNATURE KUNING METRO HEADER CARD (WITH TABS) ─────
                _buildHeaderCard(),

                const SizedBox(height: 20),

                // ── 2. TAB CONTENT: TANTANGAN ────────────────────────────
                _buildTantanganTabContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tab Pill Header saat tab Peringkat aktif (memungkinkan toggle kembali ke Tantangan)
  Widget _buildPeringkatTabHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Row(
        children: [
          // Tantangan Tab (Inactive)
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeTabIndex = 0);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Tantangan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1117).withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ),

          // Peringkat Tab (Active)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117), // Deep dark / black
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Peringkat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. HEADER CARD (Kuning Metro Card with Greeting, Headline, Search & Tabs)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.accent, // Kuning Metro (#FAE653)
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: User Avatar + Greeting + 4 Dots Menu
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _userPhotoUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Image.asset(
                                  'assets/images/challenge_monica_avatar.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/challenge_monica_avatar.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hai, $_userName!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D1117),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    _buildFourDotsIcon(),
                  ],
                ),

                const SizedBox(height: 20),

                // Big Tantangan Headline Title
                Text(
                  'Tantangan apa yang\ningin kamu taklukkan?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1117),
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 18),

                // Search Bar + Pure Black Squircle Filter Button
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
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
                                cursorColor: const Color(0xFF101010),
                                cursorWidth: 1.5,
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1E1E),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Cari tantangan, topik...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
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
                    ),

                    const SizedBox(width: 10),

                    // Pure Black Squircle Filter Button
                    GestureDetector(
                      onTap: _openFilterBottomSheet,
                      child: Container(
                        width: 52,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101010),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x24101010),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── STEPPED TABS (Tantangan vs Peringkat) ──
          Row(
            children: [
              // Tab 1: Tantangan
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeTabIndex = 0);
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: _activeTabIndex == 0 ? AppColors.accentDark : Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: const Radius.circular(36),
                        bottomRight: _activeTabIndex == 0 ? const Radius.circular(24) : Radius.zero,
                        topRight: _activeTabIndex == 0 ? Radius.zero : const Radius.circular(22),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Tantangan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _activeTabIndex == 0 ? const Color(0xFF0D1117) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ),

              // Tab 2: Peringkat
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeTabIndex = 1);
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: _activeTabIndex == 1 ? AppColors.accentDark : Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomRight: const Radius.circular(36),
                        bottomLeft: _activeTabIndex == 1 ? const Radius.circular(24) : Radius.zero,
                        topLeft: _activeTabIndex == 1 ? Radius.zero : const Radius.circular(22),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Peringkat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _activeTabIndex == 1 ? const Color(0xFF0D1117) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. TAB 1: TANTANGAN (Stats + Daftar Latihan)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTantanganTabContent() {
    final totalChallenges = _challenges.length;
    final completedCount = _challenges.where((c) => c['isCompleted'] == true).length;
    final totalXpEarnable = _challenges
        .where((c) => c['isCompleted'] != true && c['isUnlocked'] != false)
        .fold<int>(0, (sum, c) => sum + ((c['xpReward'] as num?)?.toInt() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── STATS ROW (Ringkasan Kemajuan Mentee) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Tantangan', '$totalChallenges', const Color(0xFF1E1E1E)),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _buildStatItem('Selesai', '$completedCount / $totalChallenges', const Color(0xFF1E1E1E)),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _buildStatItem('XP Tersedia', '+$totalXpEarnable XP', const Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        // ── SECTION: DAFTAR LATIHAN ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Latihan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1E1E),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${_filteredChallenges.length} tantangan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_isLoadingChallenges)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF101010)),
            ),
          )
        else if (_filteredChallenges.isEmpty)
          _buildEmptyChallengesCard()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredChallenges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final ch = _filteredChallenges[idx] as Map<String, dynamic>;
                return _buildChallengeListItem(ch);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Challenge list item from database
  Widget _buildChallengeListItem(Map<String, dynamic> ch) {
    final title = ch['title']?.toString() ?? 'Tantangan';
    final xp = (ch['xpReward'] as num?)?.toInt() ?? 100;
    final level = ch['level']?.toString() ?? 'BEGINNER';
    final isCompleted = ch['isCompleted'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : AppColors.accent.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.code_rounded,
              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        level,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+$xp XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openChallenge(ch),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF101010),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(
              isCompleted ? 'Review' : 'Mulai',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChallengesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.2),
              ),
              child: const Icon(Icons.code_off_rounded, size: 28, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Tantangan Aktif',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tantangan baru akan terbuka seiring kamu menyelesaikan materi pada kelas aktifmu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. HELPER ICONS (4 Dots & 2 Dots)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildFourDotsIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF0D1117), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF0D1117), shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF0D1117), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF0D1117), shape: BoxShape.circle)),
            ],
          ),
        ],
      ),
    );
  }
}
