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

  // Track expanded chapters
  final Set<int> _expandedChapters = {0};

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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Materi ini terkunci. Beli kelas untuk akses seluruh materi & sertifikat.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Beli Sekarang',
          textColor: const Color(0xFFFBBF24),
          onPressed: () => _openCheckout(price),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
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
    for (final ch in chapters) {
      final sList = (ch['sessions'] as List?) ?? [];
      totalLessons += sList.length;
    }
    if (totalLessons == 0) totalLessons = chapters.isNotEmpty ? chapters.length : 1;

    // Full, immersive height for video container (~40% of screen height)
    final mediaHeight = MediaQuery.of(context).size.height * 0.40;

    return Stack(
      children: [
        // ── Main Scroll View ─────────────────────────────────────────────────
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP VIDEO CONTAINER with rounded bottom corners (Thumbnail fills card completely)
              _buildTopVideoPlayer(mediaHeight, thumbnail, isEnrolled, price),

              // 2. COURSE INFO & LESSONS (Warm Cream Theme)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1E1B18),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Course Description
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B655F),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Mentor & Rating Row
                    _buildMentorAndRatingRow(mentorName, mentorPhoto, rating),
                    const SizedBox(height: 28),

                    // Lessons Header Row (Left: "Lessons", Right: total count e.g. "14")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lessons',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1E1B18),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$totalLessons',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF9E948A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Chapter / Lessons Capsule Cards
                    if (chapters.isEmpty)
                      _buildEmptyLessonsPlaceholder()
                    else
                      ...chapters.asMap().entries.map((entry) {
                        final chIndex = entry.key;
                        final chapter = entry.value as Map<String, dynamic>;
                        return _buildChapterCapsule(chIndex, chapter, isEnrolled, price);
                      }),
                  ],
                ),
              ),
            ],
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TOP VIDEO CONTAINER (Thumbnail follows card size, Play starts video)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopVideoPlayer(double height, String thumbnail, bool isEnrolled, int price) {
    // Current duration calculations
    final currentPos = _videoController?.value.position ?? Duration.zero;
    Duration totalDur = _videoController?.value.duration ?? Duration.zero;

    if (totalDur == Duration.zero && _activeSession?['videoDuration'] != null) {
      final sec = _activeSession!['videoDuration'] as int;
      if (sec > 0) totalDur = Duration(seconds: sec);
    }

    final isSessionFree = _activeSession?['isFreePreview'] == true;
    final canPlay = isEnrolled || isSessionFree;
    final timestampStr = '${_formatDuration(currentPos)} / ${_formatDuration(totalDur)}';

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF231F1C),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 1: VIDEO OR THUMBNAIL (Fills card completely) ─────────────
          if (_isPlaying) ...[
            if (_isWebEmbed && _webViewController != null)
              SizedBox.expand(
                child: WebViewWidget(controller: _webViewController!),
              )
            else if (_isVideoInitialized && _videoController != null && _videoController!.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ] else ...[
            // Thumbnail image strictly follows the size of the video card container
            if (thumbnail.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumbnail,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFF2B2622)),
                errorWidget: (context, url, error) => Container(color: const Color(0xFF2B2622)),
              )
            else
              Container(
                color: const Color(0xFF2B2622),
                child: const Center(
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white24, size: 64),
                ),
              ),

            // Gradient Overlay for readability of buttons and play icon
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 0.65, 1.0],
                  colors: [
                    Color(0x88000000),
                    Colors.transparent,
                    Color(0x22000000),
                    Color(0x99000000),
                  ],
                ),
              ),
            ),

            // Center Play / Lock Button (Click to start playing or unlock)
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
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      canPlay ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                      color: const Color(0xFF1E1B18),
                      size: canPlay ? 42 : 30,
                    ),
                  ),
                ),
              ),
            ),

            if (!isEnrolled)
              Positioned(
                bottom: 60,
                left: 20,
                child: GestureDetector(
                  onTap: () => _openCheckout(price),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSessionFree ? Icons.visibility_outlined : Icons.lock_outline_rounded,
                          size: 13,
                          color: isSessionFree ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isSessionFree ? 'Preview Sesi Gratis' : 'Akses Penuh Terkunci',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Dynamic Timestamp on bottom right (e.g. "12:18 / 28:00")
            Positioned(
              bottom: 64,
              right: 20,
              child: Text(
                timestampStr,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),

            // Floating Frosted Glass Control Pill (Speed, Seekbar, Fullscreen)
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: _buildFrostedControlPill(currentPos, totalDur),
            ),
          ],

          // ── LAYER 2: OVERLAY NAVIGATION (Back, Transactions & Bookmark) ─────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Riwayat Transaksi button
                        InkWell(
                          onTap: () => context.push(AppRoutes.transactions),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Bookmark or Fullscreen if playing
                        if (_isPlaying)
                          InkWell(
                            onTap: _playAndEnterLandscape,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                            ),
                          )
                        else
                          InkWell(
                            onTap: _toggleWishlist,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Icon(
                                _isWishlisted ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                color: _isWishlisted ? const Color(0xFFFBBF24) : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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
  // 3. CHAPTER / LESSONS CAPSULE CARD (ActivityDropdown with smooth animations)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildChapterCapsule(int index, Map<String, dynamic> chapter, bool isEnrolled, int price) {
    return ChapterActivityDropdown(
      index: index,
      chapter: chapter,
      isExpanded: _expandedChapters.contains(index),
      activeSessionId: _activeSession?['id']?.toString(),
      onToggle: () {
        setState(() {
          if (_expandedChapters.contains(index)) {
            _expandedChapters.remove(index);
          } else {
            _expandedChapters.add(index);
          }
        });

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
