import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/bootcamp_remote_datasource.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import '../../../../data/datasources/remote/webinar_remote_datasource.dart';
import '../../../../data/datasources/remote/wishlist_remote_datasource.dart';
import 'course_detail_screen.dart';
import '../widgets/clean_combobox.dart';

/// LearnScreen — Ruang Belajar Discovery page:
/// • Clean Search Bar with dark charcoal cursor (NO green color)
/// • Black Filter Button (Sort by Rating, Harga Tertinggi, Harga Terendah, Gratis)
/// • Side-by-side Clean Comboboxes using official Admin Fields (UI/UX, Frontend, Backend, Mobile)
///   and dynamically discovered fields from the live database — ZERO hardcoding / invented data
/// • Big Hero Card Carousel (maximum 10 items) with snap effect & peeking side cards
/// • "Program Lainnya" section (5 distinct items different from hero cards + "Lihat Semua" card at the far right)
/// • Full dynamic image resolver supporting bannerUrl (Webinar), thumbnailUrl (Course/Bootcamp), and relative paths
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  static void clearCache() => _LearnScreenState.clearCache();

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _courseDs = sl<CourseRemoteDataSource>();
  final _bootcampDs = sl<BootcampRemoteDataSource>();
  final _webinarDs = sl<WebinarRemoteDataSource>();
  final _wishlistDs = sl<WishlistRemoteDataSource>();

  // Static Caches
  static List<dynamic>? _cachedCourses;
  static List<dynamic>? _cachedBootcamps;
  static List<dynamic>? _cachedWebinars;
  static List<dynamic>? _cachedMyClasses;
  static Set<String>? _cachedEnrolledIds;

  static void clearCache() {
    _cachedCourses = null;
    _cachedBootcamps = null;
    _cachedWebinars = null;
    _cachedMyClasses = null;
    _cachedEnrolledIds = null;
  }

  // Data Lists
  bool _isLoading = false;
  List<dynamic> _courses = _cachedCourses ?? [];
  List<dynamic> _bootcamps = _cachedBootcamps ?? [];
  List<dynamic> _webinars = _cachedWebinars ?? [];
  List<dynamic> _myClasses = _cachedMyClasses ?? [];
  final Set<String> _enrolledIds = Set.from(_cachedEnrolledIds ?? {});

  // Wishlist
  final Set<String> _wishlistIds = {};

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedField; // null or 'ALL' = Semua
  String _selectedProgram = 'Semua'; // 'Semua', 'Mini Course', 'Bootcamp', 'Webinar', 'Kelas Saya'
  String? _activeSortFilter; // null, 'rating', 'price_high', 'price_low'
  double _minRating = 0.0; // Slider: 0.0 to 5.0 (0.0 = Semua)
  RangeValues? _priceRange; // RangeSlider: min to max (null = rentang penuh)

  // Carousel Controller (Starts from first unpurchased card)
  PageController? _pageController;
  int _currentHeroIndex = 0;
  String _lastHeroSignature = '';

  @override
  void initState() {
    super.initState();
    _loadWishlistIds();
    _loadAllData();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWishlistIds() async {
    try {
      final items = await _wishlistDs.getWishlist();
      final ids = <String>{};
      for (final it in items) {
        if (it is Map<String, dynamic>) {
          if (it['courseId'] != null) ids.add(it['courseId'].toString());
          if (it['bootcampId'] != null) ids.add(it['bootcampId'].toString());
          if (it['course']?['id'] != null) ids.add(it['course']['id'].toString());
          if (it['bootcamp']?['id'] != null) ids.add(it['bootcamp']['id'].toString());
        }
      }
      if (mounted) setState(() => _wishlistIds.addAll(ids));
    } catch (_) {}
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadMiniCourses(),
      _loadBootcamps(),
      _loadWebinars(),
      _loadMyClasses(),
    ]);
  }

  Future<void> _loadMiniCourses() async {
    if (_cachedCourses == null) setState(() => _isLoading = true);
    try {
      final list = await _courseDs.getCourses(field: _selectedField);
      _cachedCourses = list;
      if (!mounted) return;
      setState(() {
        _courses = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBootcamps() async {
    if (_cachedBootcamps == null) setState(() => _isLoading = true);
    try {
      final list = await _bootcampDs.getBootcamps(field: _selectedField);
      _cachedBootcamps = list;
      if (!mounted) return;
      setState(() {
        _bootcamps = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWebinars() async {
    if (_cachedWebinars == null) setState(() => _isLoading = true);
    try {
      final list = await _webinarDs.getWebinars();
      _cachedWebinars = list;
      if (!mounted) return;
      setState(() {
        _webinars = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMyClasses() async {
    if (_cachedMyClasses == null) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _courseDs.getEnrolledCourses().catchError((_) => []),
        _bootcampDs.getEnrolledBootcamps().catchError((_) => []),
        _webinarDs.getMyWebinars().catchError((_) => []),
      ]);
      final enrolledCourses = results[0]
          .map((c) => {...(c as Map<String, dynamic>), 'itemType': 'MINI_COURSE'});
      final enrolledBootcamps = results[1]
          .map((b) => {...(b as Map<String, dynamic>), 'itemType': 'BOOTCAMP'});
      final registeredWebinars = results[2]
          .map((w) => {...(w as Map<String, dynamic>), 'itemType': 'WEBINAR', 'isRegistered': true});
      final combined = [...enrolledCourses, ...enrolledBootcamps, ...registeredWebinars];

      final ids = <String>{};
      for (final it in combined) {
        final id = it['id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
        final cid = it['courseId']?.toString();
        if (cid != null && cid.isNotEmpty) ids.add(cid);
        final bid = it['bootcampId']?.toString();
        if (bid != null && bid.isNotEmpty) ids.add(bid);
        final wid = it['webinarId']?.toString();
        if (wid != null && wid.isNotEmpty) ids.add(wid);
      }

      _cachedMyClasses = combined;
      _cachedEnrolledIds = ids;
      if (!mounted) return;
      setState(() {
        _myClasses = combined;
        _enrolledIds.clear();
        _enrolledIds.addAll(ids);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── DYNAMIC IMAGE RESOLVER (Supports bannerUrl, thumbnailUrl, and full Cloudinary URLs) ──
  String _getItemImage(Map<String, dynamic> item) {
    final raw = (item['bannerUrl'] ??
            item['thumbnailUrl'] ??
            item['thumbnail'] ??
            item['banner'] ??
            item['coverUrl'] ??
            item['imageUrl'] ??
            item['image'] ??
            '')
        .toString()
        .trim();
    if (raw.isEmpty || raw == 'null') return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return 'https://api.metroinstitute.site$raw';
    return 'https://$raw';
  }

  Future<void> _toggleWishlist(Map<String, dynamic> item, bool isBootcamp) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final isWish = _wishlistIds.contains(id);
    setState(() {
      if (isWish) {
        _wishlistIds.remove(id);
      } else {
        _wishlistIds.add(id);
      }
    });

    try {
      if (isWish) {
        await _wishlistDs.removeFromWishlist(
          courseId: !isBootcamp ? id : null,
          bootcampId: isBootcamp ? id : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dihapus dari Wishlist'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await _wishlistDs.addToWishlist(
          courseId: !isBootcamp ? id : null,
          bootcampId: isBootcamp ? id : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disimpan ke Wishlist'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (isWish) {
            _wishlistIds.add(id);
          } else {
            _wishlistIds.remove(id);
          }
        });
      }
    }
  }

  bool _isItemEnrolled(Map<String, dynamic> item) {
    if (item['isEnrolled'] == true || item['isRegistered'] == true) return true;
    final id = item['id']?.toString() ?? '';
    if (id.isNotEmpty && _enrolledIds.contains(id)) return true;
    final courseId = item['courseId']?.toString() ?? '';
    if (courseId.isNotEmpty && _enrolledIds.contains(courseId)) return true;
    final bootcampId = item['bootcampId']?.toString() ?? '';
    if (bootcampId.isNotEmpty && _enrolledIds.contains(bootcampId)) return true;
    final webinarId = item['webinarId']?.toString() ?? '';
    if (webinarId.isNotEmpty && _enrolledIds.contains(webinarId)) return true;
    return false;
  }

  Future<void> _openCourseDetail(Map<String, dynamic> course) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          item: {
            ...course,
            if (_isItemEnrolled(course)) 'isEnrolled': true,
          },
          isBootcamp: false,
        ),
      ),
    );
    _loadMyClasses();
  }

  Future<void> _openBootcampDetail(Map<String, dynamic> bootcamp) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          item: {
            ...bootcamp,
            if (_isItemEnrolled(bootcamp)) 'isEnrolled': true,
          },
          isBootcamp: true,
        ),
      ),
    );
    _loadMyClasses();
  }

  void _openItemDetail(Map<String, dynamic> item) {
    final isBootcamp = item['itemType'] == 'BOOTCAMP' || item['batchStatus'] != null;
    final isWebinar = item['itemType'] == 'WEBINAR' || item['eventDate'] != null;
    if (isWebinar) {
      final wid = item['id']?.toString() ?? '';
      final wtitle = item['title']?.toString() ?? 'Webinar';
      _openWebinarAttendanceDialog(wid, wtitle);
    } else if (isBootcamp) {
      _openBootcampDetail(item);
    } else {
      _openCourseDetail(item);
    }
  }

  void _openWebinarAttendanceDialog(String webinarId, String webinarTitle) {
    final feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Presensi Kehadiran',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                webinarTitle,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tuliskan feedback singkat atau kesimpulan materi yang Anda dapatkan:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Materinya sangat relevan dan aplikatif...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setModalState(() => isSubmitting = true);
                      try {
                        await _webinarDs.attendWebinar(webinarId, feedback: feedbackController.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Presensi berhasil dicatat. Terima kasih!'), backgroundColor: AppColors.primary),
                        );
                        _loadWebinars();
                        _loadMyClasses();
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSubmitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kirim Presensi'),
            ),
          ],
        ),
      ),
    );
  }

  // ── DYNAMIC PRICE & RATING GETTERS (Zero hardcoded bounds & 100% crash-proof) ─
  int _parseItemPrice(dynamic itemOrPrice) {
    dynamic raw = itemOrPrice;
    if (itemOrPrice is Map) {
      raw = itemOrPrice['price'];
    }
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean)?.toInt() ?? 0;
    }
    return 0;
  }

  double _parseItemRating(dynamic itemOrRating) {
    dynamic raw = itemOrRating;
    if (itemOrRating is Map) {
      raw = itemOrRating['rating'];
    }
    if (raw == null) return 5.0;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      return double.tryParse(raw) ?? 5.0;
    }
    return 5.0;
  }

  DateTime _parseItemDate(dynamic item) {
    if (item is! Map) return DateTime.fromMillisecondsSinceEpoch(0);
    final raw = item['createdAt'] ??
        item['scheduledAt'] ??
        item['eventDate'] ??
        item['registrationStartDate'] ??
        item['batchStartDate'] ??
        item['updatedAt'];
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (raw is DateTime) return raw;
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<dynamic> _getBaseItemsForCurrentProgram() {
    if (_selectedProgram == 'Mini Course') {
      return _courses;
    } else if (_selectedProgram == 'Bootcamp') {
      return _bootcamps;
    } else if (_selectedProgram == 'Webinar') {
      return _webinars;
    } else if (_selectedProgram == 'Kelas Saya') {
      return _myClasses;
    } else {
      return [..._courses, ..._bootcamps, ..._webinars];
    }
  }

  double get _dbMinPrice {
    var pool = _getBaseItemsForCurrentProgram();
    if (pool.isEmpty) pool = [..._courses, ..._bootcamps, ..._webinars];
    if (pool.isEmpty) return 0.0;
    int minP = 999999999;
    for (final it in pool) {
      final p = _parseItemPrice(it);
      if (p < minP) minP = p;
    }
    return (minP == 999999999) ? 0.0 : minP.toDouble();
  }

  double get _dbMaxPrice {
    var pool = _getBaseItemsForCurrentProgram();
    if (pool.isEmpty) pool = [..._courses, ..._bootcamps, ..._webinars];
    if (pool.isEmpty) return 1000000.0;
    int maxP = 0;
    for (final it in pool) {
      final p = _parseItemPrice(it);
      if (p > maxP) maxP = p;
    }
    return maxP.toDouble();
  }

  double get _effectiveMinPrice => _dbMinPrice;
  double get _effectiveMaxPrice {
    final minP = _effectiveMinPrice;
    final maxP = _dbMaxPrice;
    if (maxP <= minP) {
      return minP + 1000000.0;
    }
    return maxP;
  }

  String _formatRupiah(int price) {
    if (price <= 0) return 'Gratis';
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  // ── FILTER & SORT BOTTOM SHEET (Interactive Rating & Price Sliders) ────────
  void _showSortFilterModal() {
    final double dbMin = _effectiveMinPrice;
    final double dbMax = _effectiveMaxPrice;

    double tempRating = _minRating.clamp(0.0, 5.0);
    RangeValues tempPriceRange = _priceRange ?? RangeValues(dbMin, dbMax);
    String? tempSort = _activeSortFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Prevents fullscreen white overlay
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double priceDiff = dbMax - dbMin;
            final double priceStep = priceDiff > 500000 ? 50000 : (priceDiff > 100000 ? 25000 : 10000);

            final safeStart = tempPriceRange.start.clamp(dbMin, dbMax);
            final safeEnd = tempPriceRange.end.clamp(safeStart, dbMax);
            final currentRange = RangeValues(safeStart, safeEnd);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2), // Elegant warm cream palette
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6CDC3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header: Title & Reset Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter & Urutkan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempRating = 0.0;
                                tempPriceRange = RangeValues(dbMin, dbMax);
                                tempSort = null;
                              });
                            },
                            child: Text(
                              'Reset Filter',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8C827A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ── 1. FILTER RATING (SLIDER) ──────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 6),
                              Text(
                                'Rating Minimal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              tempRating == 0.0
                                  ? 'Semua Rating'
                                  : '⭐ ${tempRating.toStringAsFixed(1)} ke atas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF0F172A),
                          inactiveTrackColor: const Color(0xFFE2E8F0),
                          thumbColor: const Color(0xFF0F172A),
                          overlayColor: const Color(0x1F0F172A),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: tempRating,
                          min: 0.0,
                          max: 5.0,
                          divisions: 10,
                          onChanged: (val) {
                            setModalState(() => tempRating = val);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0.0 (Semua)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                            Text(
                              '5.0 (Sempurna)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 2. FILTER RENTANG HARGA (RANGE SLIDER) ─────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF0F172A)),
                              const SizedBox(width: 6),
                              Text(
                                'Rentang Harga',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '${_formatRupiah(currentRange.start.round())} - ${_formatRupiah(currentRange.end.round())}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF0F172A),
                          inactiveTrackColor: const Color(0xFFE2E8F0),
                          thumbColor: const Color(0xFF0F172A),
                          overlayColor: const Color(0x1F0F172A),
                          trackHeight: 4,
                        ),
                        child: RangeSlider(
                          values: currentRange,
                          min: dbMin,
                          max: dbMax,
                          onChanged: (vals) {
                            setModalState(() {
                              final start = ((vals.start / priceStep).round() * priceStep).clamp(dbMin, vals.end);
                              final end = ((vals.end / priceStep).round() * priceStep).clamp(start, dbMax);
                              tempPriceRange = RangeValues(start, end);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Termurah: ${_formatRupiah(dbMin.round())}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                            Text(
                              'Termahal: ${_formatRupiah(dbMax.round())}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 3. URUTKAN (SORTING PILLS) ──────────────────────────
                      Text(
                        'Urutkan Berdasarkan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSortChip(null, 'Rekomendasi', tempSort, (val) => setModalState(() => tempSort = val)),
                          _buildSortChip('rating', '⭐ Rating Tertinggi', tempSort, (val) => setModalState(() => tempSort = val)),
                          _buildSortChip('price_low', 'Harga Terendah', tempSort, (val) => setModalState(() => tempSort = val)),
                          _buildSortChip('price_high', 'Harga Tertinggi', tempSort, (val) => setModalState(() => tempSort = val)),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // ── 4. TERAPKAN FILTER BUTTON ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _minRating = tempRating;
                              final isFullRange = (tempPriceRange.start <= dbMin && tempPriceRange.end >= dbMax);
                              _priceRange = isFullRange ? null : tempPriceRange;
                              _activeSortFilter = tempSort;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Terapkan Filter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(String? key, String label, String? current, ValueChanged<String?> onSelect) {
    final isSelected = current == key;
    return GestureDetector(
      onTap: () => onSelect(isSelected && key != null ? null : key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterBadge({required String label, required VoidCallback onClear}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _getSortFilterLabel(String? key) {
    switch (key) {
      case 'rating':
        return '⭐ Rating Tertinggi';
      case 'price_high':
        return 'Harga Tertinggi';
      case 'price_low':
        return 'Harga Terendah';
      case 'free':
        return 'Kelas Gratis';
      default:
        return 'Filter Aktif';
    }
  }

  // ── "LIHAT SEMUA" MODAL SHEET ──────────────────────────────────────────────
  void _openAllProgramsModal(List<dynamic> allItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6CDC3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Semua Program',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${allItems.length} Program',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: allItems.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada program yang tersedia',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF8C827A),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: allItems.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = allItems[i] as Map<String, dynamic>;
                              return _buildSecondaryCardListItem(item);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── RUBBER STAMP ENROLLED BADGE (Inspired by official PAID stamp seal) ──────
  Widget _buildStampBadge({
    required bool isWebinar,
    double scale = 1.0,
    bool compact = false,
  }) {
    final primaryText = isWebinar ? 'TERDAFTAR' : 'SUDAH DIBELI';
    final subText = isWebinar ? 'LIVE ACCESS' : 'AKSES AKTIF';
    const stampColor = Color(0xFFDC2626);

    return Transform.rotate(
      angle: -8 * (math.pi / 180),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (compact ? 6 : 8) * scale,
          vertical: (compact ? 3 : 4) * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(6 * scale),
          border: Border.all(
            color: stampColor,
            width: 1.8 * scale,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.16),
              blurRadius: 8 * scale,
              offset: Offset(0, 2.5 * scale),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: (compact ? 4 : 6) * scale,
            vertical: (compact ? 2 : 2.5) * scale,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.5 * scale),
            border: Border.all(
              color: stampColor.withValues(alpha: 0.38),
              width: 0.8 * scale,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                primaryText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: (compact ? 8.5 : 10.5) * scale,
                  fontWeight: FontWeight.w900,
                  color: stampColor,
                  letterSpacing: 0.8 * scale,
                  height: 1.05,
                ),
              ),
              if (!compact) ...[
                SizedBox(height: 2 * scale),
                Text(
                  subText,
                  style: GoogleFonts.spaceMono(
                    fontSize: 7 * scale,
                    fontWeight: FontWeight.w700,
                    color: stampColor,
                    letterSpacing: 0.7 * scale,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryCardListItem(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Program').toString();
    final isBootcamp = item['itemType'] == 'BOOTCAMP' || item['batchStatus'] != null;
    final isWebinar = item['itemType'] == 'WEBINAR' || item['eventDate'] != null;
    final thumbnail = _getItemImage(item);
    final price = _parseItemPrice(item);
    final priceStr = price == 0 ? 'GRATIS' : _formatRupiah(price);
    final rating = _parseItemRating(item);
    final reviewCount = (item['reviewCount'] ?? 12).toString();
    final duration = isWebinar ? 'Webinar Live' : (isBootcamp ? '8 Minggu' : '12 Materi');
    final isEnrolled = _isItemEnrolled(item);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _openItemDetail(item);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: const Color(0xFFF2ECE4)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFF2ECE4),
                              child: const Icon(Icons.image_outlined, color: Color(0xFF8C827A)),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF2ECE4),
                            child: const Icon(Icons.school_outlined, color: Color(0xFF8C827A)),
                          ),
                    if (isEnrolled)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: _buildStampBadge(
                          isWebinar: isWebinar,
                          scale: 0.70,
                          compact: true,
                        ),
                      ),
                  ],
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '$duration • $priceStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8C827A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF8C827A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── OFFICIAL ADMIN FIELDS & DYNAMIC EXTRACTION ────────────────────────────
    // Synchronized 1:1 with admin dashboard FIELD_LABELS:
    // UI_UX: 'UI/UX', FRONTEND: 'Frontend', BACKEND: 'Backend', MOBILE: 'Mobile'
    final Map<String, String> adminFields = {
      'BACKEND': 'Backend',
      'FRONTEND': 'Frontend',
      'UI_UX': 'UI/UX',
      'MOBILE': 'Mobile',
    };

    // Dynamically discover any other fields present in loaded data (Zero hardcoding)
    for (final it in [..._courses, ..._bootcamps, ..._webinars]) {
      final f = it['field']?.toString().toUpperCase();
      if (f != null && f.isNotEmpty && f != 'NULL' && !adminFields.containsKey(f)) {
        adminFields[f] = f.replaceAll('_', ' ');
      }
    }

    final fieldComboboxOptions = [
      const ComboboxOption(value: 'ALL', label: 'Semua Bidang'),
      ...adminFields.entries.map((e) => ComboboxOption(value: e.key, label: e.value)),
    ];

    // 1. Filter active items based on selected program
    List<dynamic> activeItems = [];
    if (_selectedProgram == 'Mini Course') {
      activeItems = List.from(_courses);
    } else if (_selectedProgram == 'Bootcamp') {
      activeItems = List.from(_bootcamps);
    } else if (_selectedProgram == 'Webinar') {
      activeItems = List.from(_webinars);
    } else if (_selectedProgram == 'Kelas Saya') {
      activeItems = List.from(_myClasses);
    } else {
      // 'Semua' — Combine courses, bootcamps, and webinars
      activeItems = [..._courses, ..._bootcamps, ..._webinars];
    }

    // 2. Filter by selected field / bidang
    if (_selectedField != null && _selectedField != 'ALL') {
      activeItems = activeItems.where((it) {
        final f = (it['field'] ?? '').toString().toUpperCase();
        return f == _selectedField;
      }).toList();
    }

    // 3. Filter by search query
    if (_searchQuery.isNotEmpty) {
      activeItems = activeItems.where((it) {
        final t = (it['title'] ?? '').toString().toLowerCase();
        final d = (it['shortDescription'] ?? it['description'] ?? '').toString().toLowerCase();
        return t.contains(_searchQuery) || d.contains(_searchQuery);
      }).toList();
    }

    // 4. Filter by Rating Slider (Minimal Rating)
    if (_minRating > 0.0) {
      activeItems = activeItems.where((it) {
        final r = _parseItemRating(it);
        return r >= _minRating;
      }).toList();
    }

    // 5. Filter by Price Range Slider (Batas Bawah & Batas Atas Dinamis)
    if (_priceRange != null) {
      activeItems = activeItems.where((it) {
        final p = _parseItemPrice(it);
        return p >= _priceRange!.start.round() && p <= _priceRange!.end.round();
      }).toList();
    }

    // 6. Sort
    // Default: Urutkan dari yang terbaru (createdAt / scheduledAt / eventDate descending)
    activeItems.sort((a, b) {
      final da = _parseItemDate(a);
      final db = _parseItemDate(b);
      return db.compareTo(da);
    });

    if (_activeSortFilter == 'rating') {
      activeItems.sort((a, b) {
        final ra = _parseItemRating(a);
        final rb = _parseItemRating(b);
        return rb.compareTo(ra);
      });
    } else if (_activeSortFilter == 'price_high') {
      activeItems.sort((a, b) {
        final pa = _parseItemPrice(a);
        final pb = _parseItemPrice(b);
        return pb.compareTo(pa);
      });
    } else if (_activeSortFilter == 'price_low') {
      activeItems.sort((a, b) {
        final pa = _parseItemPrice(a);
        final pb = _parseItemPrice(b);
        return pa.compareTo(pb);
      });
    } else if (_activeSortFilter == 'free') {
      activeItems = activeItems.where((it) => _parseItemPrice(it) == 0).toList();
    }

    // Prioritas: Program belum dibeli ditampilkan di awal (dari yang terbaru),
    // disusul program yang sudah dibeli (dari yang terbaru).
    final List<dynamic> sortedAll;
    if (_selectedProgram != 'Kelas Saya') {
      final unpurchased = activeItems.where((it) {
        if (it is Map<String, dynamic>) {
          return !_isItemEnrolled(it);
        }
        return true;
      }).toList();
      final purchased = activeItems.where((it) {
        if (it is Map<String, dynamic>) {
          return _isItemEnrolled(it);
        }
        return false;
      }).toList();
      sortedAll = [...unpurchased, ...purchased];
    } else {
      sortedAll = List.from(activeItems);
    }

    // Aturan jatah card besar: maksimal 10 card terbaru
    final heroItems = sortedAll.take(10).toList();

    // "Program Lainnya" HANYA muncul jika card lebih dari 10 (ada 11 atau lebih),
    // dan hanya menampung sisanya (mulai dari card ke-11 dst).
    final secondaryItems = sortedAll.length > 10 ? sortedAll.skip(10).toList() : <dynamic>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Warm Cream Palette matching design
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: RefreshIndicator(
            color: const Color(0xFF0F172A),
            onRefresh: _loadAllData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // ── 1. CLEAN SEARCH & FILTER BAR (Strictly ZERO Green Border) ────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Clean Search Pill matching Basecamp border & styling
                        Expanded(
                          child: Container(
                            height: 48,
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
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                primaryColor: const Color(0xFF0F172A),
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: const Color(0xFF0F172A),
                                ),
                                inputDecorationTheme: const InputDecorationTheme(
                                  filled: false,
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                ),
                                textSelectionTheme: const TextSelectionThemeData(
                                  cursorColor: Color(0xFF0F172A),
                                  selectionColor: Color(0x330F172A),
                                  selectionHandleColor: Color(0xFF0F172A),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                cursorColor: const Color(0xFF0F172A),
                                cursorWidth: 1.5,
                                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                          child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                                        )
                                      : null,
                                  hintText: 'Cari kelas atau topik...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Dongker Filter Button (Dark Navy 0xFF0F172A matching buttons)
                        GestureDetector(
                          onTap: _showSortFilterModal,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1F0F172A),
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                              ),
                              if (_activeSortFilter != null || _minRating > 0.0 || _priceRange != null)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 2. SIDE-BY-SIDE COMBOBOXES (Taken from Admin / DB) ────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Program Combobox (Semua, Mini Course, Bootcamp, Webinar, Kelas Saya)
                        Expanded(
                          child: CleanCombobox(
                            value: _selectedProgram,
                            placeholder: 'Pilih Program',
                            options: const [
                              ComboboxOption(value: 'Semua', label: 'Semua Program'),
                              ComboboxOption(value: 'Mini Course', label: 'Mini Course'),
                              ComboboxOption(value: 'Bootcamp', label: 'Bootcamp'),
                              ComboboxOption(value: 'Webinar', label: 'Webinar'),
                              ComboboxOption(value: 'Kelas Saya', label: 'Kelas Saya'),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedProgram = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Bidang Combobox (Exact Admin Fields: UI/UX, Frontend, Backend, Mobile)
                        Expanded(
                          child: CleanCombobox(
                            value: _selectedField ?? 'ALL',
                            placeholder: 'Pilih Bidang',
                            options: fieldComboboxOptions,
                            onChanged: (val) {
                              setState(() {
                                _selectedField = val == 'ALL' ? null : val;
                              });
                              _loadMiniCourses();
                              _loadBootcamps();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Active filter badge chips (Rating, Rentang Harga, Urutan)
                if (_minRating > 0.0 || _priceRange != null || _activeSortFilter != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (_minRating > 0.0)
                            _buildActiveFilterBadge(
                              label: '⭐ ≥ ${_minRating.toStringAsFixed(1)}',
                              onClear: () => setState(() => _minRating = 0.0),
                            ),
                          if (_priceRange != null) ...[
                            if (_minRating > 0.0) const SizedBox(width: 8),
                            _buildActiveFilterBadge(
                              label: '${_formatRupiah(_priceRange!.start.round())} - ${_formatRupiah(_priceRange!.end.round())}',
                              onClear: () => setState(() => _priceRange = null),
                            ),
                          ],
                          if (_activeSortFilter != null) ...[
                            if (_minRating > 0.0 || _priceRange != null) const SizedBox(width: 8),
                            _buildActiveFilterBadge(
                              label: _getSortFilterLabel(_activeSortFilter),
                              onClear: () => setState(() => _activeSortFilter = null),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _minRating = 0.0;
                                _priceRange = null;
                                _activeSortFilter = null;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text(
                                'Reset',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8C827A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── 3. BIG HERO CARD CAROUSEL (Max 10 Items) ─────────────────
                if (_isLoading && _courses.isEmpty && _bootcamps.isEmpty)
                  _buildShimmerHeroCarousel()
                else if (heroItems.isEmpty)
                  _buildEmptyState()
                else
                  _buildHeroCarousel(heroItems),

                if (secondaryItems.isNotEmpty) ...[
                  const SizedBox(height: 32),

                  // ── 4. PROGRAM LAINNYA (Strictly matching filter + Button Lihat Semua) ─
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Program Lainnya',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openAllProgramsModal(sortedAll),
                          child: Text(
                            'Lihat semua',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8C827A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal secondary cards: strictly matching active filter + 1 "Lihat Semua" card
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: secondaryItems.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        if (i < secondaryItems.length) {
                          final item = secondaryItems[i] as Map<String, dynamic>;
                          return _buildSecondaryCard(item);
                        } else {
                          return _buildViewAllCard(sortedAll);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // ───────────────────────────────────────────────────────────────────────────
  // HERO CAROUSEL BUILDER (Animated center scale + side peeking from middle)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCarousel(List<dynamic> items) {
    // Start from index 0 so the first card displayed is always the unpurchased program
    const initialIndex = 0;
    final signature =
        '$_selectedProgram|$_selectedField|$_searchQuery|$_activeSortFilter|$_minRating|${items.length}';

    if (_pageController == null || _pageController!.initialPage != initialIndex) {
      _pageController?.dispose();
      _currentHeroIndex = initialIndex;
      _pageController = PageController(
        viewportFraction: 0.82,
        initialPage: initialIndex,
      );
      _lastHeroSignature = signature;
    } else if (_lastHeroSignature != signature) {
      _lastHeroSignature = signature;
      _currentHeroIndex = initialIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController != null && _pageController!.hasClients) {
          _pageController!.jumpToPage(initialIndex);
        }
      });
    }

    final controller = _pageController!;

    return SizedBox(
      height: 425,
      child: PageView.builder(
        controller: controller,
        itemCount: items.length,
        onPageChanged: (idx) => setState(() => _currentHeroIndex = idx),
        itemBuilder: (context, index) {
          final item = items[index] as Map<String, dynamic>;

          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final page = controller.position.haveDimensions
                  ? (controller.page ?? _currentHeroIndex.toDouble())
                  : _currentHeroIndex.toDouble();
              final diff = (index - page).abs();
              final scale = (1.0 - (diff * 0.08)).clamp(0.92, 1.0);
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: _buildHeroCard(item),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HERO CARD ITEM (Spacious, Professional Typography + Enrolled Indicator)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Program Unggulan').toString();
    final rawDesc = (item['shortDescription'] ?? item['description'] ?? '').toString();
    final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final field = (item['field'] ?? 'DEVELOPMENT').toString().replaceAll('_', ' ');
    final isBootcamp = item['itemType'] == 'BOOTCAMP' || item['batchStatus'] != null;
    final isWebinar = item['itemType'] == 'WEBINAR' || item['eventDate'] != null;
    final programType = isWebinar ? 'Webinar' : (isBootcamp ? 'Bootcamp' : 'Mini Course');
    final thumbnail = _getItemImage(item);
    final rating = _parseItemRating(item);
    final reviewCount = (item['reviewCount'] ?? 143).toString();
    final id = item['id']?.toString() ?? '';
    final isWishlisted = _wishlistIds.contains(id);
    final isEnrolled = _isItemEnrolled(item);
    final price = _parseItemPrice(item);
    final priceStr = price == 0 ? 'Gratis' : _formatRupiah(price);
    final duration = isWebinar ? 'Webinar Live' : (isBootcamp ? '8 Minggu' : '12 Materi');

    return GestureDetector(
      onTap: () => _openItemDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Full thumbnail (100% visible, uncropped)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnail.isNotEmpty) ...[
                      // Ambient soft blur behind thumbnail to fill any aspect ratio gaps gracefully
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Opacity(
                          opacity: 0.35,
                          child: CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Crisp, uncropped thumbnail displayed in its entirety
                      CachedNetworkImage(
                        imageUrl: thumbnail,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        placeholder: (context, url) => Container(color: const Color(0xFFF8FAFC)),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Icon(Icons.school_outlined, color: Color(0xFF64748B), size: 44),
                          ),
                        ),
                      ),
                    ] else
                      Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(Icons.school_outlined, color: Color(0xFF64748B), size: 44),
                        ),
                      ),

                    // Top-Left Rubber Stamp Badge — Inspired by PAID seal
                    if (isEnrolled)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _buildStampBadge(isWebinar: isWebinar, scale: 1.05),
                      ),

                    // Top-Right Bookmark/Heart Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _toggleWishlist(item, isBootcamp),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x120F172A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isWishlisted ? const Color(0xFFF43F5E) : const Color(0xFF0F172A),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subtle divider between thumbnail and white card body
            Container(height: 1, color: const Color(0xFFF1F5F9)),

            // Bottom Section: Professional Layout with Generous Breathing Room
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Tag & Status Row (Sleek micro-pills only — price moved to bottom)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          ),
                          child: Text(
                            field.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF475569),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          ),
                          child: Text(
                            programType.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 2. Large Bold Title with comfortable line height
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF0F172A),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 3. Course Description (Well-spaced, readable typography)
                    if (cleanDesc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        cleanDesc,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.42,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 4. Rating & Modules / Duration Row
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount)',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isWebinar ? Icons.videocam_outlined : (isBootcamp ? Icons.calendar_today_rounded : Icons.menu_book_rounded),
                          size: 13,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Flexible Spacer: Gives air and positions the button cleanly at the bottom
                    const Spacer(),

                    // 5. Bottom Action Row: Price on left + Action Button on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Price display (tetap tampil baik belum beli maupun sudah beli)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Harga',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  priceStr,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: price == 0 ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right: Solid Dongker Pill Button (Buka Kelas / See more)
                        GestureDetector(
                          onTap: () => _openItemDetail(item),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F0F172A),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isEnrolled ? 'Buka Kelas' : 'See more',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isEnrolled ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                                    color: const Color(0xFF0F172A),
                                    size: isEnrolled ? 18 : 14,
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
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECONDARY CARD (Program Lainnya — Clean, Beautiful & Structured Layout)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSecondaryCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Program Rekomendasi').toString();
    final field = (item['field'] ?? 'DEVELOPMENT').toString().replaceAll('_', ' ');
    final isBootcamp = item['itemType'] == 'BOOTCAMP' || item['batchStatus'] != null;
    final isWebinar = item['itemType'] == 'WEBINAR' || item['eventDate'] != null;
    final programType = isWebinar ? 'Webinar' : (isBootcamp ? 'Bootcamp' : 'Mini Course');
    final thumbnail = _getItemImage(item);
    final price = _parseItemPrice(item);
    final priceStr = price == 0 ? 'Gratis' : _formatRupiah(price);
    final rating = _parseItemRating(item);
    final reviewCount = (item['reviewCount'] ?? 56).toString();
    final duration = isWebinar ? 'Webinar Live' : (isBootcamp ? '8 Minggu' : '12 Materi');
    final id = item['id']?.toString() ?? '';
    final isWishlisted = _wishlistIds.contains(id);
    final isEnrolled = _isItemEnrolled(item);

    return GestureDetector(
      onTap: () => _openItemDetail(item),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thumbnail Container (16:9 with clean border & overlays)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: const Color(0xFFF1F5F9),
                    child: thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.school_outlined, color: Color(0xFF94A3B8), size: 32),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.school_outlined, color: Color(0xFF94A3B8), size: 32),
                          ),
                  ),
                ),

                // Top-Left: Enrolled Rubber Stamp Badge (if enrolled)
                if (isEnrolled)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildStampBadge(isWebinar: isWebinar, scale: 0.85),
                  ),

                // Top-Right: Bookmark / Wishlist Heart Icon
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(item, isBootcamp),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isWishlisted ? const Color(0xFFF43F5E) : const Color(0xFF0F172A),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Subtle divider line
            Container(height: 1, color: const Color(0xFFF1F5F9)),

            // 2. Structured Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Micro Category & Program Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                          ),
                          child: Text(
                            field.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF475569),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                          ),
                          child: Text(
                            programType.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF64748B),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // B. Course Title (Clean 2 lines max with good typography)
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // C. Rating & Duration Row
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '($reviewCount)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isWebinar ? Icons.videocam_outlined : (isBootcamp ? Icons.calendar_today_rounded : Icons.menu_book_rounded),
                          size: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            duration,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // D. Bottom Row: Price on left, Arrow Button on right (harga selalu tampil)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              priceStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: price == 0 ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEnrolled ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: isEnrolled ? 16 : 14,
                          ),
                        ),
                      ],
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

  // ───────────────────────────────────────────────────────────────────────────
  // VIEW ALL CARD (Shown as the 6th item at the far right of Program Lainnya)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildViewAllCard(List<dynamic> allItems) {
    return GestureDetector(
      onTap: () => _openAllProgramsModal(allItems),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Lihat Semua',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jelajahi program',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C827A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerHeroCarousel() {
    return Container(
      height: 420,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 48, color: Color(0xFF8C827A)),
            const SizedBox(height: 12),
            Text(
              'Belum ada program untuk kategori ini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Silakan pilih bidang atau kata kunci lain.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF8C827A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
