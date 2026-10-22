import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import '../../../../data/datasources/remote/bootcamp_remote_datasource.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String courseTitle;
  final String? videoUrl;
  final String? courseId;
  final String? sessionId;
  final bool isAlreadyCompleted;
  final VoidCallback? onCompleted;
  final bool isBootcamp;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.courseTitle,
    this.videoUrl,
    this.courseId,
    this.sessionId,
    this.isAlreadyCompleted = false,
    this.onCompleted,
    this.isBootcamp = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with SingleTickerProviderStateMixin {
  final CourseRemoteDataSource _courseDs = sl<CourseRemoteDataSource>();
  final BootcampRemoteDataSource _bootcampDs = sl<BootcampRemoteDataSource>();

  late TabController _tabController;

  // Session Data
  String? _currentSessionId;
  String? _currentTitle;
  String? _currentVideoUrl;
  String _sessionType = 'VIDEO';
  String? _sessionDescription;
  List<dynamic> _materials = [];
  List<dynamic> _quizOptions = [];
  String? _liveMeetingUrl;
  String? _prevSessionId;
  String? _nextSessionId;
  int _courseProgress = 0;
  bool _isLoadingSessionData = true;

  // Player Controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;
  bool _isWebEmbedPlayer = false;
  bool _isPlayerInitializing = true;
  String? _playerErrorMessage;

  // Anti-skip & 90% completion logic
  late bool _isUnlocked;
  int _maxWatchedSeconds = 0;
  bool _isSubmittingProgress = false;
  bool _isSessionFinished = false;
  double _currentProgressFraction = 0.0;

  // Notes & QnA state
  List<dynamic> _notes = [];
  bool _isLoadingNotes = false;
  final TextEditingController _noteInputController = TextEditingController();

  List<dynamic> _qnaList = [];
  bool _isLoadingQna = false;
  final TextEditingController _qnaInputController = TextEditingController();

  // Quiz state
  String? _selectedQuizOptionId;
  bool _quizSubmitted = false;
  bool _quizPassed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentSessionId = widget.sessionId;
    _currentTitle = widget.title;
    _currentVideoUrl = widget.videoUrl;
    _isUnlocked = widget.isAlreadyCompleted;
    _isSessionFinished = widget.isAlreadyCompleted;

    _loadSessionAndPlayer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteInputController.dispose();
    _qnaInputController.dispose();
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _chewieController?.dispose();
    _chewieController = null;
    _webViewController = null;
  }

  // ── 1. Fetch Session Details from Backend ─────────────────────────────────
  Future<void> _loadSessionAndPlayer() async {
    final cId = widget.courseId;
    final sId = _currentSessionId;

    if (cId != null && sId != null) {
      setState(() => _isLoadingSessionData = true);
      try {
        final Map<String, dynamic> data;
        if (widget.isBootcamp) {
          data = await _bootcampDs.getBootcampSession(cId, sId);
        } else {
          data = await _courseDs.getCourseSession(cId, sId);
        }

        final current = (data['currentSession'] as Map<String, dynamic>?) ?? {};
        final rawType = (current['type'] as String?) ?? 'VIDEO';
        final rawUrl = (current['videoUrl'] as String?) ?? _currentVideoUrl;
        final isComp = current['isCompleted'] == true || widget.isAlreadyCompleted;

        // Parse materials
        List<dynamic> parsedMaterials = [];
        if (current['materials'] != null) {
          if (current['materials'] is String) {
            try {
              parsedMaterials = jsonDecode(current['materials']) as List<dynamic>;
            } catch (_) {
              parsedMaterials = [];
            }
          } else if (current['materials'] is List) {
            parsedMaterials = current['materials'];
          }
        }

        // Parse quiz
        List<dynamic> parsedQuiz = [];
        if (current['quizOptions'] != null && current['quizOptions'] is List) {
          parsedQuiz = current['quizOptions'];
        }

        if (mounted) {
          setState(() {
            _sessionType = rawType;
            _currentTitle = current['title'] ?? _currentTitle;
            _currentVideoUrl = rawUrl;
            _sessionDescription = current['description'] ?? current['assignmentDescription'];
            _materials = parsedMaterials;
            _quizOptions = parsedQuiz;
            _liveMeetingUrl = current['meetingUrl'] ?? current['liveUrl'];
            _prevSessionId = data['prevSessionId'] as String?;
            _nextSessionId = data['nextSessionId'] as String?;
            _courseProgress = (data['progress'] as num?)?.toInt() ?? 0;
            _isSessionFinished = isComp;
            _isUnlocked = isComp || rawType != 'VIDEO'; // non-video unlocks immediately
            _isLoadingSessionData = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoadingSessionData = false);
        }
      }
    } else {
      setState(() => _isLoadingSessionData = false);
    }

    _loadTabContent();

    // If it's a video session, initialize video/embed player
    if (_sessionType == 'VIDEO') {
      _initAppropriatePlayer();
    } else {
      setState(() {
        _isPlayerInitializing = false;
        _isUnlocked = true;
      });
    }
  }

  void _loadTabContent() {
    _loadNotes();
    _loadQna();
  }

  Future<void> _loadNotes() async {
    final cId = widget.courseId;
    final sId = _currentSessionId;
    if (cId == null || sId == null || widget.isBootcamp) return;

    setState(() => _isLoadingNotes = true);
    try {
      final list = await _courseDs.getSessionNotes(cId, sId);
      if (mounted) setState(() { _notes = list; _isLoadingNotes = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingNotes = false);
    }
  }

  Future<void> _loadQna() async {
    final cId = widget.courseId;
    final sId = _currentSessionId;
    if (cId == null || sId == null || widget.isBootcamp) return;

    setState(() => _isLoadingQna = true);
    try {
      final list = await _courseDs.getSessionQna(cId, sId);
      if (mounted) setState(() { _qnaList = list; _isLoadingQna = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingQna = false);
    }
  }

  // ── 2. Video Player Engine (Bunny Stream Webview vs MP4 Native) ─────────────
  bool _checkIsWebEmbed(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.toLowerCase();
    // Only Bunny Stream URLs — matches web CourseVideoPlayer exactly
    return lower.contains('iframe.mediadelivery.net') ||
        lower.contains('b-cdn.net') ||
        lower.contains('bunnycdn');
  }

  Future<void> _initAppropriatePlayer() async {
    _disposePlayer();

    final url = _currentVideoUrl;
    if (url == null || url.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isPlayerInitializing = false;
          _playerErrorMessage = 'Video materi belum diunggah untuk modul ini.';
        });
      }
      return;
    }

    setState(() {
      _isPlayerInitializing = true;
      _playerErrorMessage = null;
      _currentProgressFraction = 0.0;
      _maxWatchedSeconds = 0;
    });

    if (_checkIsWebEmbed(url)) {
      _isWebEmbedPlayer = true;
      _initWebEmbedPlayer(url);
    } else {
      _isWebEmbedPlayer = false;
      await _initNativePlayer(url);
    }
  }

  void _initWebEmbedPlayer(String rawUrl) {
    String embedUrl = rawUrl;

    // Append autoplay for Bunny Stream if not already set
    if (embedUrl.contains('iframe.mediadelivery.net') ||
        embedUrl.contains('b-cdn.net') ||
        embedUrl.contains('bunnycdn')) {
      if (!embedUrl.contains('autoplay=')) {
        embedUrl = '$embedUrl${embedUrl.contains('?') ? '&' : '?'}autoplay=true';
      }
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
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background: #000000;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: none;
      display: block;
    }
  </style>
</head>
<body>
  <iframe
    id="videoFrame"
    src="$embedUrl"
    allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
    allowfullscreen>
  </iframe>
  <script>
    // Intercept Bunny Stream / HTML5 postMessage events
    window.addEventListener('message', function(event) {
      try {
        var data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
        if (data && (data.event === 'timeupdate' || data.type === 'timeupdate')) {
          var cur = data.currentTime || data.seconds || 0;
          var dur = data.duration || 1;
          FlutterVideoChannel.postMessage(JSON.stringify({ event: 'timeupdate', current: cur, duration: dur }));
        } else if (data && (data.event === 'ended' || data.type === 'ended')) {
          FlutterVideoChannel.postMessage(JSON.stringify({ event: 'ended' }));
        }
      } catch(e) {}
    });
  </script>
</body>
</html>
''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isPlayerInitializing = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isPlayerInitializing = false;
                _playerErrorMessage = 'Gagal memuat player video: ${error.description}';
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterVideoChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['event'] == 'timeupdate') {
              final double cur = (data['current'] as num).toDouble();
              final double dur = (data['duration'] as num).toDouble();
              if (dur > 0) {
                final fraction = (cur / dur).clamp(0.0, 1.0);
                _handleWatchProgress(fraction, cur.toInt());
              }
            } else if (data['event'] == 'ended') {
              _onVideoEnded();
            }
          } catch (_) {}
        },
      )
      ..loadHtmlString(htmlContent, baseUrl: 'https://iframe.mediadelivery.net');

    _webViewController = controller;
  }

  Future<void> _initNativePlayer(String url) async {
    try {
      final uri = Uri.parse(url);
      _videoPlayerController = VideoPlayerController.networkUrl(uri);
      await _videoPlayerController!.initialize();

      _videoPlayerController!.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0 ? _videoPlayerController!.value.aspectRatio : 16 / 9,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.75, 1.0, 1.25, 1.5, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.accent,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade500,
        ),
      );

      if (mounted) {
        setState(() => _isPlayerInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlayerInitializing = false;
          _playerErrorMessage = 'Gagal memutar video: $e';
        });
      }
    }
  }

  void _videoListener() {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration.inSeconds == 0) return;

    final currentSec = position.inSeconds;
    final totalSec = duration.inSeconds;
    final fraction = (currentSec / totalSec).clamp(0.0, 1.0);

    // Anti-skip protection: cannot seek beyond watched duration
    if (!_isUnlocked && currentSec > _maxWatchedSeconds + 3) {
      controller.seekTo(Duration(seconds: _maxWatchedSeconds));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anti-skip aktif: Tonton minimal 90% sebelum dapat melewati video.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    } else {
      _maxWatchedSeconds = max(_maxWatchedSeconds, currentSec);
    }

    _handleWatchProgress(fraction, currentSec);
  }

  void _handleWatchProgress(double fraction, int currentSeconds) {
    if (mounted) {
      setState(() {
        _currentProgressFraction = fraction;
      });
    }

    if (!_isUnlocked && fraction >= 0.90) {
      setState(() => _isUnlocked = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('🎉 Syarat 90% terpenuhi! Tombol selesai kini terbuka.')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _onVideoEnded() {
    setState(() => _isUnlocked = true);
    if (!_isSessionFinished) {
      _handleCompleteSession();
    }
  }

  // ── 3. Complete Session Action ────────────────────────────────────────────
  Future<void> _handleCompleteSession() async {
    final cId = widget.courseId;
    final sId = _currentSessionId;

    if (cId == null || sId == null) {
      setState(() => _isSessionFinished = true);
      widget.onCompleted?.call();
      _showCompletionDialog(15);
      return;
    }

    setState(() => _isSubmittingProgress = true);

    try {
      final Map<String, dynamic> res;
      if (widget.isBootcamp) {
        res = await _bootcampDs.completeBootcampSession(cId, sId);
      } else {
        res = await _courseDs.completeCourseSession(cId, sId);
      }

      final xpEarned = res['xpEarned'] ?? 15;

      if (!mounted) return;
      setState(() {
        _isSessionFinished = true;
        _isSubmittingProgress = false;
      });

      widget.onCompleted?.call();
      _showCompletionDialog(xpEarned);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showCompletionDialog(dynamic xp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.xpBg, shape: BoxShape.circle),
              child: const Icon(Icons.stars_rounded, color: AppColors.xp, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              'Modul Selesai!',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Hebat! Anda telah menuntaskan modul ini dan memperoleh +$xp XP.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (_nextSessionId != null) {
                  _switchSession(_nextSessionId!);
                } else {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _nextSessionId != null ? 'Lanjut ke Sesi Berikutnya →' : 'Kembali ke Katalog',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchSession(String newSessionId) {
    setState(() {
      _currentSessionId = newSessionId;
      _isSessionFinished = false;
      _isUnlocked = false;
      _currentProgressFraction = 0.0;
      _quizSubmitted = false;
      _selectedQuizOptionId = null;
    });
    _loadSessionAndPlayer();
  }

  // ── 4. Main Build Method ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.courseTitle.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              _currentTitle ?? widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_courseProgress > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _courseProgress == 100
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _courseProgress == 100
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _courseProgress == 100 ? AppColors.primary : const Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_courseProgress% Selesai',
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top: Video Frame or Media Banner
            _buildTopMediaFrame(),

            // Bottom: Tab Navigation & Content Body
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Segmented Tab Bar (Apple / Linear Precision Style)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      height: 42,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 5,
                              offset: Offset(0, 1.5),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: const Color(0xFF0F172A),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          letterSpacing: -0.1,
                        ),
                        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        tabs: const [
                          Tab(text: 'Modul'),
                          Tab(text: 'Catatan'),
                          Tab(text: 'Tanya Jawab'),
                        ],
                      ),
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildNotesTab(),
                          _buildQnaTab(),
                        ],
                      ),
                    ),

                    // Bottom Navigation Bar (Prev / Next & Complete)
                    _buildBottomActionDock(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Media Frame: Video vs Non-Video ───────────────────────────────────
  Widget _buildTopMediaFrame() {
    if (_sessionType != 'VIDEO') {
      // Non-video sessions show a dedicated module banner
      return Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(
                _sessionType == 'MATERIAL'
                    ? Icons.book_rounded
                    : _sessionType == 'QUIZ'
                        ? Icons.quiz_rounded
                        : Icons.videocam_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _sessionType == 'MATERIAL'
                          ? 'DOKUMEN MATERI'
                          : _sessionType == 'QUIZ'
                              ? 'KUIS PEMAHAMAN'
                              : 'SESI LIVE INTERAKTIF',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentTitle ?? 'Modul Pembelajaran',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: _isPlayerInitializing
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _playerErrorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 44),
                          const SizedBox(height: 10),
                          Text(
                            (_playerErrorMessage ?? '').contains('ERR_NAME_NOT_RESOLVED')
                                ? 'Video tidak dapat diputar.\nURL video belum dikonfigurasi dengan benar oleh admin.'
                                : (_playerErrorMessage ?? 'Gagal memuat video.'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _initAppropriatePlayer,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          if (_currentVideoUrl != null && _currentVideoUrl!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final uri = Uri.tryParse(_currentVideoUrl!);
                                if (uri != null) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_browser_rounded, size: 16, color: Colors.white54),
                              label: Text(
                                'Buka di Browser',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : _isWebEmbedPlayer
                    ? WebViewWidget(controller: _webViewController!)
                    : Chewie(controller: _chewieController!),
      ),
    );
  }

  // ── Tab 1: Overview / Modul Content ───────────────────────────────────────
  Widget _buildOverviewTab() {
    if (_isLoadingSessionData) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final progressPct = (_currentProgressFraction * 100).toInt();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single Refined Status & Anti-Skip Header Pill
          Row(
            children: [
              if (_isSessionFinished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                      const SizedBox(width: 5),
                      Text(
                        'Modul Telah Selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_sessionType == 'VIDEO')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isUnlocked ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isUnlocked ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isUnlocked ? Icons.verified_rounded : Icons.lock_clock_rounded,
                        size: 13,
                        color: _isUnlocked ? const Color(0xFF059669) : const Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isUnlocked ? 'Syarat 90% Terpenuhi' : 'Anti-Skip: $progressPct% / 90%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isUnlocked ? const Color(0xFF047857) : const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            _currentTitle ?? widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.courseTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Clean Minimalist 4px Progress Bar
          if (_sessionType == 'VIDEO') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _currentProgressFraction,
                minHeight: 4,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isUnlocked ? AppColors.primary : const Color(0xFFEA580C),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Elegant XP Reward Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFEF3C7), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDE68A),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.stars_rounded, size: 16, color: Color(0xFFD97706)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tuntaskan modul ini untuk meraih +15 XP ke profil Anda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Session Body Content Based on Type ──
          if (_sessionType == 'MATERIAL') ...[
            _buildMaterialContent(),
          ] else if (_sessionType == 'QUIZ') ...[
            _buildQuizContent(),
          ] else if (_sessionType == 'LIVE') ...[
            _buildLiveContent(),
          ] else ...[
            // Default Video Description
            if (_sessionDescription != null && _sessionDescription!.isNotEmpty) ...[
              Text(
                'Deskripsi Modul',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                ),
                child: Text(
                  _sessionDescription!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF475569), height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Attached materials for video session (if any)
            if (_materials.isNotEmpty) _buildAttachmentList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sessionDescription != null && _sessionDescription!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              _sessionDescription!,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF334155), height: 1.7),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_materials.isNotEmpty) _buildAttachmentList(),
      ],
    );
  }

  Widget _buildAttachmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Berkas & Dokumen Pendukung',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _materials.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final mat = _materials[idx] as Map<String, dynamic>;
            final name = (mat['name'] as String?) ?? 'Dokumen Materi ${idx + 1}';
            final fileUrl = (mat['url'] as String?) ?? '';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.file_present_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Unduh untuk mempelajari materi',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (fileUrl.isNotEmpty) {
                        launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: const Text('Buka'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuizContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Jawaban yang Tepat:',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        if (_quizOptions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(child: Text('Pertanyaan kuis sedang disiapkan oleh mentor.')),
          )
        else
          ..._quizOptions.map((opt) {
            final option = opt as Map<String, dynamic>;
            final optId = option['id']?.toString() ?? '';
            final text = option['text'] ?? '';
            final isSelected = _selectedQuizOptionId == optId;

            return GestureDetector(
              onTap: _quizSubmitted ? null : () => setState(() => _selectedQuizOptionId = optId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFF94A3B8), width: 2),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 14),
        if (!_quizSubmitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedQuizOptionId == null
                  ? null
                  : () {
                      final selected = _quizOptions.firstWhere((o) => o['id']?.toString() == _selectedQuizOptionId, orElse: () => {});
                      final isCorrect = selected['isCorrect'] == true;
                      setState(() {
                        _quizSubmitted = true;
                        _quizPassed = isCorrect;
                        if (isCorrect) _isUnlocked = true;
                      });
                      if (isCorrect) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Jawaban Anda Benar!'), backgroundColor: AppColors.success),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Jawaban belum tepat, silakan coba lagi.'), backgroundColor: AppColors.error),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kirim Jawaban Kuis'),
            ),
          )
        else if (!_quizPassed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() {
                _quizSubmitted = false;
                _selectedQuizOptionId = null;
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi'),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                'Sesi Interaktif Live Mentoring',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _sessionDescription ?? 'Bergabunglah ke dalam ruang diskusi daring dengan mentor melalui tautan berikut.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 16),
          if (_liveMeetingUrl != null && _liveMeetingUrl!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(_liveMeetingUrl!), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text('Masuk Sesi Google Meet / Zoom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 2: Notes ──────────────────────────────────────────────────────────
  Widget _buildNotesTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingNotes
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _notes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.edit_note_rounded, size: 28, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum Ada Catatan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Catat poin penting selama menyimak video untuk dipelajari kembali kapan saja.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notes.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final note = _notes[idx] as Map<String, dynamic>;
                        final content = note['content'] ?? '';
                        final ts = note['timestampSec'] != null ? '${(note['timestampSec'] / 60).floor()}:${(note['timestampSec'] % 60).toString().padLeft(2, '0')}' : null;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ts != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '⏱ Menit $ts',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                content,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF334155),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // Input Form Dock (Apple iMessage precision style)
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _noteInputController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Tulis catatan penting...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1117),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final text = _noteInputController.text.trim();
                    if (text.isEmpty || widget.courseId == null || _currentSessionId == null) return;
                    _noteInputController.clear();
                    try {
                      await _courseDs.createSessionNote(widget.courseId!, _currentSessionId!, text);
                      _loadNotes();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3: QnA ────────────────────────────────────────────────────────────
  Widget _buildQnaTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingQna
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _qnaList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.forum_outlined, size: 26, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum Ada Diskusi',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Punya pertanyaan seputar materi? Tanyakan langsung untuk didiskusikan bersama mentor.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _qnaList.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final item = _qnaList[idx] as Map<String, dynamic>;
                        final content = item['content'] ?? '';
                        final user = item['user'] as Map<String, dynamic>? ?? {};
                        final userName = user['name'] ?? 'Mentee';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    userName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                content,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF334155),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // Input Form Dock (Apple iMessage precision style)
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _qnaInputController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Tanyakan sesuatu kepada mentor...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1117),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final text = _qnaInputController.text.trim();
                    if (text.isEmpty || widget.courseId == null || _currentSessionId == null) return;
                    _qnaInputController.clear();
                    try {
                      await _courseDs.createSessionQna(widget.courseId!, _currentSessionId!, text);
                      _loadQna();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Dock: Prev / Next & Complete Button ─────────────────────
  Widget _buildBottomActionDock() {
    final progressPct = (_currentProgressFraction * 100).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Prev Button
          if (_prevSessionId != null) ...[
            InkWell(
              onTap: () => _switchSession(_prevSessionId!),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Icon(Icons.chevron_left_rounded, color: Color(0xFF334155), size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Main Complete / Status Button
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: _isUnlocked && !_isSessionFinished
                    ? const LinearGradient(
                        colors: [Color(0xFF018556), Color(0xFF02A96C)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: _isSessionFinished
                    ? const Color(0xFFF0FDF4)
                    : (!_isUnlocked ? const Color(0xFFF1F5F9) : null),
                borderRadius: BorderRadius.circular(14),
                border: _isSessionFinished
                    ? Border.all(color: const Color(0xFFBBF7D0), width: 1.2)
                    : null,
                boxShadow: _isUnlocked && !_isSessionFinished
                    ? const [
                        BoxShadow(
                          color: Color(0x28018556),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: (!_isUnlocked || _isSessionFinished || _isSubmittingProgress) ? null : _handleCompleteSession,
                  child: Center(
                    child: _isSubmittingProgress
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isSessionFinished
                                    ? Icons.check_circle_rounded
                                    : _isUnlocked
                                        ? Icons.stars_rounded
                                        : Icons.lock_outline_rounded,
                                size: 17,
                                color: _isSessionFinished
                                    ? const Color(0xFF018556)
                                    : _isUnlocked
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isSessionFinished
                                    ? 'Modul Selesai'
                                    : _isUnlocked
                                        ? 'Selesaikan Modul (+15 XP)'
                                        : 'Tonton 90% untuk Selesai ($progressPct%)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _isSessionFinished
                                      ? const Color(0xFF018556)
                                      : _isUnlocked
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Next Button
          if (_nextSessionId != null) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _switchSession(_nextSessionId!),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

