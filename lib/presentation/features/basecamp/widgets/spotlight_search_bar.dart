import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import '../../learn/screens/course_detail_screen.dart';

/// Item data model for Apple Spotlight destinations with rich semantic keywords
class SpotlightItem {
  final String label;
  final String description;
  final IconData icon;
  final String? route;
  final String category;
  final List<String> keywords;
  final Map<String, dynamic>? courseData;

  const SpotlightItem({
    required this.label,
    required this.description,
    required this.icon,
    String? route,
    String? linkRoute,
    this.category = 'Halaman',
    this.keywords = const [],
    this.courseData,
  }) : route = route ?? linkRoute;
}

/// SpotlightSearchBar
///
/// Clean, elegant search pill placed at the very top of Basecamp,
/// mirroring the web mentee Topbar AppleSpotlight input:
/// • Capsule pill with 🔍 and "Basecamp" placeholder
/// • Clean minimalist design without extraneous buttons
/// • Tapping opens the interactive Apple Spotlight Search Modal
class SpotlightSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const SpotlightSearchBar({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: Text(
                'Cari halaman, topik, materi...',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the full interactive Apple Spotlight Search screen
/// Pushed with root navigator and smooth fade transition so header is pinned and keyboard doesn't push it up
void showSpotlightSearchModal(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const _SpotlightSearchSheet(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 180),
    ),
  );
}

class _SpotlightSearchSheet extends StatefulWidget {
  const _SpotlightSearchSheet();

  @override
  State<_SpotlightSearchSheet> createState() => _SpotlightSearchSheetState();
}

class _SpotlightSearchSheetState extends State<_SpotlightSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  List<dynamic> _cachedCourses = [];
  bool _isLoadingCourses = false;

  // Stopwords (conversational prefixes & filler words in Indonesian & English)
  static const Set<String> _stopwords = {
    'mau', 'ingin', 'tolong', 'dong', 'bisa', 'bagaimana', 'gimana',
    'cara', 'lihat', 'buka', 'cek', 'ke', 'di', 'dari', 'yang', 'dan',
    'atau', 'untuk', 'dengan', 'saya', 'aku', 'halaman', 'menu',
    'fitur', 'daftar', 'kumpulan', 'info', 'ada', 'apa', 'pada',
    'the', 'how', 'to', 'for', 'my', 'and', 'or', 'in', 'on', 'at'
  };

  // ── Maximized Synonyms & Intent Mapping for All App Destinations ──────────
  static const List<SpotlightItem> _allPages = [
    SpotlightItem(
      label: 'Basecamp',
      description: 'Kembali ke halaman utama dashboard',
      route: AppRoutes.basecamp,
      icon: Icons.home_rounded,
      category: 'Utama',
      keywords: [
        'basecamp', 'home', 'beranda', 'utama', 'dashboard', 'depan', 'awal',
        'mulai', 'main menu', 'halaman awal', 'kembali ke awal', 'kembali ke depan',
        'menu utama', 'beranda utama', 'dasbor'
      ],
    ),
    SpotlightItem(
      label: 'Mini Course',
      description: 'Jelajahi berbagai kelas mini & materi praktis',
      route: AppRoutes.learn,
      icon: Icons.explore_outlined,
      category: 'Belajar',
      keywords: [
        'mini course', 'minicourse', 'kelas', 'materi', 'kursus', 'video',
        'tutorial', 'belajar', 'modul', 'pelajaran', 'singkat', 'course',
        'self paced', 'rekaman', 'video tutorial', 'materi belajar', 'figma',
        'ui ux', 'desain', 'web development', 'frontend', 'backend',
        'mobile app', 'flutter', 'react', 'javascript', 'python',
        'coding pemula', 'belajar koding', 'kursus online', 'kelas online',
        'course praktis', 'panduan'
      ],
    ),
    SpotlightItem(
      label: 'Bootcamp',
      description: 'Daftar program intensif siap kerja & mentoring',
      route: AppRoutes.learn,
      icon: Icons.terrain_rounded,
      category: 'Belajar',
      keywords: [
        'bootcamp', 'program intensif', 'batch', 'fti', 'mentoring',
        'siap kerja', 'karir', 'kelas intensif', 'live mentoring', 'intensif',
        'fullstack', 'job guarantee', 'jaminan kerja', 'lulus langsung kerja',
        'magang', 'portofolio', 'project akhir', 'live class', 'tanya mentor',
        'bukem', 'camp', 'fast track', 'pelatihan', 'program pelatihan',
        'pembinaan karir'
      ],
    ),
    SpotlightItem(
      label: 'Webinar',
      description: 'Jelajahi jadwal webinar live & workshop interaktif',
      route: AppRoutes.webinar,
      icon: Icons.videocam_outlined,
      category: 'Belajar',
      keywords: [
        'webinar', 'live', 'zoom', 'siaran', 'workshop', 'seminar', 'jadwal',
        'acara', 'talkshow', 'siaran langsung', 'gmeet', 'streaming',
        'sesi live', 'kuliah tamu', 'kuliah umum', 'narasumber', 'speaker',
        'event', 'jadwal live', 'webminar', 'live session', 'webinar gratis',
        'live streaming', 'jadwal zoom'
      ],
    ),
    SpotlightItem(
      label: 'Kelas Saya',
      description: 'Kursus dan bootcamp yang sedang Anda ikuti',
      route: AppRoutes.myCourses,
      icon: Icons.school_outlined,
      category: 'Belajar',
      keywords: [
        'kelas saya', 'kursus saya', 'sedang belajar', 'progress', 'progres',
        'materi saya', 'daftar kelas', 'my course', 'my class', 'enrolled',
        'les', 'kelas aktif', 'kelas yang diikuti', 'pembelajaran saya',
        'lanjutkan belajar', 'resume belajar', 'riwayat kelas',
        'kursus yang diambil', 'kelas saya sekarang', 'ongoing course',
        'materi tersimpan'
      ],
    ),
    SpotlightItem(
      label: 'Challenge Bank',
      description: 'Kumpulan tantangan koding & studi kasus',
      route: AppRoutes.challenge,
      icon: Icons.bolt_rounded,
      category: 'Tantangan',
      keywords: [
        'challenge bank', 'challenge', 'tantangan', 'coding', 'koding',
        'ngoding', 'tugas', 'soal', 'latihan', 'quiz', 'kuis', 'proyek',
        'studi kasus', 'case study', 'pr', 'pekerjaan rumah', 'test',
        'tes koding', 'ujian', 'problem solving', 'algoritma', 'submission',
        'submit tugas', 'bank soal', 'latihan soal', 'kumpulan tugas',
        'tantangan mingguan', 'leetcode'
      ],
    ),
    SpotlightItem(
      label: 'Papan Peringkat',
      description: 'Lihat peringkat siswa terbaik & mentee teratas',
      route: AppRoutes.leaderboard,
      icon: Icons.emoji_events_outlined,
      category: 'Tantangan',
      keywords: [
        'papan peringkat', 'peringkat', 'leaderboard', 'ranking', 'rangking',
        'skor', 'juara', 'top', 'mentee terbaik', 'klasemen', 'prestasi',
        'rekor', 'urutan', 'kompetisi', 'nomor 1', 'leader board',
        'top mentee', 'skor tertinggi', 'juara kelas', 'klasemen sementara',
        'tangga juara'
      ],
    ),
    SpotlightItem(
      label: 'Aktivitas XP',
      description: 'Riwayat pendapatan XP, streak, dan level',
      route: AppRoutes.xpActivity,
      icon: Icons.star_outline_rounded,
      category: 'Pencapaian',
      keywords: [
        'aktivitas xp', 'xp', 'exp', 'poin', 'point', 'level', 'streak',
        'strik', 'api', 'flame', 'api streak', 'skor', 'pencapaian',
        'badge', 'rookie', 'explorer', 'gamifikasi', 'misi harian',
        'daily mission', 'quest', 'kehadiran', 'absen', 'hadiah',
        'klaim xp', 'tambah level', 'naik level', 'xp saya'
      ],
    ),
    SpotlightItem(
      label: 'Sertifikat Saya',
      description: 'Koleksi sertifikat kelulusan & verifikasi',
      route: AppRoutes.certificate,
      icon: Icons.workspace_premium_outlined,
      category: 'Pencapaian',
      keywords: [
        'sertifikat saya', 'sertifikat', 'certificate', 'ijazah', 'kelulusan',
        'piagam', 'verifikasi', 'unduh sertifikat', 'download sertifikat',
        'lulus', 'bukti kelulusan', 'tanda tamat', 'sertif', 'certif',
        'sertifikat kelulusan', 'cetak sertifikat', 'lisensi',
        'kelulusan kursus', 'sertifikasi'
      ],
    ),
    SpotlightItem(
      label: 'Riwayat Transaksi',
      description: 'Catatan pembelian kursus & status invoice',
      route: AppRoutes.transactions,
      icon: Icons.receipt_long_outlined,
      category: 'Pencapaian',
      keywords: [
        'riwayat transaksi', 'transaksi', 'transaction', 'history', 'pembelian',
        'invoice', 'invois', 'bayar', 'tagihan', 'struk', 'pembayaran',
        'order', 'riwayat belanja', 'bukti bayar', 'beli', 'checkout',
        'pesanan', 'kwitansi', 'nota', 'payment', 'status pembayaran',
        'riwayat pembayaran', 'tagihan kursus', 'biaya', 'history bayar'
      ],
    ),
    SpotlightItem(
      label: 'Wishlist Saya',
      description: 'Daftar program favorit yang Anda simpan',
      route: AppRoutes.wishlist,
      icon: Icons.favorite_border_rounded,
      category: 'Fitur',
      keywords: [
        'wishlist saya', 'wishlist', 'wislist', 'favorit', 'favorite',
        'disimpan', 'simpanan', 'suka', 'like', 'bookmark', 'kursus favorit',
        'nanti', 'keranjang', 'cart', 'beli nanti', 'daftar keinginan',
        'simpan dulu', 'koleksi saya', 'tonton nanti', 'disukai'
      ],
    ),
    SpotlightItem(
      label: 'Profil Saya',
      description: 'Pengaturan akun, kata sandi, dan biodata',
      route: AppRoutes.profile,
      icon: Icons.person_outline_rounded,
      category: 'Pengaturan',
      keywords: [
        'profil saya', 'profil', 'profile', 'akun', 'account', 'nama',
        'biodata', 'pengaturan', 'setting', 'settings', 'password',
        'kata sandi', 'ganti password', 'ubah sandi', 'foto', 'ganti foto',
        'foto profil', 'avatar', 'logout', 'keluar', 'email', 'telepon',
        'no hp', 'nomor telepon', 'data diri', 'edit akun', 'ubah profil',
        'user profile'
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCoursesForSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _fetchCoursesForSearch() async {
    try {
      setState(() => _isLoadingCourses = true);
      final ds = sl<CourseRemoteDataSource>();
      final list = await ds.getCourses();
      if (mounted) {
        setState(() {
          _cachedCourses = list;
          _isLoadingCourses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelectDestination(SpotlightItem item) {
    Navigator.pop(context); // Close search modal
    if (item.courseData != null) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(
            item: item.courseData!,
            isBootcamp: item.courseData?['itemType'] == 'BOOTCAMP',
          ),
        ),
      );
    } else if (item.route != null) {
      context.go(item.route!);
    }
  }

  // ── Maximized Typo Tolerance: Damerau-Levenshtein & Letter Compression ────
  static int _damerauLevenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final d = List.generate(
      s.length + 1,
      (i) => List.filled(t.length + 1, 0),
    );

    for (int i = 0; i <= s.length; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = (s[i - 1] == t[j - 1]) ? 0 : 1;
        int minVal = d[i - 1][j] + 1; // deletion
        if (d[i][j - 1] + 1 < minVal) minVal = d[i][j - 1] + 1; // insertion
        if (d[i - 1][j - 1] + cost < minVal) minVal = d[i - 1][j - 1] + cost; // substitution

        // Transposition (e.g. "teh" <-> "the" or "figam" <-> "figma")
        if (i > 1 && j > 1 && s[i - 1] == t[j - 2] && s[i - 2] == t[j - 1]) {
          if (d[i - 2][j - 2] + cost < minVal) {
            minVal = d[i - 2][j - 2] + cost;
          }
        }
        d[i][j] = minVal;
      }
    }
    return d[s.length][t.length];
  }

  // Compresses repeated letters (e.g. "kelasssss" -> "kelass")
  static String _compressLetters(String s) {
    return s.replaceAll(RegExp(r'(.)\1{2,}'), r'\1\1');
  }

  // Advanced fuzzy matcher with strict target-to-query direction and adaptive thresholds
  static bool _fuzzyMatch(String target, String query) {
    target = target.toLowerCase().trim();
    query = query.toLowerCase().trim();
    if (target.isEmpty || query.isEmpty) return false;

    // 1. Target must contain the query (NEVER check query.contains(target)
    // to prevent long random gibberish like "webdiejhfhejsjwjsjwjje" from matching short keywords like "web")
    if (target.contains(query)) return true;

    final compressedQuery = _compressLetters(query);
    final compressedTarget = _compressLetters(target);
    if (compressedTarget.contains(compressedQuery)) return true;

    // 2. Word-by-word comparison in target
    final words = target.split(RegExp(r'[\s\-_\/]+'));
    for (final w in words) {
      if (w.isEmpty) continue;
      // Target word starts with query (e.g. target word "sertifikat" starts with "sertif")
      if (w.startsWith(query)) return true;

      // Allow edit distance only if lengths are very close!
      final lenDiff = (w.length - query.length).abs();
      final maxAllowedDist = query.length >= 8
          ? 2
          : (query.length >= 4 ? 1 : 0);

      if (maxAllowedDist > 0 && lenDiff <= maxAllowedDist) {
        if (_damerauLevenshtein(w, query) <= maxAllowedDist) return true;
      }

      // Prefix fuzzy check for compound words (e.g. w = 'sertifikasi', query = 'sertif')
      if (query.length >= 4 && w.length > query.length && lenDiff <= 3) {
        final prefix = w.substring(0, query.length);
        if (_damerauLevenshtein(prefix, query) <= 1) return true;
      }
    }
    return false;
  }

  // Token extraction with conversational stopwords stripping
  static List<String> _extractTokens(String query) {
    final raw = query.toLowerCase().trim().split(RegExp(r'[\s\-_\.,\?!]+'));
    final filtered = raw.where((t) => t.isNotEmpty && !_stopwords.contains(t)).toList();
    return filtered.isNotEmpty ? filtered : raw.where((t) => t.isNotEmpty).toList();
  }

  // ── Maximized Relevance Scoring Engine for Destinations ───────────────────
  int _scorePage(SpotlightItem item, String fullQuery, List<String> tokens) {
    final label = item.label.toLowerCase();
    final desc = item.description.toLowerCase();

    int score = 0;

    // 1. Exact & Full Phrase Matches (Top Tier)
    if (label == fullQuery) {
      score += 2000;
    } else if (label.startsWith(fullQuery)) {
      score += 1200;
    } else if (label.contains(fullQuery)) {
      score += 800;
    }

    // 2. Keyword Matches (Exact & Substring)
    for (final kw in item.keywords) {
      final kwLower = kw.toLowerCase();
      if (kwLower == fullQuery) {
        score += 1500;
      } else if (kwLower.startsWith(fullQuery)) {
        score += 600;
      } else if (kwLower.contains(fullQuery)) {
        score += 400;
      } else if (_fuzzyMatch(kwLower, fullQuery)) {
        score += 250;
      }
    }

    if (desc.contains(fullQuery)) score += 300;

    // 3. Multi-Word Token Matching
    int matchedTokensCount = 0;
    for (final token in tokens) {
      bool tokenMatched = false;
      if (label.contains(token)) {
        score += 250;
        tokenMatched = true;
      }
      if (desc.contains(token)) {
        score += 100;
        tokenMatched = true;
      }
      for (final kw in item.keywords) {
        final kwLower = kw.toLowerCase();
        if (kwLower.contains(token)) {
          score += 180;
          tokenMatched = true;
          break;
        } else if (_fuzzyMatch(kwLower, token)) {
          score += 120;
          tokenMatched = true;
          break;
        }
      }
      if (tokenMatched) matchedTokensCount++;
    }

    // Multi-Word Handling: require at least half the tokens to match in multi-word queries
    if (tokens.length > 1) {
      final minRequired = (tokens.length / 2).ceil();
      if (matchedTokensCount < minRequired) {
        score = 0;
      } else if (matchedTokensCount == tokens.length) {
        score += 800; // ALL tokens matched bonus!
      } else {
        score += (matchedTokensCount * 150);
      }
    }

    // 4. Fuzzy Match Fallback directly on label
    if (score == 0 && _fuzzyMatch(label, fullQuery)) {
      score += 200;
    }

    return score;
  }

  // ── Maximized Relevance Scoring Engine for Live Courses ───────────────────
  int _scoreCourse(Map<String, dynamic> c, String fullQuery, List<String> tokens) {
    final title = (c['title'] ?? '').toString().toLowerCase();
    final field = (c['field'] ?? '').toString().toLowerCase().replaceAll('_', ' ');
    final desc = (c['shortDescription'] ?? c['description'] ?? '').toString().toLowerCase();
    final type = (c['itemType'] ?? '').toString().toLowerCase();
    final instructor = (c['instructor'] is Map
            ? c['instructor']['name']
            : c['instructorName'] ?? '')
        .toString()
        .toLowerCase();

    int score = 0;

    // Exact title match
    if (title == fullQuery) {
      score += 2000;
    } else if (title.startsWith(fullQuery)) {
      score += 1200;
    } else if (title.contains(fullQuery)) {
      score += 800;
    }

    if (field.contains(fullQuery)) score += 500;
    if (type.contains(fullQuery)) score += 400;
    if (desc.contains(fullQuery)) score += 250;
    if (instructor.contains(fullQuery)) score += 300;

    int matchedTokensCount = 0;
    for (final token in tokens) {
      bool tokenMatched = false;
      if (title.contains(token)) {
        score += 250;
        tokenMatched = true;
      }
      if (field.contains(token)) {
        score += 180;
        tokenMatched = true;
      }
      if (type.contains(token)) {
        score += 150;
        tokenMatched = true;
      }
      if (desc.contains(token)) {
        score += 100;
        tokenMatched = true;
      }
      if (instructor.contains(token)) {
        score += 120;
        tokenMatched = true;
      }
      if (!tokenMatched && _fuzzyMatch(title, token)) {
        score += 120;
        tokenMatched = true;
      }
      if (tokenMatched) matchedTokensCount++;
    }

    // Multi-Word BONUS for courses
    if (tokens.length > 1) {
      final minRequired = (tokens.length / 2).ceil();
      if (matchedTokensCount < minRequired) {
        score = 0;
      } else if (matchedTokensCount == tokens.length) {
        score += 800;
      } else {
        score += (matchedTokensCount * 150);
      }
    }

    if (score == 0 && _fuzzyMatch(title, fullQuery)) {
      score += 180;
    }

    return score;
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final tokens = _extractTokens(q);

    // 1. Score & Rank Pages
    final List<MapEntry<SpotlightItem, int>> scoredPages = [];
    if (_query.isEmpty) {
      for (final p in _allPages) {
        scoredPages.add(MapEntry(p, 1));
      }
    } else {
      for (final p in _allPages) {
        final score = _scorePage(p, q, tokens);
        if (score > 0) {
          scoredPages.add(MapEntry(p, score));
        }
      }
      scoredPages.sort((a, b) => b.value.compareTo(a.value));
    }
    final filteredPages = scoredPages.map((e) => e.key).toList();

    // 2. Score & Rank Courses from Live API
    final List<MapEntry<SpotlightItem, int>> scoredCourses = [];
    if (_query.isNotEmpty && _cachedCourses.isNotEmpty) {
      for (final c in _cachedCourses) {
        if (c is Map<String, dynamic>) {
          final score = _scoreCourse(c, q, tokens);
          if (score > 0) {
            final title = (c['title'] ?? '').toString();
            final field = (c['field'] ?? '').toString();
            final itemType = (c['itemType'] ?? 'COURSE').toString();
            final typeLabel = itemType == 'BOOTCAMP' ? 'Bootcamp' : 'Mini Course';
            final desc = '${field.replaceAll('_', ' ')} • $typeLabel';
            scoredCourses.add(
              MapEntry(
                SpotlightItem(
                  label: title,
                  description: desc,
                  icon: itemType == 'BOOTCAMP'
                      ? Icons.terrain_rounded
                      : Icons.play_circle_fill_rounded,
                  category: 'Kursus & Materi',
                  courseData: c,
                ),
                score,
              ),
            );
          }
        }
      }
      scoredCourses.sort((a, b) => b.value.compareTo(a.value));
    }
    final matchingCourses = scoredCourses.map((e) => e.key).toList();

    final totalResultsCount = filteredPages.length + matchingCourses.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean background matching Kursus Saya (AppColors.background)
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── TOP SEARCH BAR HEADER (Pure white, matching Kursus Saya search header) ────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA), // Soft background matching Kursus Saya input field
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              cursorColor: const Color(0xFF0F172A),
                              cursorWidth: 1.5,
                              onChanged: (val) => setState(() => _query = val.trim()),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                hintText: 'Cari halaman, topik, materi...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          // Clear button (if typing)
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12, left: 6),
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
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Batal (Cancel) Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hairline separator
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── RESULTS LIST (Fast Navigation + Live Courses) ───────────────────
            Expanded(
              child: totalResultsCount == 0
                  ? _buildNoResultsPlaceholder()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        // Section Header: Kursus & Materi (if matching query)
                        if (matchingCourses.isNotEmpty || (_isLoadingCourses && _query.isNotEmpty)) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                            child: Row(
                              children: [
                                Text(
                                  'KURSUS & MATERI (${matchingCourses.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                if (_isLoadingCourses) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ...matchingCourses.map((item) => _buildResultCard(item)),
                          const SizedBox(height: 14),
                        ],

                        // Section Header: Navigasi Halaman
                        if (filteredPages.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                            child: Text(
                              _query.isEmpty
                                  ? 'NAVIGASI CEPAT'
                                  : 'HALAMAN & FITUR (${filteredPages.length})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          ...filteredPages.map((item) => _buildResultCard(item)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(SpotlightItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSelectDestination(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon Box (rounded square 40x40)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.courseData != null
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      color: item.courseData != null ? Colors.white : const Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Label & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_query.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsPlaceholder() {
    final suggestions = [
      {'label': 'Belajar Koding', 'query': 'koding'},
      {'label': 'Figma UI/UX', 'query': 'figma'},
      {'label': 'Bootcamp Intensif', 'query': 'bootcamp'},
      {'label': 'Tantangan & Tugas', 'query': 'tugas'},
      {'label': 'Sertifikat Kelulusan', 'query': 'sertifikat'},
      {'label': 'Papan Peringkat', 'query': 'ranking'},
      {'label': 'Riwayat Pembayaran', 'query': 'transaksi'},
      {'label': 'Streak Api XP', 'query': 'streak'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ditemukan hasil untuk "$_query"',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba salah satu kata kunci populer di bawah ini:',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF64748B),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Suggestion Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions.map((s) {
              return ActionChip(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                label: Text(
                  s['label']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                onPressed: () {
                  _controller.text = s['query']!;
                  setState(() => _query = s['query']!);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
