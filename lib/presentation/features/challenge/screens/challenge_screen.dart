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

  Future<void> _loadLeaderboard({bool forceRefresh = false}) async {
    if (_cachedLeaderboard == null || forceRefresh) {
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
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih bersih
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF101010),
          onRefresh: () async {
            await _loadChallenges();
            await _loadLeaderboard(forceRefresh: true);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. SIGNATURE KUNING METRO HEADER CARD (WITH TABS) ─────
                _buildHeaderCard(),

                const SizedBox(height: 16),

                // ── 2. TAB CONTENT: TANTANGAN vs PERINGKAT ───────────────
                if (_activeTabIndex == 0)
                  _buildTantanganTabContent()
                else
                  MetroLeaderboardView(
                    entries: _leaderboard,
                    isLoading: _isLoadingLeaderboard,
                    isEmbedded: true,
                    searchQuery: _searchQuery,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. HEADER CARD (Warm Butter Yellow Card with Curved Tab Tops)
  // Direproduksi 100% persis sesuai desain referensi (media_1794116744526_1547e0d0.jpg)
  // • Bagian bawah Card Hi Monica melengkung ke atas di kedua sudut (Radius 28)
  // • Sudut kiri atas tab Tantangan (Lesson) melengkung naik mengisi sudut kiri
  // • Sudut kanan atas tab Peringkat (My Classes) melengkung naik mengisi sudut kanan
  // • Garis lurus mulus tanpa celah atau bayangan bertumpuk
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    final activeTab = _activeTabIndex; // 0 = Tantangan, 1 = Peringkat
    const cardBgColor = Color(0xFFFED968);       // Warm butter pastel yellow
    const activeTabColor = Color(0xFFF6C54E);    // Rich golden amber yellow
    const inactiveTabColor = Colors.white;       // Pure white tab background
    const textDarkColor = Color(0xFF111827);     // Deep dark/charcoal text
    const inactiveTextColor = Color(0xFF8E8E93);  // Muted gray for inactive tab

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Memastikan kedua layer terpotong rapi dalam 1 kontur kartu
      child: Stack(
        children: [
          // ── LAYER 1 (BELAKANG): DUA TAB (TANTANGAN & PERINGKAT) ──
          // Memanjang dari bawah naik ke balik card atas setinggi 82px (54px terekspos + 28px masuk ke balik card)
          // Memiliki base putih solid di baliknya sehingga lengkungan sudut tengah terisi warna putih mulus (persis media_1794117742534_66f5b141.png)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 82,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white, // Solid pure white base under the entire tab bar
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  // Tab Kiri: Tantangan (Lessons)
                  // Mengisi sudut kiri atas, dengan sudut kanan bawah melengkung bulat di atas base putih
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeTabIndex = 0;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: Container(
                        height: 82,
                        decoration: BoxDecoration(
                          color: activeTab == 0 ? activeTabColor : Colors.white,
                          borderRadius: activeTab == 0
                              ? const BorderRadius.only(
                                  bottomLeft: Radius.circular(28),
                                  bottomRight: Radius.circular(28),
                                )
                              : BorderRadius.zero,
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          'Tantangan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                            color: activeTab == 0 ? textDarkColor : inactiveTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tab Kanan: Peringkat (My Classes)
                  // Mengisi sudut kanan atas, dengan sudut kiri bawah melengkung bulat di atas base putih saat aktif
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeTabIndex = 1;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _loadLeaderboard(forceRefresh: true);
                      },
                      child: Container(
                        height: 82,
                        decoration: BoxDecoration(
                          color: activeTab == 1 ? activeTabColor : Colors.white,
                          borderRadius: activeTab == 1
                              ? const BorderRadius.only(
                                  bottomRight: Radius.circular(28),
                                  bottomLeft: Radius.circular(28),
                                )
                              : BorderRadius.zero,
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          'Peringkat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                            color: activeTab == 1 ? textDarkColor : inactiveTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LAYER 2 (DEPAN): KARTU UTAMA HI MONICA (KUNING BUTTER) ──
          // Diberi padding bottom 54px sehingga 54px tab terekspos di bawah.
          // Kedua sudut bawahnya melengkung naik (Radius 28), sehingga sudut kiri atas dan kanan atas tab tampak menyembul mulus!
          Padding(
            padding: const EdgeInsets.only(bottom: 54),
            child: Container(
              decoration: const BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top row: Monica Avatar + Greeting + 4 Dots Menu
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Row(
                      children: [
                        // Squircle Monica Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDB5CB), // Soft candy blossom pink
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13.5),
                            child: Image.asset(
                              'assets/images/challenge_monica_avatar.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Greeting: "Hai, [Name]!"
                        Expanded(
                          child: Text(
                            _userName.isNotEmpty ? 'Hai, $_userName!' : 'Hai, Monica!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 4 Dots Menu (2x2 grid)
                        _buildFourDotsIcon(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Tantangan Headline Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      activeTab == 0
                          ? 'Tantangan apa yang\ningin kamu taklukkan?'
                          : 'Siapa yang memimpin\nperingkat saat ini?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textDarkColor,
                        height: 1.25,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Search Bar + Right-docked Black Capsule Filter Button
                  Padding(
                    padding: const EdgeInsets.only(left: 22, bottom: 22),
                    child: Row(
                      children: [
                        // White Pill Search Bar
                        Expanded(
                          child: Container(
                            height: 52,
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
                                  color: Color(0xFF9CA3AF),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    cursorColor: textDarkColor,
                                    cursorWidth: 1.5,
                                    onChanged: (val) {
                                      setState(() => _searchQuery = val);
                                    },
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textDarkColor,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: activeTab == 0 ? 'Cari tantangan...' : 'Cari mentee...',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF9CA3AF),
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

                        const SizedBox(width: 12),

                        // Black Filter Button Docked to Right Edge of Card
                        GestureDetector(
                          onTap: _openFilterBottomSheet,
                          child: Container(
                            width: 66,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFF111827),
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(26),
                                right: Radius.circular(0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x28000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 22,
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
