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
    final displayList = _buildDisplayList();
    final topThree = displayList.take(3).toList();
    final remaining = displayList.length > 3 ? displayList.sublist(3) : <Map<String, dynamic>>[];

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

                      // 2. Title: "Leaderboard"
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isEmbedded ? 25 : 27,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A), // Dark charcoal
                          letterSpacing: -0.6,
                        ),
                      ),

                      const SizedBox(height: 20),

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
              else if (displayList.isEmpty)
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
                  final rank = index + 4;
                  final item = remaining[index];
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
  // PODIUM SECTION (3 Pedestals with percentages, stars, avatars, and names)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPodiumSection(List<Map<String, dynamic>> topThree) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    final first = topThree[0];
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final spacing = (maxW * 0.02).clamp(4.0, 8.0);
        final available = maxW - (spacing * 2) - 16;
        final sideWidth = (available * 0.315).clamp(84.0, 104.0);
        final centerWidth = (available * 0.37).clamp(94.0, 114.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── PODIUM #2 (LEFT) ──
            if (second != null)
              _buildPodiumPillar(
                rank: 2,
                percentage: second['percentage']?.toString() ?? '0 %',
                name: second['name']?.toString() ?? second['displayName']?.toString() ?? 'Mentee',
                avatarAsset: second['avatarAsset']?.toString(),
                photoUrl: second['photoUrl']?.toString(),
                isLogo: second['isLogo'] == true,
                xp: second['xp'] as int?,
                pillarHeight: 148,
                pillarWidth: sideWidth,
                topRadius: 26,
              )
            else
              SizedBox(width: sideWidth),

            SizedBox(width: spacing),

            // ── PODIUM #1 (CENTER - TALLEST) ──
            _buildPodiumPillar(
              rank: 1,
              percentage: first['percentage']?.toString() ?? '100 %',
              name: first['name']?.toString() ?? first['displayName']?.toString() ?? 'Mentee',
              avatarAsset: first['avatarAsset']?.toString(),
              photoUrl: first['photoUrl']?.toString(),
              isLogo: first['isLogo'] == true,
              xp: first['xp'] as int?,
              pillarHeight: 184,
              pillarWidth: centerWidth,
              topRadius: 30,
            ),

            SizedBox(width: spacing),

            // ── PODIUM #3 (RIGHT) ──
            if (third != null)
              _buildPodiumPillar(
                rank: 3,
                percentage: third['percentage']?.toString() ?? '0 %',
                name: third['name']?.toString() ?? third['displayName']?.toString() ?? 'Mentee',
                avatarAsset: third['avatarAsset']?.toString(),
                photoUrl: third['photoUrl']?.toString(),
                isLogo: third['isLogo'] == true,
                xp: third['xp'] as int?,
                pillarHeight: 128,
                pillarWidth: sideWidth,
                topRadius: 26,
              )
            else
              SizedBox(width: sideWidth),
          ],
        );
      },
    );
  }

  Widget _buildPodiumPillar({
    required int rank,
    required String percentage,
    required String name,
    required double pillarHeight,
    required double pillarWidth,
    required double topRadius,
    String? avatarAsset,
    String? photoUrl,
    bool isLogo = false,
    int? xp,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Percentage above pedestal on yellow background
        Text(
          percentage,
          style: GoogleFonts.plusJakartaSans(
            fontSize: rank == 1 ? 16.5 : 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 6),

        // Pedestal Stack with overlapping star badge
        SizedBox(
          width: pillarWidth,
          height: pillarHeight + 16,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // The Dark Emerald Pedestal Container
              Container(
                width: pillarWidth,
                height: pillarHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF08261B), // Deep Emerald Dark Metro
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(topRadius),
                    topRight: Radius.circular(topRadius),
                  ),
                ),
                padding: const EdgeInsets.only(top: 24, left: 6, right: 6),
                child: Column(
                  children: [
                    // Avatar Squircle Box in Kuning Metro
                    _buildAvatarBox(
                      isLogo: isLogo,
                      avatarAsset: avatarAsset,
                      photoUrl: photoUrl,
                      fallbackName: name,
                    ),

                    const SizedBox(height: 8),

                    // User Name in 2 lines (White Text, bold, centered)
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
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

              // Pink Star Badge with Rank Number straddling the top edge
              Positioned(
                top: 0,
                child: _buildStarBadge(rank),
              ),
            ],
          ),
        ),
      ],
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
  }) {
    return Container(
      width: 52,
      height: 52,
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
      child: Center(
        child: isLogo
            ? Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF08261B),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              )
            : (photoUrl != null && photoUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      errorWidget: (_, __, ___) => _buildFallbackInitial(fallbackName),
                    ),
                  )
                : (avatarAsset != null && avatarAsset.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          avatarAsset,
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(fallbackName),
                        ),
                      )
                    : _buildFallbackInitial(fallbackName),
      ),
    );
  }

  Widget _buildFallbackInitial(String name) {
    final clean = name.replaceAll('\n', ' ').trim();
    final letter = clean.isNotEmpty ? clean[0].toUpperCase() : 'M';
    return Text(
      letter,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF08261B),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STAR BADGE (Pink 5-point star with white number)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStarBadge(int rank) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(32, 32),
            painter: const _FivePointStarPainter(color: Color(0xFFFF5286)), // Coral Pink
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
    final percentage = item['percentage']?.toString() ?? '0 %';
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

          // Percentage & XP on the right
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                percentage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              if (xp != null)
                Text(
                  '$xp XP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent, // Gold Kuning Metro
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DATA PARSING & FALLBACK MAPPER (Database-backed)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _buildDisplayList() {
    if (entries.isEmpty) {
      return [];
    }

    // Determine max XP for relative percentage calculations
    int maxXp = 0;
    for (final e in entries) {
      if (e is Map<String, dynamic>) {
        final xp = (e['totalXp'] as num?)?.toInt() ?? (e['xp'] as num?)?.toInt() ?? 0;
        if (xp > maxXp) maxXp = xp;
      }
    }
    if (maxXp == 0) maxXp = 100;

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
        final pct = maxXp > 0 ? ((xp / maxXp) * 100).round() : 0;
        final isOrgLogo = raw['isLogo'] == true || rawName.toLowerCase() == 'metro institute';

        result.add({
          'name': twoLineName,
          'displayName': rawName,
          'percentage': '$pct %',
          'xp': xp,
          'photoUrl': raw['photoUrl'],
          'isLogo': isOrgLogo,
        });
      }
    }

    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final q = searchQuery!.trim().toLowerCase();
      final filtered = result.where((e) {
        final name = (e['displayName'] ?? e['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
      return filtered;
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
      ..color = const Color(0xFFD97706).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Line 1: Upper subtle curve
    final path1 = Path()
      ..moveTo(-30, h * 0.20)
      ..cubicTo(w * 0.25, h * 0.12, w * 0.70, h * 0.35, w + 30, h * 0.16);
    canvas.drawPath(path1, paint);

    // Line 2: Mid wave across leaderboard title
    final path2 = Path()
      ..moveTo(-30, h * 0.38)
      ..cubicTo(w * 0.30, h * 0.24, w * 0.65, h * 0.52, w + 30, h * 0.36);
    canvas.drawPath(path2, paint);

    // Line 3: Sweeping curve dipping down to podiums
    final path3 = Path()
      ..moveTo(-40, h * 0.55)
      ..cubicTo(w * 0.20, h * 0.44, w * 0.55, h * 0.78, w + 40, h * 0.48);
    canvas.drawPath(path3, paint);

    // Line 4: Flowing bottom contour
    final path4 = Path()
      ..moveTo(-30, h * 0.75)
      ..cubicTo(w * 0.35, h * 0.88, w * 0.75, h * 0.62, w + 30, h * 0.78);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

