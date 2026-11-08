import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// MetroLeaderboardView — Papan Peringkat Metro Institute.
/// Direproduksi persis dari referensi desain dengan adaptasi warna resmi Metro:
/// • Background atas Kuning Metro (#FAE653) dengan garis-garis organik dinamis
/// • Header Top Bar (Menu, Search, Notifikasi dengan dot pink, Divider, Avatar Logo)
/// • Headline "Leaderboard" tebal & proporsional
/// • Podium Juara 1-2-3 (Center #1 tertinggi, Left #2, Right #3)
/// • Persentase di atas podium (100%, 96%, 88%)
/// • Pin Bintang 5 sudut warna coral pink (#FF5286) dengan nomor peringkat putih
/// • Frame avatar rounded squircle berwarna Kuning Metro (#FAE653)
/// • Bagian bawah berwarna Deep Emerald Dark Metro (#072B1E) menyambung mulus
/// • Daftar peringkat 4+ dengan badge bintang transparan, nama mentee, dan skor/persentase
class MetroLeaderboardView extends StatelessWidget {
  final List<dynamic> entries;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final Widget? tabHeader;
  final VoidCallback? onBack;
  final bool? showTopAppBar;
  final bool isEmbedded;
  final String? searchQuery;

  const MetroLeaderboardView({
    super.key,
    required this.entries,
    this.isLoading = false,
    this.onRefresh,
    this.tabHeader,
    this.onBack,
    this.showTopAppBar,
    this.isEmbedded = false,
    this.searchQuery,
  });

