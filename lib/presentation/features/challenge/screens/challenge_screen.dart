import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/challenge_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'challenge_arena_screen.dart';

/// ChallengeScreen — Halaman Tantangan Metro Institute
/// Mengadopsi 100% desain referensi visual (Warm Yellow Header, Stepped Tabs, Whimsical Illustrated Cards),
/// dengan KONTEN YANG DIADAPTASIKAN PERSIS untuk konsep TANTANGAN koding & bootcamp:
/// • Background kanvas krem pastel hangat (#FFE7C8)
/// • Header card kuning pastel (#FCDA83) dengan sapaan user & headline "Tantangan apa yang ingin kamu taklukkan?"
/// • Pill search bar ("Cari tantangan, algoritma, topik...") & tombol filter hitam pekat
/// • Stepped tabs "Tantangan" dan "Peringkat" (Leaderboard)
/// • Section "Tantangan Populer" dengan kartu bergambar (UI/UX Sprint, Mobile App Sprint)
/// • Section "Live Code & Workshop" dengan kartu latihan (Algoritma, Slicing UI)
/// • Ringkasan statistik (Total, Selesai, XP Tersedia) & Daftar Latihan lengkap dari API
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
                color: Color(0xFFFFF8EE),
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
          color: isSelected ? const Color(0xFFFAC55D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF5B942) : const Color(0xFFE2E8F0),
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
      backgroundColor: const Color(0xFFFFE7C8), // Warm cream peach canvas from reference design
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
                // ── 1. SIGNATURE WARM YELLOW HEADER CARD (WITH TABS) ──────
                _buildHeaderCard(),

                const SizedBox(height: 24),

                // ── 2. TAB CONTENT ───────────────────────────────────────
                if (_activeTabIndex == 0)
                  _buildTantanganTabContent()
                else
                  _buildPeringkatTabContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. HEADER CARD (Warm Yellow Card with Greeting, Headline, Search & Tabs)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFCDA83), // Warm yellow pastel from reference
        borderRadius: BorderRadius.circular(38),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14F5B942),
            blurRadius: 18,
            offset: Offset(0, 8),
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
                        color: const Color(0xFF1E1E1E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    _buildFourDotsIcon(),
                  ],
                ),

                const SizedBox(height: 22),

                // Big Tantangan Headline Title
                Text(
                  'Tantangan apa yang\ningin kamu taklukkan?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Search Bar + Black Filter Button
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
                              color: Color(0x0A000000),
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
                    height: 56,
                    decoration: BoxDecoration(
                      color: _activeTabIndex == 0 ? const Color(0xFFFAC55D) : Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: const Radius.circular(38),
                        bottomRight: _activeTabIndex == 0 ? const Radius.circular(26) : Radius.zero,
                        topRight: _activeTabIndex == 0 ? Radius.zero : const Radius.circular(22),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Tantangan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _activeTabIndex == 0 ? const Color(0xFF1E1E1E) : const Color(0xFF8E8E93),
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
                    height: 56,
                    decoration: BoxDecoration(
                      color: _activeTabIndex == 1 ? const Color(0xFFFAC55D) : Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomRight: const Radius.circular(38),
                        bottomLeft: _activeTabIndex == 1 ? const Radius.circular(26) : Radius.zero,
                        topLeft: _activeTabIndex == 1 ? Radius.zero : const Radius.circular(22),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Peringkat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _activeTabIndex == 1 ? const Color(0xFF1E1E1E) : const Color(0xFF8E8E93),
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
  // 2. TAB 1: TANTANGAN (Populer + Live Code & Workshop + Daftar Latihan)
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
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

        const SizedBox(height: 24),

        // ── SECTION 1: TANTANGAN POPULER ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Tantangan Populer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1E1E),
                  letterSpacing: -0.4,
                ),
              ),
              _buildTwoDotsIcon(),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal Row of Popular Challenge Cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Card 1: UI/UX Design Sprint
              _buildPopularCard(
                title: 'UI/UX Design Sprint',
                subtitle: '15 Soal  •  +150 XP',
                badgeText: 'UI/UX',
                imageAsset: 'assets/images/challenge_graphic_design.png',
                onTap: () {
                  if (_challenges.isNotEmpty) {
                    _openChallenge(_challenges.first as Map<String, dynamic>);
                  }
                },
              ),

              const SizedBox(width: 16),

              // Card 2: Mobile App Coding Sprint
              _buildPopularCard(
                title: 'Mobile App Sprint',
                subtitle: '12 Soal  •  +200 XP',
                badgeText: 'Mobile',
                imageAsset: 'assets/images/challenge_swimming.png',
                onTap: () {
                  if (_challenges.length > 1) {
                    _openChallenge(_challenges[1] as Map<String, dynamic>);
                  } else if (_challenges.isNotEmpty) {
                    _openChallenge(_challenges.first as Map<String, dynamic>);
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── SECTION 2: LIVE CODE & WORKSHOP ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Live Code & Workshop',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1E1E),
                  letterSpacing: -0.4,
                ),
              ),
              _buildTwoDotsIcon(),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal Row of Workshop Cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Card 1: Algoritma & Struktur Data
              _buildWorkshopCard(
                title: 'Algoritma & Struktur Data',
                instructorName: 'Coach Tommy  •  Menengah',
                instructorAsset: 'assets/images/challenge_instructor_tommy.png',
                thumbnailAsset: 'assets/images/challenge_workshop_1.png',
                onTap: () {
                  if (_challenges.isNotEmpty) {
                    _openChallenge(_challenges.last as Map<String, dynamic>);
                  }
                },
              ),

              const SizedBox(width: 16),

              // Card 2: Slicing UI Figma ke Flutter
              _buildWorkshopCard(
                title: 'Slicing UI ke Flutter',
                instructorName: 'Mentor Daffa  •  Semua Level',
                instructorAsset: 'assets/images/challenge_monica_avatar.png',
                thumbnailAsset: 'assets/images/challenge_workshop_2.png',
                onTap: () {
                  if (_challenges.isNotEmpty) {
                    _openChallenge(_challenges.first as Map<String, dynamic>);
                  }
                },
              ),
            ],
          ),
        ),

        // ── SECTION 3: DAFTAR LATIHAN (Real Challenges from API) ──
        const SizedBox(height: 28),
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
            padding: EdgeInsets.symmetric(vertical: 30),
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

  /// Popular vertical challenge card
  Widget _buildPopularCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 195,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork Thumbnail with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    imageAsset,
                    width: double.infinity,
                    height: 142,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101010).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Card Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1E1E),
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle / XP count
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal Workshop / Live Code card
  Widget _buildWorkshopCard({
    required String title,
    required String instructorName,
    required String instructorAsset,
    required String thumbnailAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Artwork Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                thumbnailAsset,
                width: 74,
                height: 74,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1E1E),
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          instructorAsset,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          instructorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
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
                  : const Color(0xFFFAC55D).withValues(alpha: 0.25),
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
                        color: const Color(0xFFFFF3E0),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.code_off_rounded, size: 26, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 14),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. TAB 2: PERINGKAT (Leaderboard & Podium)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPeringkatTabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Papan Peringkat Mingguan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1E1E),
                  letterSpacing: -0.3,
                ),
              ),
              _buildTwoDotsIcon(),
            ],
          ),

          const SizedBox(height: 16),

          if (_isLoadingLeaderboard)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF101010)),
              ),
            )
          else if (_leaderboard.isEmpty)
            _buildEmptyLeaderboardState()
          else ...[
            // Top Podium
            if (_leaderboard.length >= 3) _buildWarmPodium(),
            const SizedBox(height: 20),

            // Leaderboard List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaderboard.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final user = _leaderboard[idx] as Map<String, dynamic>;
                return _buildLeaderboardRow(idx + 1, user);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarmPodium() {
    final first = _leaderboard[0] as Map<String, dynamic>;
    final second = _leaderboard[1] as Map<String, dynamic>;
    final third = _leaderboard[2] as Map<String, dynamic>;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPodiumStep(rank: 2, user: second, height: 110, color: const Color(0xFFE2E8F0)),
        const SizedBox(width: 14),
        _buildPodiumStep(rank: 1, user: first, height: 140, color: const Color(0xFFFAC55D)),
        const SizedBox(width: 14),
        _buildPodiumStep(rank: 3, user: third, height: 95, color: const Color(0xFFFED7AA)),
      ],
    );
  }

  Widget _buildPodiumStep({
    required int rank,
    required Map<String, dynamic> user,
    required double height,
    required Color color,
  }) {
    final name = user['name']?.toString() ?? 'User';
    final xp = (user['totalXp'] as num?)?.toInt() ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 26 : 22,
          backgroundColor: Colors.white,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: rank == 1 ? 16 : 14,
              color: const Color(0xFF1E1E1E),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 75,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E1E),
            ),
          ),
        ),
        Text(
          '$xp XP',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 75,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(int rank, Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'User';
    final xp = (user['totalXp'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? const Color(0xFFFAC55D) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: rank <= 3 ? const Color(0xFF1E1E1E) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E),
              ),
            ),
          ),
          Text(
            '$xp XP',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeaderboardState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Peringkat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selesaikan tantangan untuk mengumpulkan XP dan memuncaki papan peringkat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
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
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwoDotsIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle)),
      ],
    );
  }
}
