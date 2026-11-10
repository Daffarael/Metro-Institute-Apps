import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampHeroCard — Menampilkan HANYA kelas yang sudah dibeli / diikuti oleh mentee.
/// Mengadopsi visual persis dari referensi desain:
/// • Background warna soft pastel rose/pink (#FDECEF) dengan border halus
/// • Aksen starburst lime-green (#C6F24D) dan ilustrasi estetik di sisi kanan
/// • Headline judul kelas tebal & tegas
/// • Teks sebutan progres lesson: "X/Y Lesson Selesai" (e.g. "0/3 Lesson Selesai")
/// • Indikator persentase circular gelap di pojok kanan atas dengan ring pink (e.g. "0%")
/// • Tombol LANJUT di sebelah KIRI berwarna Kuning Metro (#FAE653)
/// • Auto-carousel berganti tiap 5 detik sesuai kelas yang dibeli (urut persentase terendah)
/// • Jika mentee belum beli kelas, widget tidak menampilkan apa-apa.
class BasecampHeroCard extends StatefulWidget {
  final List<Map<String, dynamic>>? courses;
  final Map<String, dynamic>? continueLearning;

  const BasecampHeroCard({
    super.key,
    this.courses,
    this.continueLearning,
  });

  @override
  State<BasecampHeroCard> createState() => _BasecampHeroCardState();
}

class _BasecampHeroCardState extends State<BasecampHeroCard> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  List<Map<String, dynamic>> get _items {
    if (widget.courses != null && widget.courses!.isNotEmpty) {
      return widget.courses!;
    }
    if (widget.continueLearning != null) {
      return [widget.continueLearning!];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _autoPlayTimer?.cancel();
    if (_items.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_currentPage + 1) % _items.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant BasecampHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courses?.length != widget.courses?.length) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (items.length == 1) {
      return _buildSingleCard(context, items.first);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 182,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
              // Reset timer when manually swiped
              _startTimer();
            },
            itemBuilder: (context, index) {
              return _buildSingleCard(context, items[index]);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (idx) {
            final isActive = idx == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF018556) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSingleCard(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] as String?)?.trim().isNotEmpty == true
        ? data['title'] as String
        : 'Bootcamp Metro Institute';

    final rawProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
    final progress = (rawProgress / 100).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    int totalSessions = (data['totalSessions'] as num?)?.toInt() ?? 0;
    int completedSessions = (data['completedSessions'] as num?)?.toInt() ?? 0;

    // Fallback realistis jika backend belum menghitung session count
    if (totalSessions == 0) {
      totalSessions = 3;
      completedSessions = ((percent / 100) * totalSessions).round();
      if (percent > 0 && completedSessions == 0) completedSessions = 1;
    }

    final courseId = data['id']?.toString() ?? '';
    final sessionId = data['sessionId']?.toString() ?? '';
    final isBootcamp = data['type'] == 'bootcamp' || data['isBootcamp'] == true;

    void handleTap() {
      if (sessionId.isNotEmpty) {
        context.push('/learn/player/$sessionId', extra: {
          'courseId': courseId,
          'isBootcamp': isBootcamp,
          'title': data['sessionTitle'] ?? title,
          'courseTitle': title,
          'sessionType': data['sessionType'] ?? data['type'],
        });
      } else if (courseId.isNotEmpty) {
        context.push('/learn/course/$courseId', extra: {
          'id': courseId,
          'title': title,
          'isBootcamp': isBootcamp,
          'isEnrolled': true,
        });
      } else {
        context.go(AppRoutes.learn);
      }
    }

    final rawThumb = (data['thumbnailUrl'] as String?)?.trim().isNotEmpty == true
        ? data['thumbnailUrl'] as String
        : (data['thumbnail'] as String?)?.trim().isNotEmpty == true
            ? data['thumbnail'] as String
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF062316),
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Background Thumbnail Image ────────────────────────
          if (rawThumb != null && rawThumb.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                rawThumb,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF018556),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: const Color(0xFF018556),
              ),
            ),

          // ── Darkening Overlay Gradient ────────────────────────
          // Menyelimuti thumbnail dengan lapisan gelap transparan agar foto terlihat samar di belakang
          // namun teks putih, progress meter, dan tombol LANJUT tetap super tajam & kontras tinggi.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF061810).withValues(alpha: 0.76),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),

          // ── Foreground Content ───────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: handleTap,
              borderRadius: BorderRadius.circular(44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Title + Lesson Count (Left) & Circular Progress Tracker (Right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Title & Lesson count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  height: 1.22,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$completedSessions/$totalSessions Lesson Selesai',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE2F4E9),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Right: Circular Dark Progress Indicator with Kuning Metro Arc
                        _buildCircularProgressIndicator(progress, percent),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Bottom Row: Button LANJUT di SEBELAH KIRI (Kuning Metro)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAE653), // Kuning Metro (#FAE653)
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFF111827),
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LANJUT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  letterSpacing: 0.4,
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
            ),
          ),
        ],
      ),
    );
  }

  /// Circular dark badge with outer Kuning Metro arc
  Widget _buildCircularProgressIndicator(double progress, int percent) {
    return SizedBox(
      width: 66,
      height: 66,
      child: CustomPaint(
        painter: _CircularProgressPainter(progress: progress),
        child: Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$percent',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: '%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFAE653),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter untuk circular progress badge: Dark emerald disk center dengan Kuning Metro arc
class _CircularProgressPainter extends CustomPainter {
  final double progress;

  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dark emerald circular center disk (#063D2A)
    final diskPaint = Paint()
      ..color = const Color(0xFF063D2A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4.5, diskPaint);

    // 2. Track background ring
    final trackPaint = Paint()
      ..color = const Color(0xFFFAE653).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2;
    canvas.drawCircle(center, radius - 2.5, trackPaint);

    // 3. Active Progress Arc (Kuning Metro #FAE653)
    final arcPaint = Paint()
      ..color = const Color(0xFFFAE653)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (progress.clamp(0.02, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
