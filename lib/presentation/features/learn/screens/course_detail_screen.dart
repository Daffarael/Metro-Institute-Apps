import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/bootcamp_remote_datasource.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import '../../../../data/datasources/remote/wishlist_remote_datasource.dart';
import '../widgets/checkout_bottom_sheet.dart';
import 'video_player_screen.dart';

/// CourseDetailScreen — Displays the course/bootcamp detail page with the elegant Warm Cream UI:
/// • Warm Cream background (Color(0xFFFAF7F2)) with pristine white/cream capsule cards.
/// • Top: Immersive Hero / Video Player container with rounded bottom corners (32px).
/// • Thumbnail fills the video card completely (fit: BoxFit.cover, no shrinking or letterboxing).
/// • Tapping Play immediately starts video playback right inside the card (native or web embed).
/// • Floating Frosted Glass Control Pill: 1x speed cycler, seekbar slider, and Fullscreen toggle.
/// • Overlaid Top Bar: Translucent Back (←) and Wishlist (🔖) buttons.
/// • 100% Dynamic: Titles, descriptions, mentors, ratings, chapters, sessions, and durations from API.
class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isBootcamp;

  const CourseDetailScreen({
    super.key,
    required this.item,
    this.isBootcamp = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// SCOOPED NOTCH CARD DECORATION & PAINTER (Floating Card with Ambient Shadow)
// ─────────────────────────────────────────────────────────────────────────────
class ScoopedCardDecoration extends StatelessWidget {
  final Widget child;

  const ScoopedCardDecoration({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScoopedCardPainter(),
      child: child,
    );
  }
}

Path _buildScoopedCardPath(Size size) {
  final w = size.width;
  final h = size.height;
  const r = 28.0;
  const nw = 78.0;
  const nd = 15.0;
  const sr = 14.0;
  final cx = w / 2;
  final effectiveH = h < (2 * r) ? (2 * r) : h;

  final path = Path()
    ..moveTo(0, r)
    ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
    ..lineTo(cx - nw / 2 - sr, 0)
    ..cubicTo(
      cx - nw / 2, 0,
      cx - nw / 2, nd,
      cx - nw / 2 + sr, nd,
    )
    ..lineTo(cx + nw / 2 - sr, nd)
    ..cubicTo(
      cx + nw / 2, nd,
      cx + nw / 2, 0,
      cx + nw / 2 + sr, 0,
    )
    ..lineTo(w - r, 0)
    ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
    ..lineTo(w, effectiveH - r)
    ..arcToPoint(Offset(w - r, effectiveH), radius: const Radius.circular(r))
    ..lineTo(r, effectiveH)
    ..arcToPoint(Offset(0, effectiveH - r), radius: const Radius.circular(r))
    ..close();

  return path;
}

class _ScoopedCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildScoopedCardPath(size);

    // 1. Ambient & Elevated Floating Shadows (Lifts card off background)
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.10), 16.0, false);
    canvas.drawShadow(path, const Color(0x18000000), 6.0, true);

    // 2. Crisp White Fill
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Subtle Elegant Border
    final borderPaint = Paint()
      ..color = const Color(0xFFEBE6DF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Exact organic bipartite capsule clipper with smooth hourglass waist pinch
class _BipartiteWaistClipper extends CustomClipper<Path> {
  const _BipartiteWaistClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = h / 2;
    final cx = w / 2;
    const ww = 40.0;
    const wd = 7.5;

    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(cx - ww / 2, 0);
    path.cubicTo(cx - ww / 4, 0, cx - ww / 4, wd, cx, wd);
    path.cubicTo(cx + ww / 4, wd, cx + ww / 4, 0, cx + ww / 2, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    path.lineTo(cx + ww / 2, h);
    path.cubicTo(cx + ww / 4, h, cx + ww / 4, h - wd, cx, h - wd);
    path.cubicTo(cx - ww / 4, h - wd, cx - ww / 4, h, cx - ww / 2, h);
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, r), radius: Radius.circular(r));
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseRemoteDataSource _courseDs = sl<CourseRemoteDataSource>();
  final BootcampRemoteDataSource _bootcampDs = sl<BootcampRemoteDataSource>();
  final WishlistRemoteDataSource _wishlistDs = sl<WishlistRemoteDataSource>();

  bool _isLoading = true;
  bool _isBootcampActual = false;
  Map<String, dynamic>? _detail;
  bool _isWishlisted = false;

  // Active Session for Video Player
  Map<String, dynamic>? _activeSession;

  // Selected Tab: 0 = Deskripsi (kiri), 1 = Silabus (kanan)
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _isBootcampActual = widget.isBootcamp ||
        widget.item['isBootcamp'] == true ||
        widget.item['type'] == 'bootcamp' ||
        widget.item['productType'] == 'BOOTCAMP';
    _isWishlisted = widget.item['isWishlisted'] == true;
    _fetchDetail();
  }

  @override
  void dispose() {
    // Always restore portrait mode when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final id = widget.item['id']?.toString() ?? '';
    try {
      Map<String, dynamic> res;
      if (widget.isBootcamp) {
        try {
          res = await _bootcampDs.getBootcampDetail(id);
        } catch (_) {
          res = await _courseDs.getCourseDetail(id);
        }
      } else {
        try {
          res = await _courseDs.getCourseDetail(id);
        } catch (_) {
          res = await _bootcampDs.getBootcampDetail(id);
        }
      }

      // If item was already marked as enrolled (e.g. from Basecamp Active Courses / My Courses), preserve it!
      if (widget.item['isEnrolled'] == true) {
        res['isEnrolled'] = true;
      }

      if (!mounted) return;
      setState(() {
        _detail = res;
        _isBootcampActual = res['field'] != null ||
            res['isBootcamp'] == true ||
            res['type'] == 'BOOTCAMP' ||
            _isBootcampActual;
        _isLoading = false;
        if (res.containsKey('isWishlisted')) {
          _isWishlisted = res['isWishlisted'] == true;
        }
      });

      _selectInitialSession(res);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _selectInitialSession(widget.item);
    }
  }

  void _selectInitialSession(Map<String, dynamic> data) {
    final chapters = (data['chapters'] as List?) ?? [];
    Map<String, dynamic>? foundSession;
    Map<String, dynamic>? firstUncompleted;

    for (final ch in chapters) {
      final sessions = (ch['sessions'] as List?) ?? [];
      for (final s in sessions) {
        if (s is Map<String, dynamic>) {
          foundSession ??= s;
          if (s['isCompleted'] != true && firstUncompleted == null) {
            firstUncompleted = s;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _activeSession = firstUncompleted ?? foundSession;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    final courseId = !widget.isBootcamp ? widget.item['id']?.toString() : null;
    final bootcampId = widget.isBootcamp ? widget.item['id']?.toString() : null;
    final nextState = !_isWishlisted;

    setState(() => _isWishlisted = nextState);

    try {
      if (nextState) {
        await _wishlistDs.addToWishlist(courseId: courseId, bootcampId: bootcampId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disimpan ke Wishlist'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await _wishlistDs.removeFromWishlist(courseId: courseId, bootcampId: bootcampId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dihapus dari Wishlist'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isWishlisted = !nextState);
    }
  }

  void _openCheckout(int price) {
    debugPrint('=== [METRO_CHECKOUT] _openCheckout dipanggil dengan price: $price ===');
    try {
      final actualIsBootcamp = _detail?['isBootcamp'] == true ||
          widget.isBootcamp ||
          _detail?['type']?.toString().toLowerCase() == 'bootcamp' ||
          widget.item['type']?.toString().toLowerCase() == 'bootcamp' ||
          _detail?.containsKey('cohort') == true ||
          _detail?.containsKey('batch') == true;

      final title = (_detail?['title'] ?? widget.item['title'])?.toString() ?? 'Kelas Metro';
      final id = (_detail?['id'] ??
              _detail?['courseId'] ??
              _detail?['bootcampId'] ??
              widget.item['id'] ??
              widget.item['courseId'] ??
              widget.item['bootcampId'])
          ?.toString() ?? '';

      final rawThumb = (_detail?['bannerUrl'] ??
              _detail?['thumbnailUrl'] ??
              _detail?['thumbnail'] ??
              widget.item['bannerUrl'] ??
              widget.item['thumbnailUrl'] ??
              widget.item['thumbnail'] ??
              '')
          .toString();

      String? mentorName;
      final instr = _detail?['instructor'] ?? widget.item['instructor'];
      if (instr is Map) {
        mentorName = instr['name']?.toString();
      } else if (instr is String && instr.isNotEmpty) {
        mentorName = instr;
      }
      mentorName ??= (_detail?['mentorName'] ?? widget.item['mentorName'])?.toString();

      debugPrint('=== [METRO_CHECKOUT] Membuka modal CheckoutBottomSheet: id: $id, title: $title, type: ${actualIsBootcamp ? 'BOOTCAMP' : 'MINI_COURSE'} ===');

      CheckoutBottomSheet.show(
        context,
        title: title,
        price: price,
        productType: actualIsBootcamp ? 'BOOTCAMP' : 'MINI_COURSE',
        productId: id,
        thumbnailUrl: rawThumb,
        subtitle: mentorName != null ? 'Mentor: $mentorName' : null,
        onSuccess: () {
          if (mounted) {
            setState(() {
              if (_detail != null) {
                _detail!['isEnrolled'] = true;
              }
              widget.item['isEnrolled'] = true;
            });
          }
          // Re-fetch detail to refresh isEnrolled status to true!
          _fetchDetail();
        },
        onStartLearning: () {
          if (mounted) {
            setState(() {
              if (_detail != null) {
                _detail!['isEnrolled'] = true;
              }
              widget.item['isEnrolled'] = true;
            });
            // Segera buka pembelajaran sesi aktif
            _openLearningPlayer();
          }
        },
      );
    } catch (e, stack) {
      debugPrint('Error in _openCheckout: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka checkout: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _promptUnlockCourse(int price) {
    // Langsung buka CheckoutBottomSheet (Dialog) tanpa perantara showModalBottomSheet
    // yang bisa menyebabkan RenderBox crash / layar gelap kosong
    debugPrint('=== [METRO_CHECKOUT] _promptUnlockCourse -> langsung ke _openCheckout ===');
    _openCheckout(price);
  }

  void _openLearningPlayer([Map<String, dynamic>? session]) {
    final courseId = widget.item['id']?.toString() ?? '';
    final courseTitle = (_detail?['title'] ?? widget.item['title']) as String? ?? 'Kelas Metro';

    Map<String, dynamic>? targetSession = session ?? _activeSession;
    if (targetSession == null) {
      final chapters = ((_detail?['chapters'] ?? widget.item['chapters']) as List?) ?? [];
      for (final ch in chapters) {
        final sessions = (ch['sessions'] as List?) ?? [];
        if (sessions.isNotEmpty) {
          targetSession = sessions.first as Map<String, dynamic>;
          break;
        }
      }
    }

    if (targetSession != null && targetSession['id'] != null) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            sessionId: targetSession!['id'].toString(),
            title: targetSession['title']?.toString() ?? 'Sesi Belajar',
            courseTitle: courseTitle,
            videoUrl: targetSession['videoUrl']?.toString(),
            courseId: courseId,
            isBootcamp: _isBootcampActual,
            sessionType: targetSession['type']?.toString(),
            onCompleted: () => _fetchDetail(),
          ),
        ),
      ).then((_) {
        _fetchDetail();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi sesi sedang dipersiapkan oleh mentor.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _detail == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: _buildPortraitContent(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PORTRAIT CONTENT (Warm Cream UI with Full-Width Thumbnail Card)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPortraitContent() {
    final title = (_detail?['title'] ?? widget.item['title']) as String? ?? 'Detail Kelas';
    final rawDesc = _detail?['description'] ?? _detail?['shortDescription'] ?? widget.item['description'] ?? widget.item['shortDescription'] ?? '';
    final description = rawDesc.toString().trim().isNotEmpty
        ? rawDesc.toString().trim()
        : 'Pelajari kurikulum terstruktur dengan panduan praktis dan materi berkualitas tinggi.';
    final rawThumb = (_detail?['bannerUrl'] ??
            _detail?['thumbnailUrl'] ??
            _detail?['thumbnail'] ??
            _detail?['banner'] ??
            widget.item['bannerUrl'] ??
            widget.item['thumbnailUrl'] ??
            widget.item['thumbnail'] ??
            widget.item['banner']) as String? ??
        '';
    final thumbnail = rawThumb.startsWith('http://') || rawThumb.startsWith('https://')
        ? rawThumb
        : (rawThumb.startsWith('/') ? 'https://api.metroinstitute.site$rawThumb' : (rawThumb.isNotEmpty ? 'https://$rawThumb' : ''));
    final mentorName = (_detail?['instructor']?['name'] ?? _detail?['mentorName'] ?? widget.item['instructor']?['name'] ?? widget.item['mentorName']) as String? ?? 'Mentor Metro';
    final mentorPhoto = (_detail?['instructor']?['avatar'] ?? _detail?['mentorPhotoUrl'] ?? widget.item['instructor']?['avatar'] ?? widget.item['mentorPhotoUrl']) as String? ?? '';
    final rating = ((_detail?['rating'] ?? widget.item['rating']) as num?)?.toDouble() ?? 0.0;
    final price = ((_detail?['price'] ?? widget.item['price']) as num?)?.toInt() ?? 0;
    final priceStr = price == 0 ? 'GRATIS' : 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    final isEnrolled = _detail?['isEnrolled'] == true || widget.item['isEnrolled'] == true;

    final chapters = ((_detail?['chapters'] ?? widget.item['chapters']) as List?) ?? [];
    int totalLessons = 0;
    int totalSec = 0;
    for (final ch in chapters) {
      final sList = (ch['sessions'] as List?) ?? [];
      totalLessons += sList.length;
      for (final s in sList) {
        if (s is Map) {
          final sec = s['videoDuration'];
          if (sec is num) totalSec += sec.toInt();
        }
      }
    }
    if (totalLessons == 0) totalLessons = chapters.isNotEmpty ? chapters.length : 1;

    String timeDisplay = '';
    final rawDuration = _detail?['duration'] ?? widget.item['duration'];
    if (rawDuration != null && rawDuration.toString().trim().isNotEmpty) {
      timeDisplay = rawDuration.toString().trim();
    } else if (totalSec > 0) {
      if (totalSec >= 3600) {
        final hours = totalSec / 3600;
        timeDisplay = hours >= 10
            ? '${hours.round()}h'
            : '${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)}h';
      } else {
        timeDisplay = '${(totalSec / 60).round()}m';
      }
    } else {
      final estMinutes = totalLessons * 15;
      if (estMinutes >= 60) {
        final h = estMinutes / 60;
        timeDisplay = '${h.toStringAsFixed(h.truncateToDouble() == h ? 0 : 1)}h';
      } else {
        timeDisplay = '${estMinutes}m';
      }
    }
    final lessonsDisplay = '$totalLessons';

    // Exact 16:9 video container size (matches thumbnail size)
    final screenWidth = MediaQuery.of(context).size.width;
    final videoHeight = screenWidth * (9 / 16);
    final mediaHeight = videoHeight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Stack(
        children: [
          // ── Main Scroll View ─────────────────────────────────────────────────
          SafeArea(
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP VIDEO CONTAINER with rounded bottom corners (Thumbnail fills card completely)
                  _buildTopThumbnail(mediaHeight, thumbnail),

                  // 2. STATS CAPSULE CARD (Floating Bridge: Time & Lessons)
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatsCard(
                        timeDisplay,
                        lessonsDisplay,
                        onTapLessons: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ),

                  // 3. FLOATING WHITE CONTENT CARD WITH SIGNATURE SCOOPED NOTCH HANDLE & LESSONS
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ScoopedCardDecoration(
                        child: Container(
                          width: double.infinity,
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── TOP HANDLE NOTCH (Elevated / Floating above the scooped dip) ──
                              Center(
                                child: Transform.translate(
                                  offset: const Offset(0, -9),
                                  child: Container(
                                    width: 58,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE8E3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE2DDD6),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 24,
                                      height: 3.5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F4D50),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // ── COURSE TITLE ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                                child: Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF1E1B18),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    height: 1.25,
                                  ),
                                ),
                              ),

                              // ── SEGMENTED TAB BAR ("Description" vs "Lessons") ──
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: _buildSegmentedTabBar(),
                              ),
                              const SizedBox(height: 20),

                              // ── TAB CONTENT: Description vs Lessons ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                                child: _selectedTab == 0
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Description text
                                          Text(
                                            description,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: const Color(0xFF6B655F),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              height: 1.6,
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Mentor & Rating Row
                                          _buildMentorAndRatingRow(mentorName, mentorPhoto, rating),
                                          const SizedBox(height: 24),

                                          // Course Benefits / Highlights Card
                                          _buildCourseHighlightsCard(),
                                        ],
                                      )
                                    : _buildLessonsList(chapters, isEnrolled, price),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── STICKY BOTTOM BAR (Action CTA) ───────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyBottomBar(priceStr, price, isEnrolled, chapters),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TOP HERO THUMBNAIL (Exact 16:9 thumbnail size, with signature bottom curve)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopThumbnail(double height, String thumbnail) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF143E26),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 0: CRISP 16:9 BANNER / THUMBNAIL (100% full-bleed, bottom corners clipped by curve) ──
          Positioned.fill(
            child: thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) => Container(color: const Color(0xFF143E26)),
                    errorWidget: (context, url, error) => Container(color: const Color(0xFF143E26)),
                  )
                : Container(
                    color: const Color(0xFF143E26),
                  ),
          ),

          // ── LAYER 1: CINEMATIC TOP GRADIENT VIGNETTE (For top navigation buttons contrast) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 52,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x88000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── LAYER 2: TOP NAVIGATION BAR (Back, Transactions, Bookmark) ──
          Positioned(
            top: 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 19),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Riwayat Transaksi button
                    InkWell(
                      onTap: () => context.push(AppRoutes.transactions),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Bookmark / Wishlist button
                    InkWell(
                      onTap: _toggleWishlist,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Icon(
                          _isWishlisted ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                          color: _isWishlisted ? const Color(0xFFFBBF24) : Colors.white,
                          size: 19,
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

  // ───────────────────────────────────────────────────────────────────────────
  // SEGMENTED TAB BAR (Deskripsi vs Silabus, Organic Bipartite Capsule)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabBar() {
    const tabHeight = 48.0;

    return SizedBox(
      height: tabHeight,
      child: ClipPath(
        clipper: const _BipartiteWaistClipper(),
        child: Stack(
          children: [
            // Base background: Soft warm grey
            Positioned.fill(
              child: Container(
                color: const Color(0xFFEBE7E1),
              ),
            ),

            // Sliding Active Pill: Metro Green
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              alignment: _selectedTab == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.52,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),

            // Interactive Tab Labels: "Deskripsi" vs "Silabus"
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTab != 0) setState(() => _selectedTab = 0);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _selectedTab == 0
                                ? Colors.white
                                : const Color(0xFF1E1B18),
                            letterSpacing: -0.2,
                          ),
                          child: const Text('Deskripsi'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTab != 1) setState(() => _selectedTab = 1);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _selectedTab == 1
                                ? Colors.white
                                : const Color(0xFF1E1B18),
                            letterSpacing: -0.2,
                          ),
                          child: const Text('Silabus'),
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COURSE HIGHLIGHTS / BENEFITS (Shown inside Description Tab)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCourseHighlightsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBE6DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keunggulan Program',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B18),
            ),
          ),
          const SizedBox(height: 14),
          _buildHighlightItem(Icons.all_inclusive_rounded, 'Akses materi selamanya tanpa batas'),
          const SizedBox(height: 10),
          _buildHighlightItem(Icons.verified_rounded, 'Sertifikat resmi kelulusan Metro Institute'),
          const SizedBox(height: 10),
          _buildHighlightItem(Icons.forum_rounded, 'Grup diskusi komunitas belajar & mentoring'),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF143E26), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A453E),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATS CAPSULE CARD (Time & Lessons from reference design)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStatsCard(String timeStr, String lessonsStr, {VoidCallback? onTapLessons}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEBE6DF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── LEFT: TIME ─────────────────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/ic_time_alarm.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.alarm_rounded, color: Color(0xFF2E7D32), size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Durasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B655F),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1B18),
                          letterSpacing: -0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── VERTICAL DIVIDER ───────────────────────────────────────────────
          Container(
            width: 1,
            height: 44,
            color: const Color(0xFFEFECE6),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          // ── RIGHT: LESSONS ──────────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onTapLessons,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Image.asset(
                  'assets/icons/ic_lessons_book.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFE65100), size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Materi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B655F),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lessonsStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1B18),
                          letterSpacing: -0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  // ───────────────────────────────────────────────────────────────────────────
  // 2. MENTOR & RATING ROW (Cream UI)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMentorAndRatingRow(String mentorName, String mentorPhoto, double rating) {
    return Row(
      children: [
        // Avatar with gradient border ring matching screenshot
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFF43F5E), Color(0xFF8B5CF6), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(2.2),
          child: ClipOval(
            child: mentorPhoto.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: mentorPhoto,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: const Color(0xFFEADBCE)),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFEADBCE),
                      child: const Icon(Icons.person, color: Color(0xFF8C827A), size: 24),
                    ),
                  )
                : Container(
                    color: const Color(0xFFEADBCE),
                    child: const Icon(Icons.person, color: Color(0xFF8C827A), size: 24),
                  ),
          ),
        ),
        const SizedBox(width: 14),

        // Mentor label & name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8C827A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mentorName,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E1B18),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Rating with yellow star (only if rating > 0)
        if (rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E1B18),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ],
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ───────────────────────────────────────────────────────────────────────────
  // LESSONS LIST & SQUIRCLE STAR CARDS (Matches reference design 100%)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLessonsList(List chapters, bool isEnrolled, int price) {
    // If chapters is empty, provide fallback lessons matching reference design
    final effectiveChapters = chapters.isNotEmpty
        ? chapters
        : [
            {
              'title': 'Chapter 1',
              'sessions': [
                {
                  'id': 'fallback_1',
                  'title': 'Introduction to UI/UX',
                  'type': 'VIDEO',
                  'isFreePreview': true,
                },
                {
                  'id': 'fallback_2',
                  'title': 'Materi Pengenalan UI/UX',
                  'type': 'ARTICLE',
                  'isFreePreview': false,
                },
                {
                  'id': 'fallback_3',
                  'title': 'Kuis Pengenalan UI/UX',
                  'type': 'QUIZ',
                  'isFreePreview': false,
                },
              ]
            }
          ];

    int globalIndex = 0;
    final List<Widget> items = [];

    for (int chIndex = 0; chIndex < effectiveChapters.length; chIndex++) {
      final chapter = effectiveChapters[chIndex] as Map<String, dynamic>;
      final sessions = (chapter['sessions'] as List?) ?? [];

      for (int sIndex = 0; sIndex < sessions.length; sIndex++) {
        final session = sessions[sIndex] as Map<String, dynamic>;
        final currentIndex = globalIndex++;
        items.add(
          _buildLessonCard(
            globalIndex: currentIndex,
            session: session,
            isEnrolled: isEnrolled,
            price: price,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  IconData _getSessionTypeIcon(String title, Map<String, dynamic> session) {
    final rawType = (session['type'] ?? session['sessionType'] ?? '').toString().toUpperCase();
    final lowerTitle = title.toLowerCase();

    if (rawType.contains('QUIZ') || lowerTitle.contains('kuis') || lowerTitle.contains('quiz')) {
      return Icons.quiz_outlined;
    } else if (rawType.contains('LIVE') || lowerTitle.contains('live') || lowerTitle.contains('webinar')) {
      return Icons.videocam_rounded;
    } else if (rawType.contains('ARTICLE') ||
        rawType.contains('READ') ||
        lowerTitle.contains('materi') ||
        lowerTitle.contains('bacaan') ||
        lowerTitle.contains('modul') ||
        lowerTitle.contains('pdf') ||
        lowerTitle.contains('artikel') ||
        lowerTitle.contains('panduan')) {
      return Icons.menu_book_rounded;
    } else if (rawType.contains('TASK') ||
        rawType.contains('PROJECT') ||
        lowerTitle.contains('tugas') ||
        lowerTitle.contains('praktik')) {
      return Icons.assignment_rounded;
    } else {
      // Default: Video lesson icon
      return Icons.play_arrow_rounded;
    }
  }

  Widget _buildLessonCard({
    required int globalIndex,
    required Map<String, dynamic> session,
    required bool isEnrolled,
    required int price,
  }) {
    final sessionTitle = (session['title'] as String?)?.trim().isNotEmpty == true
        ? session['title'] as String
        : (globalIndex == 0
            ? 'Introduction to UI/UX'
            : (globalIndex == 1 ? 'Materi Pengenalan UI/UX' : 'Kuis Pengenalan UI/UX'));
    final isFree = session['isFreePreview'] == true;
    final canPlay = isEnrolled || isFree;
    final isLocked = !canPlay;
    final isCurrentSession = _activeSession?['id']?.toString() == session['id']?.toString();
    final iconData = _getSessionTypeIcon(sessionTitle, session);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isCurrentSession ? AppColors.primary : const Color(0xFFECE7E1),
          width: isCurrentSession ? 1.6 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: () {
            if (canPlay) {
              _openLearningPlayer(session);
            } else {
              _promptUnlockCourse(price);
            }
          },
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // 1. Sleek Neutral Grey Box with Lesson Type Icon (not colored)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFEA), // Sleek neutral soft grey
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    iconData,
                    color: const Color(0xFF5A524C), // Clean neutral grey/charcoal
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Title and Bold "+20 points" Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sessionTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B18),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '+20 points',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B18),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF143E26),
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. STICKY BOTTOM BAR (Cream UI Price & CTA)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStickyBottomBar(String priceStr, int price, bool isEnrolled, List chapters) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        border: Border(top: BorderSide(color: Color(0xFFEADBCE), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEnrolled ? 'Status Akses' : 'Investasi Belajar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C827A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnrolled ? 'Terdaftar' : priceStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('=== [METRO_CHECKOUT] Tombol Beli Sekarang diklik! price: $price, isEnrolled: $isEnrolled ===');
                      if (isEnrolled) {
                        _openLearningPlayer();
                      } else {
                        _openCheckout(price);
                      }
                    },
                    icon: Icon(
                      isEnrolled
                          ? Icons.arrow_forward_rounded
                          : (price == 0 ? Icons.how_to_reg_rounded : Icons.shopping_bag_outlined),
                      size: 20,
                    ),
                    label: Text(
                      isEnrolled
                          ? 'Lanjutkan Belajar'
                          : (price == 0 ? 'Daftar Sekarang' : 'Beli Sekarang'),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
