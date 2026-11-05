import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/bootcamp_remote_datasource.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import '../../../../data/datasources/remote/wishlist_remote_datasource.dart';
import '../widgets/chapter_activity_dropdown.dart';
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

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseRemoteDataSource _courseDs = sl<CourseRemoteDataSource>();
  final BootcampRemoteDataSource _bootcampDs = sl<BootcampRemoteDataSource>();
  final WishlistRemoteDataSource _wishlistDs = sl<WishlistRemoteDataSource>();

  bool _isLoading = true;
  Map<String, dynamic>? _detail;
  bool _isWishlisted = false;

  // Active Session for Video Player
  Map<String, dynamic>? _activeSession;

  // Video Controller State
  VideoPlayerController? _videoController;
  WebViewController? _webViewController;
  bool _isWebEmbed = false;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  // Selected Tab: 0 = Description, 1 = Lessons
  int _selectedTab = 0;

  // Track expanded chapters
  final Set<int> _expandedChapters = {0};
  // Chapter GlobalKeys for auto-scroll and focus
  final Map<int, GlobalKey> _chapterKeys = {};

  // Fullscreen Landscape Controls
  bool _showLandscapeControls = true;
  Timer? _controlsTimer;

  // Playback speeds list
  static const List<double> _availableSpeeds = [1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _isWishlisted = widget.item['isWishlisted'] == true;
    _fetchDetailAndInitVideo();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _disposeVideo();
    // Always restore portrait mode when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _videoController = null;
    _webViewController = null;
    _isVideoInitialized = false;
    _isPlaying = false;
  }

  Future<void> _fetchDetailAndInitVideo() async {
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

    for (final ch in chapters) {
      final sessions = (ch['sessions'] as List?) ?? [];
      for (final s in sessions) {
        if (s is Map<String, dynamic>) {
          if (s['videoUrl'] != null && s['videoUrl'].toString().trim().isNotEmpty) {
            foundSession = s;
            break;
          }
          foundSession ??= s;
        }
      }
      if (foundSession != null && foundSession['videoUrl'] != null) break;
    }

    if (foundSession != null) {
      _activeSession = foundSession;
      final isEnrolled = _detail?['isEnrolled'] == true || widget.item['isEnrolled'] == true;
      if (isEnrolled || foundSession['isFreePreview'] == true) {
        // Pre-initialize controller without playing until user clicks Play
        _loadSessionVideo(foundSession, autoPlay: false);
      }
    }
  }

  void _loadSessionVideo(Map<String, dynamic> session, {bool autoPlay = false}) {
    _activeSession = session;
    final rawUrl = session['videoUrl']?.toString() ?? '';

    if (rawUrl.isEmpty) {
      _disposeVideo();
      if (mounted) setState(() {});
      return;
    }

    final lower = rawUrl.toLowerCase();
    final isEmbed = lower.contains('iframe.mediadelivery.net') ||
        lower.contains('b-cdn.net') ||
        lower.contains('bunnycdn') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be');

    if (isEmbed) {
      _initWebEmbed(rawUrl, autoPlay: autoPlay);
    } else {
      _initNativeVideo(rawUrl, autoPlay: autoPlay);
    }
  }

  void _initWebEmbed(String rawUrl, {bool autoPlay = false}) {
    _disposeVideo();
    _isWebEmbed = true;

    String embedUrl = rawUrl;
    if (autoPlay && !embedUrl.contains('autoplay=')) {
      embedUrl = '$embedUrl${embedUrl.contains('?') ? '&' : '?'}autoplay=true';
    }

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; }
    html, body {
      margin: 0; padding: 0; width: 100%; height: 100%;
      background: #000000; overflow: hidden;
      display: flex; align-items: center; justify-content: center;
    }
    iframe { width: 100%; height: 100%; border: none; display: block; }
  </style>
</head>
<body>
  <iframe id="videoFrame" src="$embedUrl" allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;" allowfullscreen></iframe>