  // Default sample data mirroring the reference design if backend list is empty or minimal
  static final List<Map<String, dynamic>> _sampleEntries = [
    {
      'name': 'Nikitin\nBogdan',
      'displayName': 'Nikitin Bogdan',
      'percentage': '100 %',
      'xp': 2450,
      'isLogo': true,
    },
    {
      'name': 'Alice\nKoller',
      'displayName': 'Alice Koller',
      'percentage': '96 %',
      'xp': 2350,
      'avatarAsset': 'assets/images/challenge_monica_avatar.png',
    },
    {
      'name': 'Peter\nDin',
      'displayName': 'Peter Din',
      'percentage': '88 %',
      'xp': 2150,
      'avatarAsset': 'assets/images/challenge_instructor_tommy.png',
    },
    {
      'displayName': 'John Doe',
      'percentage': '75 %',
      'xp': 1850,
    },
    {
      'displayName': 'Michael Kopfler',
      'percentage': '73 %',
      'xp': 1790,
    },
    {
      'displayName': 'Alice Koller',
      'percentage': '40 %',
      'xp': 980,
    },
    {
      'displayName': 'George Limbof',
      'percentage': '32 %',
      'xp': 780,
    },
    {
      'displayName': 'John Doe',
      'percentage': '20 %',
      'xp': 490,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Process display entries
    final allEntries = _buildAllEntries();
    final isSearching = searchQuery != null && searchQuery!.trim().isNotEmpty;
    final filteredList = isSearching
        ? allEntries.where((e) {
            final name = (e['displayName'] ?? e['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery!.trim().toLowerCase());
          }).toList()
        : allEntries;

    final topThree = isSearching ? <Map<String, dynamic>>[] : allEntries.take(3).toList();
    final remaining = isSearching
        ? filteredList
        : (allEntries.length > 3 ? allEntries.sublist(3) : <Map<String, dynamic>>[]);

    final mainColumn = Column(
      children: [
        // ── TOP SECTION: WARM YELLOW WITH ORGANIC WAVES ──────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Yellow Background with subtle organic wavy curves
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.accent, // Kuning Metro (#FAE653)
              ),
              child: CustomPaint(
                painter: const _OrganicWavePainter(),
                child: SafeArea(
                  top: !isEmbedded,
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. App Bar (Menu, Search, Bell, Profile) - Sembunyikan jika di halaman Tantangan/Embedded
                      if (!isEmbedded && (showTopAppBar ?? (tabHeader == null && onBack != null))) ...[
                        _buildTopAppBar(context),
                      ] else ...[
                        SizedBox(height: isEmbedded ? 22 : 16),
                      ],

                      // Optional Tab Header (e.g. Tantangan vs Peringkat toggle)
                      if (!isEmbedded && tabHeader != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: tabHeader!,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (isSearching) ...[
                        // Search active summary banner
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search_rounded, size: 20, color: Color(0xFF0F172A)),
                              const SizedBox(width: 8),
                              Text(
                                'Ditemukan ${filteredList.length} mentee',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Spacing before podium (Leaderboard title removed as requested)
                        SizedBox(height: isEmbedded ? 14 : 12),

                        // 3. The Podium Section
                        if (topThree.isNotEmpty) ...[
                          _buildPodiumSection(topThree),
                        ] else if (!isLoading) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Text(
                              'Belum ada data peringkat mentee.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── BOTTOM SECTION: DEEP EMERALD METRO CONTAINER (LIST) ────
        Container(
          width: double.infinity,
          color: const Color(0xFF08261B), // Deep Emerald Dark Metro
          padding: EdgeInsets.fromLTRB(20, 10, 20, isEmbedded ? 36 : 120),
          child: Column(
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (isSearching && filteredList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 42,
                        color: AppColors.accent.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mentee Tidak Ditemukan',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tidak ada mentee yang cocok dengan "$searchQuery".',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else if (!isSearching && allEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'Belum ada data mentee pada papan peringkat.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(remaining.length, (index) {
                  final item = remaining[index];
                  final rank = item['rank'] as int? ?? (index + (isSearching ? 1 : 4));
                  return _buildLeaderboardListItem(rank, item);
                }),
            ],
          ),
        ),
      ],
    );

    if (isEmbedded) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: mainColumn,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0F172A),
      backgroundColor: AppColors.accent,
      onRefresh: onRefresh ?? () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: mainColumn,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TOP APP BAR (Menu, Search, Bell with Pink Dot, Divider, Avatar)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Left: Back button or Hamburger menu icon
          GestureDetector(
            onTap: onBack ?? () {},
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.centerLeft,
              child: onBack != null
                  ? const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF0F172A),
                      size: 20,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 22, height: 2.4, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 4.5),
                        Container(width: 15, height: 2.4, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 4.5),
                        Container(width: 19, height: 2.4, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
            ),
          ),

          const Spacer(),

          // Right Icons: Search
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF0F172A),
            size: 24,
          ),

          const SizedBox(width: 16),

          // Bell with Pink Notification Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5286), // Pink notification dot
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Thin Vertical Divider
          Container(
            width: 1,
            height: 18,
            color: const Color(0x33000000),
          ),

          const SizedBox(width: 14),

          // Profile Circle with Metro Shield Logo
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF08261B), // Deep emerald
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(5),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PODIUM SECTION (Stepped Champion Throne / Singgasana Juara)
  // Direproduksi 100% PERSIS sesuai referensi desain (media_1794129564096_b491c022.jpg):
  // • Ketiga pilar saling menempel rapat tanpa celah (gap = 0)
  // • Juara 2 di kiri menyatu langsung dengan tepi kiri kartu (left: 0)
  // • Juara 3 di kanan menyatu langsung dengan tepi kanan kartu (right: 0)
  // • Bentuk pilar geometri berundak bersih (rounded rectangle):
  //   - Pilar tengah (#1) tertinggi (196 px), radius atas 24 px
  //   - Pilar kiri (#2) tinggi kedua (156 px), radius atas 22 px
  //   - Pilar kanan (#3) tinggi ketiga (136 px), radius atas 22 px
  // • Bintang 5 sudut pink (#FF5286) bertengger di puncak lengkungan masing-masing pilar
  // • Teks persentase DIHAPUS TOTAL sesuai permintaan
  // • Frame avatar squircle Kuning Metro (#FAE653) untuk semua mentee di podium
  // • Nama mentee 2 baris teks putih tebal di dalam pilar gelap
  // • Poin XP di bawah nama dengan warna Kuning Metro Gold
  // • Bagian bawah ketiga pilar menyatu langsung dengan kontainer gelap di bawahnya
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPodiumSection(List<Map<String, dynamic>> topThree) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    final first = topThree[0];
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── JUARA #2 (LEFT - MENYATU DENGAN TEPI KIRI KARTU) ──
        Expanded(
          flex: 32,
          child: second != null
              ? _buildPodiumPillar(
                  rank: 2,
                  name: second['name']?.toString() ?? second['displayName']?.toString() ?? 'Mentee',
                  avatarAsset: second['avatarAsset']?.toString(),
                  photoUrl: second['photoUrl']?.toString(),
                  isLogo: second['isLogo'] == true,
                  xp: second['xp'] as int?,
                  pillarHeight: 156,
                  topRadius: 22,
                  avatarSize: 46,
                )
              : const SizedBox.shrink(),
        ),

        // ── JUARA #1 (CENTER - TERTINGGI DI TENGAH) ──
        Expanded(
          flex: 36,
          child: _buildPodiumPillar(
            rank: 1,
            name: first['name']?.toString() ?? first['displayName']?.toString() ?? 'Mentee',
            avatarAsset: first['avatarAsset']?.toString(),
            photoUrl: first['photoUrl']?.toString(),
            isLogo: first['isLogo'] == true,
            xp: first['xp'] as int?,
            pillarHeight: 196,
            topRadius: 24,
            avatarSize: 52,
          ),
        ),

        // ── JUARA #3 (RIGHT - MENYATU DENGAN TEPI KANAN KARTU) ──
        Expanded(
          flex: 32,
          child: third != null
              ? _buildPodiumPillar(
                  rank: 3,
                  name: third['name']?.toString() ?? third['displayName']?.toString() ?? 'Mentee',
                  avatarAsset: third['avatarAsset']?.toString(),
                  photoUrl: third['photoUrl']?.toString(),
                  isLogo: third['isLogo'] == true,
                  xp: third['xp'] as int?,
                  pillarHeight: 136,
                  topRadius: 22,
                  avatarSize: 46,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPodiumPillar({
    required int rank,
    required String name,
    required double pillarHeight,
    required double topRadius,
    required double avatarSize,
    String? avatarAsset,
    String? photoUrl,
    bool isLogo = false,
    int? xp,
  }) {
    const starAboveHeight = 16.0;

    return SizedBox(
      height: pillarHeight + starAboveHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Badan Pilar Gelap (Deep Emerald Dark Metro #08261B)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: pillarHeight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF08261B), // Deep Emerald Dark Metro
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(topRadius),
                  topRight: Radius.circular(topRadius),
                ),
              ),
              padding: const EdgeInsets.only(top: 20, left: 3, right: 3, bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Frame Avatar Squircle Kuning Metro (#FAE653)
                  _buildAvatarBox(
                    isLogo: isLogo,
                    avatarAsset: avatarAsset,
                    photoUrl: photoUrl,
                    fallbackName: name,
                    size: avatarSize,
                  ),

                  const SizedBox(height: 6),

                  // Nama Mentee (2 baris teks putih tebal)
                  Flexible(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: rank == 1 ? 12.0 : 11.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),

                  if (xp != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$xp XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent, // Gold Kuning Metro
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 2. Pin Bintang 5 Sudut Pink (#FF5286) bertengger di puncak pilar
          Positioned(
            top: 0,
            child: _buildStarBadge(rank),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AVATAR BOX (Yellow Squircle with Logo or Illustration)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildAvatarBox({
    required bool isLogo,
    String? avatarAsset,
    String? photoUrl,
    required String fallbackName,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent, // Kuning Metro (#FAE653)
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.5),
      child: Center(
        child: isLogo
            ? Container(
                width: size - 8,
                height: size - 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF08261B),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              )
            : (photoUrl != null && photoUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      width: size - 7,
                      height: size - 7,
                      errorWidget: (_, __, ___) => _buildFallbackInitial(fallbackName, size),
                    ),
                  )
                : (avatarAsset != null && avatarAsset.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          avatarAsset,
                          fit: BoxFit.cover,
                          width: size - 7,
                          height: size - 7,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(fallbackName, size),
                        ),
                      )
                    : _buildFallbackInitial(fallbackName, size),
      ),
    );
  }

  Widget _buildFallbackInitial(String name, [double boxSize = 48]) {
    final clean = name.replaceAll('\n', ' ').trim();
    final letter = clean.isNotEmpty ? clean[0].toUpperCase() : 'M';
    return Text(
      letter,
      style: GoogleFonts.plusJakartaSans(
        fontSize: boxSize * 0.44,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF08261B),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAR BADGE (Pink 5-point star with white number matching reference)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStarBadge(int rank) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CustomPaint(
            size: Size(32, 32),
            painter: _FivePointStarPainter(color: Color(0xFFFF5286)), // Coral Pink as in reference
          ),
          Text(
            '$rank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LIST ITEM FOR RANKS 4 AND BELOW
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLeaderboardListItem(int rank, Map<String, dynamic> item) {
    final name = item['displayName']?.toString() ?? item['name']?.toString().replaceAll('\n', ' ') ?? 'Mentee';
    final xp = item['xp'] as int?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Translucent Star with Rank Number
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(30, 30),
                  painter: _FivePointStarPainter(color: Colors.white.withValues(alpha: 0.16)),
                ),
                Text(
                  '$rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          // User Name
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // XP on the right (without percentage)
          Text(
            '${xp ?? 0} XP',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.accent, // Gold Kuning Metro
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DATA PARSING & FALLBACK MAPPER (Database-backed)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _buildAllEntries() {
    if (entries.isEmpty) {
      return [];
    }

    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < entries.length; i++) {
      final raw = entries[i];
      if (raw is Map<String, dynamic>) {
        final rawName = (raw['name'] ?? raw['displayName'] ?? 'Mentee').toString().trim();
        final nameParts = rawName.split(' ');
        final twoLineName = nameParts.length > 1
            ? '${nameParts[0]}\n${nameParts.sublist(1).join(" ")}'
            : rawName;
        final xp = (raw['totalXp'] as num?)?.toInt() ?? (raw['xp'] as num?)?.toInt() ?? 0;
        final isOrgLogo = raw['isLogo'] == true || rawName.toLowerCase() == 'metro institute';

        result.add({
          'rank': i + 1,
          'name': twoLineName,
          'displayName': rawName,
          'xp': xp,
          'photoUrl': raw['photoUrl'],
          'isLogo': isOrgLogo,
        });
      }
    }

    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-POINT STAR CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _FivePointStarPainter extends CustomPainter {
  final Color color;
  const _FivePointStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.48; // Chunky rounded star proportion
    const step = math.pi / 5;

    for (int i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final angle = i * step - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FivePointStarPainter oldDelegate) => oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// ORGANIC WAVE CURVES PAINTER (Matching the reference design lines)
// ─────────────────────────────────────────────────────────────────────────────
class _OrganicWavePainter extends CustomPainter {
  const _OrganicWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD9901C).withValues(alpha: 0.28) // Warm golden organic curves matching reference
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Line 1: Upper subtle curve
    final path1 = Path()
      ..moveTo(-30, h * 0.18)
      ..cubicTo(w * 0.25, h * 0.10, w * 0.70, h * 0.30, w + 30, h * 0.14);
    canvas.drawPath(path1, paint);

    // Line 2: Mid wave across leaderboard title
    final path2 = Path()
      ..moveTo(-30, h * 0.35)
      ..cubicTo(w * 0.30, h * 0.22, w * 0.65, h * 0.48, w + 30, h * 0.32);
    canvas.drawPath(path2, paint);

    // Line 3: Sweeping curve dipping down to podiums
    final path3 = Path()
      ..moveTo(-40, h * 0.52)
      ..cubicTo(w * 0.20, h * 0.40, w * 0.55, h * 0.72, w + 40, h * 0.45);
    canvas.drawPath(path3, paint);

    // Line 4: Flowing bottom contour
    final path4 = Path()
      ..moveTo(-30, h * 0.70)
      ..cubicTo(w * 0.35, h * 0.82, w * 0.75, h * 0.58, w + 30, h * 0.72);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

