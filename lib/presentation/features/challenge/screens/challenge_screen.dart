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
    final isLocked = challenge['isLocked'] == true;
    if (isLocked) {
      final req = challenge['unlockAtProgress'] ?? 0;
      final classTitle = challenge['linkedClassName'] ?? 'kelas aktifmu';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tantangan ini terbuka setelah menyelesaikan $req% materi di $classTitle.'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final id = challenge['id']?.toString() ?? '';
    final title = challenge['title'] ?? 'Tantangan';
    final xp = (challenge['xpReward'] as num?)?.toInt() ?? 100;
    final timeLimitSec = (challenge['timeLimitSec'] as num?)?.toInt();
    final timeLimit = (challenge['timeLimitMinutes'] as num?)?.toInt() ??
        (timeLimitSec != null && timeLimitSec > 0 ? (timeLimitSec ~/ 60) : 15);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeArenaScreen(
          challengeId: id,
          title: title,
          timeLimitMinutes: timeLimit > 0 ? timeLimit : 15,
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

                // ── 2. TAB CONTENT: TANTANGAN vs PERINGKAT (Smooth Crossfade & Morph) ──
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  firstCurve: Curves.easeInOut,
                  secondCurve: Curves.easeInOut,
                  sizeCurve: Curves.easeInOutCubic,
                  crossFadeState: _activeTabIndex == 0
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: _buildTantanganTabContent(),
                  secondChild: MetroLeaderboardView(
                    entries: _leaderboard,
                    isLoading: _isLoadingLeaderboard,
                    isEmbedded: true,
                    searchQuery: _searchQuery,
                    onRefresh: () => _loadLeaderboard(forceRefresh: true),
                  ),
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
    const cardBgColor = AppColors.accent;       // Kuning Metro (#FAE653)
    const activeTabColor = AppColors.accent;    // Kuning Metro (#FAE653)
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
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_activeTabIndex == 0) return;
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeTabIndex = 0;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
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
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                            color: activeTab == 0 ? textDarkColor : inactiveTextColor,
                          ),
                          child: const Text('Tantangan'),
                        ),
                      ),
                    ),
                  ),

                  // Tab Kanan: Peringkat (My Classes)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_activeTabIndex == 1) return;
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeTabIndex = 1;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        if (_leaderboard.isEmpty) {
                          _loadLeaderboard();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
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
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                            color: activeTab == 1 ? textDarkColor : inactiveTextColor,
                          ),
                          child: const Text('Peringkat'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LAYER 2 (DEPAN): KARTU UTAMA HI MONICA (KUNING BUTTER) ──
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
                  // 1. Top row: Metro Shield/User Avatar + Greeting + 4 Dots Menu
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Row(
                      children: [
                        // Squircle Metro Green Shield Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF08261B), // Deep Emerald Hijau Metro
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _userPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _buildFallbackUserIcon(),
                                  )
                                : _buildFallbackUserIcon(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Greeting: "Hai, [Name]!"
                        Expanded(
                          child: Text(
                            _userName.isNotEmpty ? 'Hai, $_userName!' : 'Hai, Mentee!',
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

                  // 2. Tantangan Headline Title (Smooth crossfade, anchored to left with fixed height to prevent jitter)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        firstCurve: Curves.easeInOut,
                        secondCurve: Curves.easeInOut,
                        crossFadeState: activeTab == 0
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        alignment: Alignment.centerLeft,
                        firstChild: Text(
                          'Tantangan apa yang\ningin kamu taklukkan?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textDarkColor,
                            height: 1.25,
                            letterSpacing: -0.4,
                          ),
                        ),
                        secondChild: Text(
                          'Siapa yang memimpin\nperingkat saat ini?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textDarkColor,
                            height: 1.25,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Search Bar + Right-docked Filter Button (Filter hidden on Peringkat, Search bar width kept constant)
                  Padding(
                    padding: const EdgeInsets.only(left: 22, bottom: 22),
                    child: Row(
                      children: [
                        // White Pill Search Bar (Width remains constant regardless of tab)
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
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      inputDecorationTheme: const InputDecorationTheme(
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
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
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: activeTab == 0 ? 'Cari tantangan...' : 'Cari mentee...',
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF9CA3AF),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
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

                        // Filter Button - Visible only in Tantangan tab, maintaining size so search bar never shifts
                        Visibility(
                          visible: activeTab == 0,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: GestureDetector(
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
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  if (_selectedField != 'ALL' || _selectedLevel != 'ALL')
                                    Positioned(
                                      top: 10,
                                      right: 14,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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

  Widget _buildFallbackUserIcon() {
    return Container(
      color: const Color(0xFF08261B),
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
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
                  child: _buildStatItem('XP Tersedia', '+$totalXpEarnable XP', AppColors.primary),
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
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_filteredChallenges.isEmpty)
          if (_searchQuery.trim().isNotEmpty)
            _buildSearchEmptyCard()
          else
            _buildEmptyChallengesCard()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (int idx = 0; idx < _filteredChallenges.length; idx++) ...[
                  if (idx > 0) const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final item = _filteredChallenges[idx];
                      final Map<String, dynamic> ch = item is Map<String, dynamic>
                          ? item
                          : (item is Map
                              ? item.map((k, v) => MapEntry(k.toString(), v))
                              : <String, dynamic>{});
                      return _buildChallengeListItem(ch);
                    },
                  ),
                ],
              ],
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
    final title = (ch['title'] as String?)?.trim().isNotEmpty == true
        ? ch['title'] as String
        : 'Tantangan Metro Institute';
    final xp = (ch['xpReward'] as num?)?.toInt() ?? 100;
    final level = (ch['level'] as String?)?.trim().isNotEmpty == true
        ? ch['level'] as String
        : 'BEGINNER';
    final isCompleted = ch['isCompleted'] == true;
    final isLocked = ch['isLocked'] == true;
    final unlockAt = (ch['unlockAtProgress'] as num?)?.toInt() ?? 0;
    final timeLimitSec = (ch['timeLimitSec'] as num?)?.toInt();
    final timeLimitMin = (ch['timeLimitMinutes'] as num?)?.toInt() ??
        (timeLimitSec != null && timeLimitSec > 0 ? (timeLimitSec ~/ 60) : 15);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openChallenge(ch),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isCompleted
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0F172A),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : (isLocked ? const Color(0xFFF1F5F9) : const Color(0xFF08261B)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : (isLocked ? Icons.lock_rounded : Icons.code_rounded),
                    color: isCompleted
                        ? Colors.white
                        : (isLocked ? const Color(0xFF94A3B8) : AppColors.accent),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isLocked ? const Color(0xFF64748B) : const Color(0xFF1E1E1E),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLocked ? const Color(0xFFF1F5F9) : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            level,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isLocked ? const Color(0xFF94A3B8) : AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? const Color(0xFFF1F5F9)
                                : AppColors.accent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 12,
                                color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF063D2A),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+$xp XP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF063D2A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (timeLimitMin > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$timeLimitMin mnt',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        if (isLocked && unlockAt > 0)
                          Text(
                            '• Buka di $unlockAt%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _openChallenge(ch),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? const Color(0xFFF1F5F9)
                      : (isLocked ? const Color(0xFFF1F5F9) : const Color(0xFF101010)),
                  foregroundColor: isCompleted
                      ? const Color(0xFF1E1E1E)
                      : (isLocked ? const Color(0xFF94A3B8) : Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(
                  isCompleted ? 'Review' : (isLocked ? 'Terkunci' : 'Mulai'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary, // Solid Hijau Metro tegas (#018556)
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.code_off_rounded, size: 28, color: Colors.white),
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

  Widget _buildSearchEmptyCard() {
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary, // Solid Hijau Metro tegas (#018556)
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off_rounded, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Tantangan Tidak Ditemukan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada tantangan yang cocok dengan kata kunci "$_searchQuery".',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Hapus Pencarian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
