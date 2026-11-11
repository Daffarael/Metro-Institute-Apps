import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import '../../../../data/datasources/remote/bootcamp_remote_datasource.dart';
import '../../../common/widgets/tactile_metro_button.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String courseTitle;
  final String? videoUrl;
  final String? courseId;
  final String? sessionId;
  final bool isAlreadyCompleted;
  final VoidCallback? onCompleted;
  final bool isBootcamp;
  final String? sessionType;

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
    this.sessionType,
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
  bool _isLiveEnded = false;
  String? _prevSessionId;
  String? _nextSessionId;
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
  bool _isBootcampActual = false;
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

  // Reading timer state for MATERIAL sessions
  Timer? _readingTimer;
  int _requiredReadingSeconds = 180;
  int _remainingReadingSeconds = 180;
  int _xpReward = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
      if (mounted) setState(() {});
    });
    _isBootcampActual = widget.isBootcamp;
    _currentSessionId = widget.sessionId;
    _currentTitle = widget.title;
    _currentVideoUrl = widget.videoUrl;
    _isUnlocked = widget.isAlreadyCompleted;
    _isSessionFinished = widget.isAlreadyCompleted;
    if (widget.sessionType != null && widget.sessionType!.isNotEmpty) {
      _sessionType = widget.sessionType!;
      if (_sessionType != 'VIDEO') {
        _isUnlocked = true;
      }
    }

    _loadSessionAndPlayer();
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
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
        Map<String, dynamic>? data;
        if (_isBootcampActual) {
          try {
            data = await _bootcampDs.getBootcampSession(cId, sId);
            _isBootcampActual = true;
          } catch (e) {
            try {
              data = await _courseDs.getCourseSession(cId, sId);
              _isBootcampActual = false;
            } catch (_) {}
          }
        } else {
          try {
            data = await _courseDs.getCourseSession(cId, sId);
            _isBootcampActual = false;
          } catch (e) {
            try {
              data = await _bootcampDs.getBootcampSession(cId, sId);
              _isBootcampActual = true;
            } catch (_) {}
          }
        }

        final sessionData = data;
        if (sessionData != null && sessionData.isNotEmpty) {
          final current = (sessionData['currentSession'] as Map<String, dynamic>?) ?? {};
          final rawType = (current['type'] as String?) ?? widget.sessionType ?? 'VIDEO';
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
          if (current['quizOptions'] != null) {
            final raw = current['quizOptions'];
            if (raw is String) {
              try {
                final dec = jsonDecode(raw);
                if (dec is List) parsedQuiz = dec;
              } catch (_) {}
            } else if (raw is List) {
              parsedQuiz = raw;
            }
          }

          bool isLiveEnd = current['isLiveEnded'] == true || current['isChapterLiveEnded'] == true || current['isEnded'] == true;
          final liveSched = current['liveScheduledAt'] ?? current['scheduledAt'];
          if (liveSched != null) {
            final sched = DateTime.tryParse(liveSched.toString());
            if (sched != null) {
              final dur = (current['videoDuration'] as num?)?.toInt() ?? (current['durationMinutes'] as num?)?.toInt() ?? 5400;
              final durMin = dur > 300 ? (dur ~/ 60) : dur;
              if (DateTime.now().isAfter(sched.add(Duration(minutes: durMin > 0 ? durMin : 90)))) {
                isLiveEnd = true;
              }
            }
          }

          final rawDuration = current['videoDuration'] ?? current['durationMin'];
          final durationSec = (rawDuration != null && (rawDuration as num) > 0)
              ? ((rawDuration as num) < 60 ? ((rawDuration as num) * 60).toInt() : (rawDuration as num).toInt())
              : 0;
          final remainingSec = isComp ? 0 : durationSec;
          final rawXp = current['xpReward'];
          final xpVal = (rawXp is num && rawXp > 0) ? rawXp.toInt() : 10;

          if (mounted) {
            setState(() {
              _sessionType = rawType;
              _currentTitle = current['title'] ?? _currentTitle;
              _currentVideoUrl = rawUrl;
              _sessionDescription = current['description'] ?? current['assignmentDescription'];
              _materials = parsedMaterials;
              _quizOptions = parsedQuiz;
              _isLiveEnded = isLiveEnd;
              _liveMeetingUrl = isLiveEnd ? null : (current['meetingUrl'] ?? current['liveUrl']);
              _prevSessionId = sessionData['prevSessionId'] as String?;
              _nextSessionId = sessionData['nextSessionId'] as String?;
              _isSessionFinished = isComp;
              _requiredReadingSeconds = durationSec;
              _remainingReadingSeconds = remainingSec;
              _xpReward = xpVal;
              _isUnlocked = isComp || (rawType != 'VIDEO' && rawType != 'MATERIAL'); // non-video/non-material unlocks immediately
              _isLoadingSessionData = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingSessionData = false);
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
    } else if (_sessionType == 'MATERIAL') {
      setState(() {
        _isPlayerInitializing = false;
        _playerErrorMessage = null;
        _isUnlocked = _isSessionFinished || _remainingReadingSeconds <= 0;
      });
      _startReadingTimer();
    } else {
      setState(() {
        _isPlayerInitializing = false;
        _playerErrorMessage = null;
        _isUnlocked = true;
      });
    }
  }

  void _startReadingTimer() {
    _readingTimer?.cancel();
    if (_isSessionFinished || _sessionType != 'MATERIAL' || _remainingReadingSeconds <= 0) return;
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingReadingSeconds > 0) {
        setState(() {
          _remainingReadingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isUnlocked = true;
        });
      }
    });
  }

  String _formatReadingTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
    var iframe = document.getElementById('videoFrame');

    // Bunny Stream Player.js handshake
    function sendHandshake() {
      if (iframe && iframe.contentWindow) {
        try {
          iframe.contentWindow.postMessage(JSON.stringify({ context: 'player.js', method: 'addEventListener', value: 'timeupdate' }), '*');
          iframe.contentWindow.postMessage(JSON.stringify({ context: 'player.js', method: 'addEventListener', value: 'ended' }), '*');
          iframe.contentWindow.postMessage(JSON.stringify({ context: 'player.js', method: 'addEventListener', value: 'play' }), '*');
        } catch(e) {}
      }
    }

    window.addEventListener('load', function() {
      sendHandshake();
      setTimeout(sendHandshake, 1000);
      setTimeout(sendHandshake, 2500);
      setTimeout(sendHandshake, 5000);
    });

    // Intercept Bunny Stream / HTML5 postMessage events
    window.addEventListener('message', function(event) {
      try {
        var data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
        if (!data) return;

        var evt = data.event || data.type || (data.context === 'player.js' ? data.event : null);

        if (evt === 'timeupdate') {
          var cur = (data.value && typeof data.value.seconds === 'number') ? data.value.seconds : (data.currentTime || data.seconds || 0);
          var dur = (data.value && typeof data.value.duration === 'number') ? data.value.duration : (data.duration || 1);
          FlutterVideoChannel.postMessage(JSON.stringify({ event: 'timeupdate', current: cur, duration: dur }));
        } else if (evt === 'ended' || evt === 'finish' || evt === 'completed') {
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
            _controllerSendHandshake();
          },
          onWebResourceError: (error) {
            // Only report fatal main-frame failure; ignore minor telemetry/DNS resource errors
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _isPlayerInitializing = false;
                  _playerErrorMessage = 'Gagal memuat player video: ${error.description}';
                });
              }
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

  void _controllerSendHandshake() {
    final jsCode = '''
      (function() {
        var iframe = document.getElementById('videoFrame');
        if (iframe && iframe.contentWindow) {
          try {
            iframe.contentWindow.postMessage(JSON.stringify({ context: 'player.js', method: 'addEventListener', value: 'timeupdate' }), '*');
            iframe.contentWindow.postMessage(JSON.stringify({ context: 'player.js', method: 'addEventListener', value: 'ended' }), '*');
          } catch(e) {}
        }
      })();
    ''';
    _webViewController?.runJavaScript(jsCode);
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
    final totalMs = duration.inMilliseconds;
    final currentMs = position.inMilliseconds;
    if (totalMs <= 0) return;

    final currentSec = position.inSeconds;
    double fraction = (currentMs / totalMs).clamp(0.0, 1.0);

    // Deteksi video tamat / hampir tamat
    final bool isCompleted = controller.value.isCompleted ||
        (totalMs > 2000 && totalMs - currentMs <= 1500) ||
        fraction >= 0.95;

    if (isCompleted) {
      fraction = 1.0;
      if (!_isUnlocked) {
        setState(() => _isUnlocked = true);
      }
      _maxWatchedSeconds = max(_maxWatchedSeconds, duration.inSeconds);
      _handleWatchProgress(1.0, duration.inSeconds);
      _onVideoEnded();
      return;
    }

    // Anti-skip protection: hanya aktifkan jika video cukup panjang (> 15 detik)
    // dan user mencoba melompat lebih dari 8 detik dari titik yang sudah ditonton
    if (!_isUnlocked && totalMs > 15000 && currentSec > _maxWatchedSeconds + 8) {
      controller.seekTo(Duration(seconds: _maxWatchedSeconds));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Simak materi video sampai tuntas terlebih dahulu.'),
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
        _currentProgressFraction = max(_currentProgressFraction, fraction);
      });
    }

    if (!_isUnlocked && (_currentProgressFraction >= 0.90 || fraction >= 0.90)) {
      setState(() => _isUnlocked = true);
    }
  }

  void _onVideoEnded() {
    if (!_isUnlocked) {
      setState(() => _isUnlocked = true);
    }
    if (!_isSessionFinished && !_isSubmittingProgress) {
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
      Map<String, dynamic> res;
      if (_isBootcampActual) {
        try {
          res = await _bootcampDs.completeBootcampSession(cId, sId);
        } catch (_) {
          res = await _courseDs.completeCourseSession(cId, sId);
        }
      } else {
        try {
          res = await _courseDs.completeCourseSession(cId, sId);
        } catch (_) {
          res = await _bootcampDs.completeBootcampSession(cId, sId);
        }
      }

      final xpEarned = res['xpEarned'] ?? 15;

      if (!mounted) return;
      _readingTimer?.cancel();
      setState(() {
        _isSessionFinished = true;
        _isUnlocked = true;
        _currentProgressFraction = 1.0;
        _remainingReadingSeconds = 0;
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clean Metro Yellow XP Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDD00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$xp XP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Modul Selesai',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 22),
            TactileMetroButton.primary(
              onPressed: () {
                Navigator.pop(ctx);
                if (_nextSessionId != null) {
                  _switchSession(_nextSessionId!);
                } else {
                  Navigator.pop(context, true);
                }
              },
              height: 48,
              text: _nextSessionId != null ? 'Lanjut ke Sesi Berikutnya' : 'Kembali ke Katalog',
            ),
          ],
        ),
      ),
    );
  }

  void _goToPrevSession(String prevId) {
    _switchSession(prevId);
  }

  void _goToNextSession(String nextId) {
    if (!_isSessionFinished) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Selesaikan modul saat ini terlebih dahulu untuk melanjutkan ke modul berikutnya.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _switchSession(nextId);
  }

  void _switchSession(String newSessionId) {
    _readingTimer?.cancel();
    setState(() {
      _currentSessionId = newSessionId;
      _isSessionFinished = false;
      _isUnlocked = false;
      _currentProgressFraction = 0.0;
      _maxWatchedSeconds = 0;
      _quizSubmitted = false;
      _selectedQuizOptionId = null;
      _remainingReadingSeconds = _requiredReadingSeconds;
    });
    _loadSessionAndPlayer();
  }

  // ── 4. Main Build Method ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isMaterial = _sessionType.toUpperCase() == 'MATERIAL';

    return Scaffold(
      backgroundColor: isMaterial ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isMaterial ? Colors.white : const Color(0xFF0D1117),
        foregroundColor: isMaterial ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: isMaterial
            ? const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              )
            : null,
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
                  color: isMaterial
                      ? const Color(0xFFF1F5F9)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: isMaterial ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: isMaterial ? const Color(0xFF0F172A) : Colors.white,
                  ),
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
                color: isMaterial ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                color: isMaterial ? const Color(0xFF0F172A) : Colors.white,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top: Video Frame or Media Banner
            _buildTopMediaFrame(),

            // Bottom: Tab Container & Tab Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: isMaterial ? null : const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: isMaterial
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: isMaterial ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Column(
                    children: [
                      // Modern Segmented Tab Header
                      _buildBrowserCardTabs(),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            KeyedSubtree(
                              key: const ValueKey('tab_overview'),
                              child: _buildOverviewTab(),
                            ),
                            KeyedSubtree(
                              key: const ValueKey('tab_notes'),
                              child: _buildNotesTab(),
                            ),
                            KeyedSubtree(
                              key: const ValueKey('tab_qna'),
                              child: _buildQnaTab(),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Navigation Bar (3D Tactile Push-Down Buttons)
                      _buildBottomActionDock(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modern Segmented Tab Header ───────────────────────────────────────────
  Widget _buildBrowserCardTabs() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final activeIndex = _tabController.index;
        final isMaterial = _sessionType.toUpperCase() == 'MATERIAL';

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _buildCardTabItem(
                index: 0,
                label: isMaterial ? 'Materi' : 'Ringkasan',
                icon: Icons.menu_book_rounded,
                isActive: activeIndex == 0,
              ),
              const SizedBox(width: 8),
              _buildCardTabItem(
                index: 1,
                label: 'Catatan',
                icon: Icons.edit_note_rounded,
                isActive: activeIndex == 1,
              ),
              const SizedBox(width: 8),
              _buildCardTabItem(
                index: 2,
                label: 'Tanya Jawab',
                icon: Icons.chat_bubble_outline_rounded,
                isActive: activeIndex == 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardTabItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabController.index != index) {
            FocusScope.of(context).unfocus();
            _tabController.animateTo(index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? AppColors.primary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? AppColors.primary : const Color(0xFF64748B),
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Media Frame: Video vs Non-Video ───────────────────────────────────
  Widget _buildTopMediaFrame() {
    if (_sessionType.toUpperCase() == 'MATERIAL') {
      return const SizedBox.shrink();
    }

    if (_sessionType != 'VIDEO') {
      final isMaterial = _sessionType == 'MATERIAL';
      final isQuiz = _sessionType == 'QUIZ';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Micro Tag Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isMaterial
                        ? const Color(0xFFFFDD00)
                        : (isQuiz ? AppColors.primary : const Color(0xFFEF4444)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMaterial
                            ? Icons.menu_book_rounded
                            : (isQuiz ? Icons.quiz_rounded : Icons.videocam_rounded),
                        size: 11,
                        color: isMaterial ? const Color(0xFF0D1117) : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMaterial
                            ? 'BACAAN MATERI'
                            : (isQuiz ? 'KUIS PEMAHAMAN' : 'LIVE CLASS'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isMaterial ? const Color(0xFF0D1117) : Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.courseTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Main Editorial Title
            Text(
              _currentTitle ?? widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Reading Meta Capsules Row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildEditorialMetaPill(
                  icon: Icons.timer_outlined,
                  label: isMaterial
                      ? (_requiredReadingSeconds > 0
                          ? '${(_requiredReadingSeconds / 60).ceil()} Menit Baca'
                          : 'Bacaan Mandiri')
                      : (isQuiz ? '5 Soal' : 'Live Meet'),
                ),
                _buildEditorialMetaPill(
                  icon: Icons.stars_rounded,
                  label: '+$_xpReward XP',
                  isAccent: true,
                ),
              ],
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 32),
                          const SizedBox(height: 6),
                          Text(
                            (_playerErrorMessage ?? '').contains('ERR_NAME_NOT_RESOLVED')
                                ? 'Video sedang bersiap atau koneksi terputus.\nSilakan coba lagi atau buka melalui browser.'
                                : (_playerErrorMessage ?? 'Gagal memuat video.'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11.5, height: 1.3),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TactileMetroButton.primary(
                                onPressed: _initAppropriatePlayer,
                                icon: Icons.refresh_rounded,
                                text: 'Coba Lagi',
                                height: 34,
                                fontSize: 11.5,
                                isFullWidth: false,
                                borderRadius: BorderRadius.circular(8),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              if (_currentVideoUrl != null && _currentVideoUrl!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                TactileMetroButton(
                                  onPressed: () async {
                                    final uri = Uri.tryParse(_currentVideoUrl!);
                                    if (uri != null) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: Icons.open_in_browser_rounded,
                                  text: 'Buka di Browser',
                                  height: 34,
                                  fontSize: 11,
                                  isFullWidth: false,
                                  backgroundColor: const Color(0xFF1E293B),
                                  baseColor: const Color(0xFF0F172A),
                                  textColor: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                              ],
                            ],
                          ),
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

  Widget _buildEditorialMetaPill({
    required IconData icon,
    required String label,
    bool isAccent = false,
    bool isLight = false,
  }) {
    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final Color textColor;

    if (isLight) {
      if (isAccent) {
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        iconColor = const Color(0xFFD97706);
        textColor = const Color(0xFF92400E);
      } else {
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
        iconColor = const Color(0xFF64748B);
        textColor = const Color(0xFF334155);
      }
    } else {
      if (isAccent) {
        bgColor = const Color(0xFFFFDD00).withValues(alpha: 0.15);
        borderColor = const Color(0xFFFFDD00).withValues(alpha: 0.4);
        iconColor = const Color(0xFFFFDD00);
        textColor = const Color(0xFFFFDD00);
      } else {
        bgColor = Colors.white.withValues(alpha: 0.08);
        borderColor = Colors.white.withValues(alpha: 0.12);
        iconColor = const Color(0xFFCBD5E1);
        textColor = const Color(0xFFE2E8F0);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isAccent ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Overview / Modul Content ───────────────────────────────────────
  Widget _buildOverviewTab() {
    if (_isLoadingSessionData) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // For VIDEO, show the Session Title & Course Title Header
          if (_sessionType == 'VIDEO') ...[
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

            // Clean Minimalist 4px Progress Bar with Metro Primary Green
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _currentProgressFraction,
                minHeight: 4,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // For MATERIAL, show an elegant in-app reading header card
          if (_sessionType == 'MATERIAL') ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAE653),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 11, color: Color(0xFF063D2A)),
                            const SizedBox(width: 4),
                            Text(
                              'BACAAN MATERI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF063D2A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.courseTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentTitle ?? widget.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildEditorialMetaPill(
                        icon: Icons.timer_outlined,
                        label: _requiredReadingSeconds > 0
                            ? '${(_requiredReadingSeconds / 60).ceil()} Menit Baca'
                            : 'Bacaan Mandiri',
                        isLight: true,
                      ),
                      _buildEditorialMetaPill(
                        icon: Icons.stars_rounded,
                        label: '+$_xpReward XP',
                        isAccent: true,
                        isLight: true,
                      ),
                      if (_isSessionFinished)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Selesai Dibaca',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],

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
                'Tentang Sesi Ini',
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

  // ── Material / Reading Module: In-App Clean Reading ────────────────────────
  Widget _buildMaterialContent() {
    final hasCustomContent = _sessionDescription != null && _sessionDescription!.trim().isNotEmpty;

    if (hasCustomContent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildFormattedArticleBlocks(_sessionDescription!.trim()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded, size: 36, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'Modul Bacaan Siap Dipelajari',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Belum ada isi materi yang ditambahkan untuk modul ini.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Formatted Article Blocks & Markdown Parser for Mobile ──────────────────
  List<Widget> _buildFormattedArticleBlocks(String content) {
    final List<Widget> widgets = [];
    final lines = content.split('\n');
    int i = 0;

    final normalStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: const Color(0xFF334155),
      height: 1.75,
    );

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        i++;
        continue;
      }

      // Horizontal Divider: --- or *** or ___
      if (RegExp(r'^([-*_]){3,}$').hasMatch(trimmed)) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: Color(0xFFE2E8F0), thickness: 1.2),
        ));
        i++;
        continue;
      }

      // Headings: #, ##, ###, ####
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final titleText = headingMatch.group(2)!;

        double fontSize;
        FontWeight fontWeight;
        double topPadding;
        double bottomPadding;

        if (level == 1) {
          fontSize = 19;
          fontWeight = FontWeight.w800;
          topPadding = 18;
          bottomPadding = 8;
        } else if (level == 2) {
          fontSize = 17;
          fontWeight = FontWeight.w800;
          topPadding = 16;
          bottomPadding = 6;
        } else if (level == 3) {
          fontSize = 15.5;
          fontWeight = FontWeight.w700;
          topPadding = 14;
          bottomPadding = 6;
        } else {
          fontSize = 14.5;
          fontWeight = FontWeight.w700;
          topPadding = 12;
          bottomPadding = 4;
        }

        widgets.add(Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          child: RichText(
            text: TextSpan(
              children: _parseInlineSpans(
                titleText,
                GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: const Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
            ),
          ),
        ));
        i++;
        continue;
      }

      // Blockquote: > text
      if (line.startsWith('> ')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].startsWith('> ')) {
          quoteLines.add(lines[i].substring(2).trim());
          i++;
        }
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: AppColors.primary, width: 3.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: quoteLines.map((ql) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: RichText(
                text: TextSpan(
                  children: _parseInlineSpans(
                    ql,
                    GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF166534),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ));
        continue;
      }

      // Unordered list: - or *
      if (RegExp(r'^\s*[-*•]\s+').hasMatch(line)) {
        final listItems = <String>[];
        while (i < lines.length && RegExp(r'^\s*[-*•]\s+').hasMatch(lines[i])) {
          listItems.add(lines[i].replaceFirst(RegExp(r'^\s*[-*•]\s+'), '').trim());
          i++;
        }
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 10),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: _parseInlineSpans(item, normalStyle),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ));
        continue;
      }

      // Ordered list: 1. 2. 3.
      if (RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
        final listItems = <Map<String, String>>[];
        while (i < lines.length && RegExp(r'^\s*(\d+)\.\s+(.*)').hasMatch(lines[i])) {
          final m = RegExp(r'^\s*(\d+)\.\s+(.*)').firstMatch(lines[i])!;
          listItems.add({'num': m.group(1)!, 'text': m.group(2)!});
          i++;
        }
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${item['num']}.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: _parseInlineSpans(item['text']!, normalStyle),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ));
        continue;
      }

      // Normal paragraph
      final paragraphLines = <String>[];
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !RegExp(r'^([-*_]){3,}$').hasMatch(lines[i].trim()) &&
          !RegExp(r'^(#{1,6})\s+').hasMatch(lines[i]) &&
          !lines[i].startsWith('> ') &&
          !RegExp(r'^\s*[-*•]\s+').hasMatch(lines[i]) &&
          !RegExp(r'^\s*\d+\.\s+').hasMatch(lines[i])) {
        paragraphLines.add(lines[i]);
        i++;
      }

      final combined = paragraphLines.join('\n');
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RichText(
          text: TextSpan(
            children: _parseInlineSpans(combined, normalStyle),
          ),
        ),
      ));
    }

    return widgets;
  }

  List<TextSpan> _parseInlineSpans(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final pattern = RegExp(r'(\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`)');
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final fullMatch = match.group(0)!;
      if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ));
      } else if (fullMatch.startsWith('*') && fullMatch.endsWith('*')) {
        spans.add(TextSpan(
          text: match.group(3),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        spans.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: const Color(0xFFF1F5F9),
            color: const Color(0xFF0F172A),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
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
            final raw = _materials[idx];
            final mat = raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};
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
                  TactileMetroButton.primary(
                    onPressed: () {
                      if (fileUrl.isNotEmpty) {
                        launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icons.download_rounded,
                    text: 'Buka',
                    height: 38,
                    fontSize: 12.5,
                    isFullWidth: false,
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
    // Detect format: whether _quizOptions has nested question objects or flat options
    final List<dynamic> sourceOptions = _quizOptions.isNotEmpty
        ? _quizOptions
        : [
            {
              'question': 'Apa perbedaan mendasar antara UI (User Interface) dan UX (User Experience)?',
              'options': [
                {
                  'id': 'a',
                  'text': 'UI berfokus pada estetika visual & layout antarmuka, sedangkan UX berfokus pada kemudahan, alur, dan pengalaman pengguna secara menyeluruh.',
                  'isCorrect': true,
                },
                {
                  'id': 'b',
                  'text': 'UI hanya untuk website di komputer desktop, sedangkan UX hanya untuk aplikasi mobile smartphone.',
                  'isCorrect': false,
                },
                {
                  'id': 'c',
                  'text': 'UI dibuat oleh programmer backend server, sedangkan UX dibuat oleh tim administrasi.',
                  'isCorrect': false,
                },
                {
                  'id': 'd',
                  'text': 'UI dan UX adalah dua istilah identik tanpa ada perbedaan fungsi apapun.',
                  'isCorrect': false,
                },
              ],
            }
          ];

    String? questionTitle;
    List<Map<String, dynamic>> optionsList = [];

    final firstItem = sourceOptions.first;
    if (firstItem is Map && firstItem.containsKey('options') && firstItem['options'] is List) {
      questionTitle = firstItem['question']?.toString();
      final nestedList = firstItem['options'] as List;
      for (int i = 0; i < nestedList.length; i++) {
        final opt = nestedList[i];
        if (opt is Map) {
          optionsList.add(opt.cast<String, dynamic>());
        }
      }
    } else {
      for (int i = 0; i < sourceOptions.length; i++) {
        final opt = sourceOptions[i];
        if (opt is Map) {
          optionsList.add(opt.cast<String, dynamic>());
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (questionTitle != null && questionTitle.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Text(
              questionTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.5,
              ),
            ),
          ),
        ],
        ...optionsList.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final optId = option['id']?.toString() ?? '$idx';
          final rawText = option['text'] ?? option['label'] ?? option['title'] ?? option['answer'];
          final text = (rawText != null && rawText.toString().trim().isNotEmpty)
              ? rawText.toString()
              : 'Pilihan ${String.fromCharCode(65 + idx)}';
          final isSelected = _selectedQuizOptionId == optId;
          final letter = String.fromCharCode(65 + idx);

          return GestureDetector(
            onTap: _quizSubmitted ? null : () => setState(() => _selectedQuizOptionId = optId),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: isSelected ? 2.0 : 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF0F172A),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _submitQuizAnswer() {
    if (_selectedQuizOptionId == null) return;

    List<Map<String, dynamic>> optionsList = [];
    final firstItem = _quizOptions.first;
    if (firstItem is Map<String, dynamic> && firstItem.containsKey('options') && firstItem['options'] is List) {
      final nestedList = firstItem['options'] as List;
      for (int i = 0; i < nestedList.length; i++) {
        final opt = nestedList[i];
        if (opt is Map<String, dynamic>) optionsList.add(opt);
      }
    } else {
      for (int i = 0; i < _quizOptions.length; i++) {
        final opt = _quizOptions[i];
        if (opt is Map<String, dynamic>) optionsList.add(opt);
      }
    }

    final selected = optionsList.firstWhere(
      (o) => (o['id']?.toString() ?? '') == _selectedQuizOptionId,
      orElse: () => {},
    );
    final isCorrect = selected['isCorrect'] == true;

    setState(() {
      _quizSubmitted = true;
      if (isCorrect) _isUnlocked = true;
    });

    if (isCorrect) {
      if (!_isSessionFinished) {
        _handleCompleteSession();
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Jawaban belum tepat, silakan coba lagi.'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _quizSubmitted = false;
          });
        }
      });
    }
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
          if (_isLiveEnded)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.videocam_off_rounded, color: Color(0xFF64748B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sesi Live Telah Berakhir',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sesi tatap muka Google Meet telah usai. Rekaman materi dan kuis tetap dapat diakses.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_liveMeetingUrl != null && _liveMeetingUrl!.isNotEmpty)
            TactileMetroButton.primary(
              onPressed: () => launchUrl(Uri.parse(_liveMeetingUrl!), mode: LaunchMode.externalApplication),
              icon: Icons.videocam_rounded,
              text: 'Masuk Sesi Google Meet / Zoom',
              height: 48,
              borderRadius: BorderRadius.circular(14),
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
              TactileMetroIconButton(
                size: 38,
                iconSize: 18,
                borderRadius: BorderRadius.circular(19),
                backgroundColor: AppColors.primary,
                baseColor: const Color(0xFF015F3D),
                icon: Icons.arrow_upward_rounded,
                iconColor: Colors.white,
                onPressed: () async {
                  final text = _noteInputController.text.trim();
                  if (text.isEmpty || widget.courseId == null || _currentSessionId == null) return;
                  _noteInputController.clear();
                  try {
                    await _courseDs.createSessionNote(widget.courseId!, _currentSessionId!, text);
                    _loadNotes();
                  } catch (_) {}
                },
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
              TactileMetroIconButton(
                size: 38,
                iconSize: 18,
                borderRadius: BorderRadius.circular(19),
                backgroundColor: AppColors.primary,
                baseColor: const Color(0xFF015F3D),
                icon: Icons.arrow_upward_rounded,
                iconColor: Colors.white,
                onPressed: () async {
                  final text = _qnaInputController.text.trim();
                  if (text.isEmpty || widget.courseId == null || _currentSessionId == null) return;
                  _qnaInputController.clear();
                  try {
                    await _courseDs.createSessionQna(widget.courseId!, _currentSessionId!, text);
                    _loadQna();
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Dock: 3D Tactile Push-Down Buttons ──────────────────────
  Widget _buildBottomActionDock() {
    final bool isQuiz = _sessionType == 'QUIZ';
    final bool isMaterial = _sessionType == 'MATERIAL';
    final bool canCompleteMaterial = isMaterial && (_isUnlocked || _remainingReadingSeconds <= 0);
    final bool canCompleteVideo = _isUnlocked || _currentProgressFraction >= 0.95;
    final bool canSubmitQuiz = _selectedQuizOptionId != null;
    final bool isActionActive = isQuiz
        ? canSubmitQuiz
        : (isMaterial ? canCompleteMaterial : canCompleteVideo);
    final bool canGoNext = _isSessionFinished;

    final String buttonLabel = _isSessionFinished
        ? 'Selesai'
        : (isQuiz
            ? 'Kirim Jawaban'
            : (isMaterial
                ? (_remainingReadingSeconds > 0
                    ? 'Baca min. ${(_requiredReadingSeconds / 60).ceil()}m (${_formatReadingTime(_remainingReadingSeconds)})'
                    : 'Selesaikan Modul')
                : 'Selesaikan Modul'));

    final VoidCallback? onMainPressed = _isSessionFinished
        ? null
        : (isQuiz
            ? (canSubmitQuiz ? _submitQuizAnswer : null)
            : (isMaterial
                ? (canCompleteMaterial
                    ? (_isSubmittingProgress ? null : _handleCompleteSession)
                    : () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Harap baca modul dengan saksama. Tombol aktif dalam ${_formatReadingTime(_remainingReadingSeconds)}.',
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      })
                : (canCompleteVideo
                    ? (_isSubmittingProgress ? null : _handleCompleteSession)
                    : () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Simak materi video sampai tuntas terlebih dahulu.'),
                            backgroundColor: const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      })));

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
          // Prev Button (3D Tactile Push)
          if (_prevSessionId != null) ...[
            TactileMetroIconButton(
              onPressed: () => _goToPrevSession(_prevSessionId!),
              icon: Icons.chevron_left_rounded,
              iconColor: const Color(0xFF334155),
              backgroundColor: Colors.white,
              baseColor: const Color(0xFFCBD5E1),
              borderColor: const Color(0xFFE2E8F0),
            ),
            const SizedBox(width: 10),
          ],

          // Main Action CTA (3D Tactile Push-Down with Metro Palette)
          Expanded(
            child: _isSessionFinished
                ? TactileMetroButton(
                    onPressed: null,
                    isDisabled: true,
                    backgroundColor: AppColors.primary,
                    baseColor: const Color(0xFF015F3D),
                    borderColor: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Selesai',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  )
                : TactileMetroButton(
                    onPressed: onMainPressed,
                    isDisabled: !isActionActive,
                    backgroundColor: isActionActive ? AppColors.primary : const Color(0xFFF1F5F9),
                    baseColor: isActionActive ? const Color(0xFF015F3D) : const Color(0xFFCBD5E1),
                    borderColor: isActionActive ? null : const Color(0xFFE2E8F0),
                    child: _isSubmittingProgress
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            buttonLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: isActionActive ? Colors.white : const Color(0xFF94A3B8),
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
          ),

          // Next Button (3D Tactile Push)
          if (_nextSessionId != null) ...[
            const SizedBox(width: 10),
            TactileMetroIconButton(
              onPressed: canGoNext ? () => _goToNextSession(_nextSessionId!) : null,
              isDisabled: !canGoNext,
              icon: Icons.chevron_right_rounded,
              iconColor: canGoNext ? Colors.white : const Color(0xFF94A3B8),
              backgroundColor: canGoNext ? AppColors.primary : const Color(0xFFF1F5F9),
              baseColor: canGoNext ? const Color(0xFF015F3D) : const Color(0xFFCBD5E1),
              borderColor: canGoNext ? null : const Color(0xFFE2E8F0),
            ),
          ],
        ],
      ),
    );
  }
}