</body>
</html>
''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    // Direct embed loading for BunnyCDN / mediadelivery
    if (rawUrl.contains('iframe.mediadelivery.net') || rawUrl.contains('b-cdn.net')) {
      controller.loadRequest(Uri.parse(embedUrl));
    } else {
      controller.loadHtmlString(htmlContent, baseUrl: 'https://iframe.mediadelivery.net');
    }

    if (mounted) {
      setState(() {
        _webViewController = controller;
        _isVideoInitialized = true;
        _isPlaying = autoPlay;
      });
    }
  }

  Future<void> _initNativeVideo(String url, {bool autoPlay = false}) async {
    _disposeVideo();
    _isWebEmbed = false;

    try {
      final uri = Uri.parse(url);
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      controller.addListener(_videoListener);
      await controller.setPlaybackSpeed(_playbackSpeed);

      if (autoPlay) {
        await controller.play();
      }

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _isVideoInitialized = true;
        _isPlaying = autoPlay;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_videoController == null) return;
    final isPlaying = _videoController!.value.isPlaying;
    if (mounted) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }
  }

  void _cyclePlaybackSpeed() {
    final nextIdx = (_availableSpeeds.indexOf(_playbackSpeed) + 1) % _availableSpeeds.length;
    final newSpeed = _availableSpeeds[nextIdx];
    setState(() => _playbackSpeed = newSpeed);
    _videoController?.setPlaybackSpeed(newSpeed);
  }

  // ── Start Playing directly in player ───────────────────────────────────────
  void _startPlaying() {
    setState(() => _isPlaying = true);

    if (_activeSession != null) {
      _loadSessionVideo(_activeSession!, autoPlay: true);
    } else {
      // Find first available session
      final chapters = ((_detail?['chapters'] ?? widget.item['chapters']) as List?) ?? [];
      for (final ch in chapters) {
        final sessions = (ch['sessions'] as List?) ?? [];
        if (sessions.isNotEmpty) {
          _loadSessionVideo(sessions.first as Map<String, dynamic>, autoPlay: true);
          return;
        }
      }
      _videoController?.play();
    }
  }

  // ── Auto Landscape Trigger ─────────────────────────────────────────────────
  Future<void> _playAndEnterLandscape() async {
    if (!_isPlaying) {
      _startPlaying();
    }

    // Switch to Landscape
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _resetControlsTimer();
    if (mounted) setState(() {});
  }

  Future<void> _exitLandscape() async {
    // Restore Portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) setState(() {});
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    setState(() => _showLandscapeControls = true);
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showLandscapeControls = false);
      }
    });
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
    final title = (_detail?['title'] ?? widget.item['title']) as String? ?? 'Kelas Metro';
    final id = widget.item['id']?.toString() ?? '';
    final rawThumb = (_detail?['bannerUrl'] ??
            _detail?['thumbnailUrl'] ??
            widget.item['bannerUrl'] ??
            widget.item['thumbnailUrl'] ??
            '') as String;
    final mentorName = (_detail?['instructor']?['name'] ??
            _detail?['mentorName'] ??
            widget.item['instructor']?['name'] ??
            widget.item['mentorName']) as String?;

    CheckoutBottomSheet.show(
      context,
      title: title,
      price: price,
      productType: widget.isBootcamp ? 'BOOTCAMP' : 'MINI_COURSE',
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
        _fetchDetailAndInitVideo();
      },
      onStartLearning: () {
        if (mounted) {
          setState(() {
            if (_detail != null) {
              _detail!['isEnrolled'] = true;
            }
            widget.item['isEnrolled'] = true;
          });
          // Segera putar materi / video sesi pertama
          _startPlaying();
        }
      },
    );
  }

  void _promptUnlockCourse(int price) {
    final priceStr = price == 0
        ? 'Gratis'
        : 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag indicator handle
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 22),

            // Lock Icon with premium gold / emerald container
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFEF3C7), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12D97706),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFD97706),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Materi Ini Terkunci',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Sesi ini adalah materi premium. Beli kelas untuk membuka seluruh video pembelajaran, kuis evaluasi, studi kasus, serta sertifikat resmi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Benefit Checklist (Metro Institute Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                children: [
                  _buildLockPerkRow(Icons.play_circle_outline_rounded, 'Akses penuh ke semua video & modul praktikum'),
                  const SizedBox(height: 10),
                  _buildLockPerkRow(Icons.quiz_outlined, 'Latihan kuis interaktif & studi kasus terstruktur'),
                  const SizedBox(height: 10),
                  _buildLockPerkRow(Icons.verified_outlined, 'Sertifikat resmi kelulusan Metro Institute'),
                  const SizedBox(height: 10),
                  _buildLockPerkRow(Icons.forum_outlined, 'Akses jaringan komunitas & diskusi Discord'),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Primary CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openCheckout(price);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00584B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      price > 0 ? 'Beli Kelas Sekarang • $priceStr' : 'Ambil Kelas Sekarang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary dismiss button
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Nanti Dulu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockPerkRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF00584B),
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
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
            isBootcamp: widget.isBootcamp,
            onCompleted: () => _fetchDetailAndInitVideo(),
          ),
        ),
      );
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isLoading && _detail == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E1B18)),
        ),
      );
    }

    return PopScope(
      canPop: !isLandscape,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isLandscape) {
          _exitLandscape();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        body: isLandscape ? _buildLandscapePlayer() : _buildPortraitContent(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LANDSCAPE FULLSCREEN PLAYER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLandscapePlayer() {
    final title = _activeSession?['title'] as String? ?? widget.item['title'] as String? ?? 'Video Pembelajaran';
    final courseTitle = widget.item['title'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        if (_showLandscapeControls) {
          setState(() => _showLandscapeControls = false);
          _controlsTimer?.cancel();
        } else {
          _resetControlsTimer();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Layer
          if (_isWebEmbed && _webViewController != null)
            WebViewWidget(controller: _webViewController!)
          else if (_isVideoInitialized && _videoController != null && _videoController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Landscape Controls Overlay
          if (_showLandscapeControls) ...[
            // Top Bar Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 28),
                        onPressed: _exitLandscape,
                        tooltip: 'Kembali ke Potret',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (courseTitle.isNotEmpty)
                              Text(
                                courseTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 12,
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
            ),

            // Center Play / Pause & Seek Overlay (Native Player)
            if (!_isWebEmbed && _isVideoInitialized && _videoController != null && _videoController!.value.isInitialized)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 42,
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                      onPressed: () {
                        _resetControlsTimer();
                        final pos = _videoController!.value.position;
                        _videoController!.seekTo(pos - const Duration(seconds: 10));
                      },
                    ),
                    const SizedBox(width: 32),
                    GestureDetector(
                      onTap: () {
                        _resetControlsTimer();
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      iconSize: 42,
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                      onPressed: () {
                        _resetControlsTimer();
                        final pos = _videoController!.value.position;
                        _videoController!.seekTo(pos + const Duration(seconds: 10));
                      },
                    ),
                  ],
                ),
              ),

            // Bottom Progress Bar (for native player)
            if (!_isWebEmbed && _isVideoInitialized && _videoController != null && _videoController!.value.isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(_videoController!.value.position),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white30,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              trackHeight: 3.5,
                            ),
                            child: Slider(
                              value: _videoController!.value.position.inMilliseconds
                                  .clamp(0, _videoController!.value.duration.inMilliseconds)
                                  .toDouble(),
                              max: _videoController!.value.duration.inMilliseconds.toDouble(),
                              onChanged: (val) {
                                _resetControlsTimer();
                                _videoController!.seekTo(Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(_videoController!.value.duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 24),
                          onPressed: _exitLandscape,
                          tooltip: 'Keluar Layar Penuh',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
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
    final rating = ((_detail?['rating'] ?? widget.item['rating']) as num?)?.toDouble() ?? 5.0;
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
                  _buildTopVideoPlayer(mediaHeight, thumbnail, isEnrolled, price),

                  // 2. STATS CAPSULE CARD (Floating Bridge: Time & Lessons - Kept exactly as earlier)
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildStatsCard(
                        timeDisplay,
                        lessonsDisplay,
                        onTapLessons: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ),

                  // 3. WHITE CONTENT SHEET WITH TOP NOTCH HANDLE, TITLE, TABS & LESSONS
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TOP HANDLE NOTCH (Capsule pill with dark center bar) ──
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 14, bottom: 8),
                              width: 62,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE8E3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 28,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F4D50),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),

                          // ── TITLE ROW ("Literature" -> Title + Calendar Icon Button) ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
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
                                const SizedBox(width: 14),
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Jadwal belajar fleksibel, dapat diakses kapan saja!',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        backgroundColor: const Color(0xFF1E1B18),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF3EFEA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_outlined,
                                      color: Color(0xFF1E1B18),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── SEGMENTED TAB BAR ("Description" vs "Lessons") ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSegmentedTabBar(),
                          ),
                          const SizedBox(height: 20),

                          // ── TAB CONTENT: Description vs Lessons ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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
  // 1. TOP VIDEO CONTAINER (Exact 16:9 thumbnail size, with signature bottom curve)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopVideoPlayer(double height, String thumbnail, bool isEnrolled, int price) {
    final isSessionFree = _activeSession?['isFreePreview'] == true;
    final canPlay = isEnrolled || isSessionFree;

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
          // ── LAYER 0: CRISP 16:9 BANNER / VIDEO (100% full-bleed, bottom corners clipped by curve) ──
          Positioned.fill(
            child: _isPlaying
                ? (_isWebEmbed && _webViewController != null
                    ? WebViewWidget(controller: _webViewController!)
                    : (_isVideoInitialized && _videoController != null && _videoController!.value.isInitialized
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )))
                : (thumbnail.isNotEmpty
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
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white24, size: 64),
                        ),
                      )),
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

          // ── LAYER 2: CENTER PLAY / LOCK BUTTON (Only the lock / play badge remains) ──
          if (!_isPlaying)
            Center(
              child: GestureDetector(
                onTap: () {
                  if (canPlay) {
                    _startPlaying();
                  } else {
                    _openCheckout(price);
                  }
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x38000000),
                        blurRadius: 18,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      canPlay ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                      color: const Color(0xFF1E1B18),
                      size: canPlay ? 36 : 26,
                    ),
                  ),
                ),
              ),
            ),

          // ── LAYER 3: TOP NAVIGATION BAR (Back, Transactions, Bookmark) ──
          Positioned(
            top: 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                InkWell(
                  onTap: () {
                    if (_isPlaying) {
                      setState(() => _isPlaying = false);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
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

                    // Bookmark or Fullscreen if playing
                    if (_isPlaying)
                      InkWell(
                        onTap: _playAndEnterLandscape,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.38),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                        ),
                      )
                    else
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
  // Floating Frosted Glass Control Pill
  // ───────────────────────────────────────────────────────────────────────────
    Widget _buildFrostedControlPill(Duration currentPos, Duration totalDur) {
    final speedLabel = _playbackSpeed == 1.0 ? '1x' : '${_playbackSpeed.toString()}x';

    final maxMs = totalDur.inMilliseconds > 0 ? totalDur.inMilliseconds.toDouble() : 1.0;
    final currentMs = currentPos.inMilliseconds.clamp(0, totalDur.inMilliseconds).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            children: [
              // 1. Playback Speed Button (e.g. "1x")
              GestureDetector(
                onTap: _cyclePlaybackSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    speedLabel,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1E1B18),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),

              // 2. Video Seekbar Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.35),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5, elevation: 2),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: currentMs,
                    min: 0.0,
                    max: maxMs,
                    onChanged: (val) {
                      if (_videoController != null && _videoController!.value.isInitialized) {
                        _videoController!.seekTo(Duration(milliseconds: val.toInt()));
                      }
                    },
                  ),
                ),
              ),

              // 3. Fullscreen / Landscape Button
              InkWell(
                onTap: _playAndEnterLandscape,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  child: const Icon(
                    Icons.crop_free_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEGMENTED TAB BAR (Description vs Lessons, matching reference design 100%)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8E3),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          // Tab 0: Description
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTab != 0) setState(() => _selectedTab = 0);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                height: 52,
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? const Color(0xFFE2C4F0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Description',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: _selectedTab == 0 ? FontWeight.w800 : FontWeight.w600,
                    color: const Color(0xFF1E1B18),
                  ),
                ),
              ),
            ),
          ),
          // Tab 1: Lessons
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTab != 1) setState(() => _selectedTab = 1);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                height: 52,
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? const Color(0xFFE2C4F0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Lessons',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: _selectedTab == 1 ? FontWeight.w800 : FontWeight.w600,
                    color: const Color(0xFF1E1B18),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                        'Time',
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
                        'Lessons',
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

        // Rating with yellow star
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
    if (chapters.isEmpty) {
      return _buildEmptyLessonsPlaceholder();
    }

    int globalIndex = 0;
    final List<Widget> items = [];

    for (int chIndex = 0; chIndex < chapters.length; chIndex++) {
      final chapter = chapters[chIndex] as Map<String, dynamic>;
      final chTitle = (chapter['title'] as String?) ?? 'Bab ${chIndex + 1}';
      final sessions = (chapter['sessions'] as List?) ?? [];

      if (chapters.length > 1) {
        items.add(
          Padding(
            padding: EdgeInsets.only(top: chIndex == 0 ? 0 : 18, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1B18),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chTitle.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8C827A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (sessions.isEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Belum ada materi untuk bab ini.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF8C827A),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }

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

  Widget _buildLessonCard({
    required int globalIndex,
    required Map<String, dynamic> session,
    required bool isEnrolled,
    required int price,
  }) {
    final sessionTitle = (session['title'] as String?)?.trim().isNotEmpty == true
        ? session['title'] as String
        : 'Sesi Belajar';
    final isFree = session['isFreePreview'] == true;
    final canPlay = isEnrolled || isFree;
    final isLocked = !canPlay;
    final isPlayingSession = _activeSession?['id']?.toString() == session['id']?.toString() && _isPlaying;

    // Duration & Points (matching exact bold text from reference)
    final durSec = (session['videoDuration'] as num?)?.toInt() ??
        (session['duration'] as num?)?.toInt() ??
        0;
    String subtitleText = '+20 points';
    if (durSec > 0) {
      subtitleText = '+20 points • ${_formatDuration(Duration(seconds: durSec))}';
    }

    // 4 Pastel Themes from Reference Design (Lavender, Peach, Mint, Sky)
    const badgeThemes = [
      (badgeBg: Color(0xFFE8D4F5), starColor: Color(0xFF8922A6)),
      (badgeBg: Color(0xFFFBE2D0), starColor: Color(0xFFD95A11)),
      (badgeBg: Color(0xFFD7F5E5), starColor: Color(0xFF059669)),
      (badgeBg: Color(0xFFD8EEFD), starColor: Color(0xFF2563EB)),
    ];
    final theme = badgeThemes[globalIndex % badgeThemes.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isPlayingSession ? const Color(0xFF143E26) : const Color(0xFFEBE6DF),
          width: isPlayingSession ? 1.6 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () {
            if (canPlay) {
              _openLearningPlayer(session);
            } else {
              _promptUnlockCourse(price);
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // 1. Squircle Pastel Badge with 3D Rounded Star
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 2.5),
                        child: Icon(
                          Icons.star_rounded,
                          color: theme.starColor.withValues(alpha: 0.35),
                          size: 30,
                        ),
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: theme.starColor,
                        size: 30,
                      ),
                    ],
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
                        subtitleText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 3. Black Squircle Action Box (Checkmark or Lock)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isLocked
                        ? Icons.lock_rounded
                        : (isPlayingSession ? Icons.play_arrow_rounded : Icons.check_rounded),
                    color: Colors.white,
                    size: isLocked ? 17 : 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. CHAPTER / LESSONS CAPSULE CARD (ActivityDropdown with smooth animations)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildChapterCapsule(int index, Map<String, dynamic> chapter, bool isEnrolled, int price) {
    final chapterKey = _chapterKeys.putIfAbsent(index, () => GlobalKey());

    return Container(
      key: chapterKey,
      child: ChapterActivityDropdown(
        index: index,
        chapter: chapter,
        isExpanded: _expandedChapters.contains(index),
        activeSessionId: _activeSession?['id']?.toString(),
        onToggle: () {
          final willExpand = !_expandedChapters.contains(index);
          setState(() {
            if (willExpand) {
              _expandedChapters.add(index);
            } else {
              _expandedChapters.remove(index);
            }
          });

          if (willExpand) {
            // Smoothly auto-scroll to focus on the opened lesson & its contents
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 240), () {
                if (!mounted) return;
                final currentCtx = chapterKey.currentContext;
                if (currentCtx != null) {
                  Scrollable.ensureVisible(
                    currentCtx,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    alignment: 0.05,
                  );
                }
              });
            });
          }

          // Select first session if none selected yet
          final sessions = (chapter['sessions'] as List?) ?? [];
          if (sessions.isNotEmpty && _activeSession?['id'] == null) {
            final first = sessions.first as Map<String, dynamic>;
            if (isEnrolled || first['isFreePreview'] == true) {
              _loadSessionVideo(first, autoPlay: false);
            }
          }
        },
        onSelectSession: (session) {
          if (isEnrolled || session['isFreePreview'] == true) {
            _openLearningPlayer(session);
          } else {
            _promptUnlockCourse(price);
          }
        },
      ),
    );
  }

  Widget _buildEmptyLessonsPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Center(
        child: Text(
          'Silabus sedang dipersiapkan oleh mentor.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF8C827A),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. STICKY BOTTOM BAR (Cream UI Price & CTA)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStickyBottomBar(String priceStr, int price, bool isEnrolled, List chapters) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2).withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: Color(0xFFEADBCE), width: 1.2)),
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
                      if (isEnrolled) {
                        _openLearningPlayer();
                      } else {
                        _openCheckout(price);
                      }
                    },
                    icon: Icon(
                      isEnrolled
                          ? Icons.play_circle_fill_rounded
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
                      backgroundColor: const Color(0xFF1E1B18),
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
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
