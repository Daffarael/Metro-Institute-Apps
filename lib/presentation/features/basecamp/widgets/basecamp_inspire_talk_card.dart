import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/webinar_remote_datasource.dart';

/// BasecampInspireTalkCard — Spotlight Card
/// Styled 1:1 with reference design (Royal Purple #6B37EB with signature avatar notch cutout):
/// • Floating circular speaker portrait nested inside an organic concave notch cutout on top-left.
/// • Top row: "[📖] Course 1" pill tag and "[⋮]" circular option button.
/// • Centered schedule ("Mon 14:30 PM || Zoom") and field category pill ("[UI/UX Design]").
/// • Bold headline ("UX & Web Design Course").
/// • Duration & rating metadata ("8 Hours   4.9 Rating").
/// • Bottom row: Overlapping attendee avatar circles with "+12" pill and crisp white "[ Join Class ]" button.
class BasecampInspireTalkCard extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const BasecampInspireTalkCard({super.key, this.initialData});

  @override
  State<BasecampInspireTalkCard> createState() => _BasecampInspireTalkCardState();
}

class _BasecampInspireTalkCardState extends State<BasecampInspireTalkCard> {
  Map<String, dynamic>? _talk;

  @override
  void initState() {
    super.initState();
    _talk = widget.initialData;
    if (_talk == null) {
      _loadLatestInspireTalk();
    }
  }

  Future<void> _loadLatestInspireTalk() async {
    try {
      final ds = sl<WebinarRemoteDataSource>();
      final list = await ds.getWebinars(status: 'UPCOMING');
      if (list.isNotEmpty && mounted) {
        setState(() {
          _talk = list.first as Map<String, dynamic>;
        });
      }
    } catch (_) {
      // Fallback data is displayed seamlessly
    }
  }

  void _handleOpenDetail() {
    final item = _talk ?? _defaultTalkData();
    final id = item['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      context.push('/inspire-talk/$id', extra: item);
    } else {
      context.push(AppRoutes.webinar);
    }
  }

  Map<String, dynamic> _defaultTalkData() {
    return {
      'id': 'course-1-ux-web-design',
      'tag': 'Course 1',
      'title': 'UX & Web Design Course',
      'speakerName': 'Alexander Smith',
      'speakerRole': 'Lead Product Designer',
      'speakerAvatarUrl': 'assets/images/inspire_talk_speaker.png',
      'field': 'UI/UX Design',
      'scheduledAt': 'Mon 14:30 PM',
      'platform': 'Zoom',
      'duration': '8 Hours',
      'rating': '4.9 Rating',
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _talk ?? _defaultTalkData();
    final tag = data['tag'] as String? ?? 'Course 1';
    final title = data['title'] as String? ?? 'UX & Web Design Course';
    final speakerAvatar = data['speakerAvatarUrl'] as String? ?? 'assets/images/inspire_talk_speaker.png';
    final field = data['field']?.toString() ?? 'UI/UX Design';
    final rawDate = data['scheduledAt']?.toString() ?? 'Mon 14:30 PM';
    final platform = data['platform']?.toString() ?? 'Zoom';
    final scheduleText = '$rawDate || $platform';
    final duration = data['duration']?.toString() ?? '8 Hours';
    final rating = data['rating']?.toString() ?? '4.9 Rating';

    const clipper = _InspireTalkNotchClipper(
      cornerRadius: 36.0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── LAYER 1: Shadow & Sculpted Purple Card ──
          CustomPaint(
            painter: const _InspireTalkCardShadowPainter(
              clipper: clipper,
              shadowColor: Color(0x386B37EB),
              elevation: 14.0,
            ),
            child: ClipPath(
              clipper: clipper,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6B37EB), // Royal Purple from reference
                      Color(0xFF5A25D6), // Deep Royal Purple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleOpenDetail,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Top Row: Space for cutout + Tag Pill + Options [⋮] ──
                          Row(
                            children: [
                              // Clearance for avatar notch on the left (20 padding + 86 = 106)
                              const SizedBox(width: 86),

                              // Tag pill: [📖] Course 1
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tag,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // Three dots circular action button [⋮]
                              GestureDetector(
                                onTap: _handleOpenDetail,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Schedule & Zoom Platform ──
                          Text(
                            scheduleText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Field Pill (e.g. UI/UX Design) ──
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              field,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ── Big Talk Headline Title ──
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // ── Duration & Rating Row ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                duration,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                rating,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // ── Bottom Row: Attendee Avatars with "+12" & White "Join Class" Button ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Overlapping attendee circles + "+12"
                              _buildAttendeeStack(),

                              // Right: Crisp White Pill Button [ Join Class ]
                              GestureDetector(
                                onTap: _handleOpenDetail,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Join Class',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF6B37EB),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
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
              ),
            ),
          ),

          // ── LAYER 2: Floating Circular Speaker Avatar inside Notch Cutout ──
          Positioned(
            left: -4,
            top: -4,
            child: GestureDetector(
              onTap: _handleOpenDetail,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E0F172A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildSpeakerImage(speakerAvatar),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds speaker image with offline fallback to the authentic reference portrait
  Widget _buildSpeakerImage(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) => Image.asset(
          'assets/images/inspire_talk_speaker.png',
          fit: BoxFit.cover,
        ),
        errorWidget: (context, _, __) => Image.asset(
          'assets/images/inspire_talk_speaker.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/inspire_talk_speaker.png',
        fit: BoxFit.cover,
      ),
    );
  }

  /// 3 Overlapping attendee avatar portraits + white "+12" pill
  Widget _buildAttendeeStack() {
    const attendeeAssets = [
      'assets/images/inspire_attendee_1.png',
      'assets/images/inspire_attendee_2.png',
      'assets/images/inspire_attendee_3.png',
    ];

    return SizedBox(
      height: 34,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 34,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(attendeeAssets.length, (index) {
                return Positioned(
                  left: index * 18.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        attendeeAssets[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFCBD5E1),
                          child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 4),

          // White circle with "+12" in royal purple
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '+12',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6B37EB),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomClipper that sculpts the signature organic concave notch cutout on top-left,
/// mathematically fitted from reference design (media_1794059228056_2bd1ed1b.jpg),
/// with corner radius = 36 on top-right, bottom-right, and bottom-left.
class _InspireTalkNotchClipper extends CustomClipper<Path> {
  final double cornerRadius;

  const _InspireTalkNotchClipper({
    this.cornerRadius = 36.0,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;

    final path = Path();
    // 1. Top edge starting after the organic notch fillet
    path.moveTo(106.0, 0.0);

    // 2. Top-right rounded corner (r = 36)
    path.lineTo(w - r, 0.0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));

    // 3. Right vertical edge to bottom-right corner (r = 36)
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    // 4. Bottom horizontal edge to bottom-left corner (r = 36)
    path.lineTo(r, h);
    path.arcToPoint(Offset(0.0, h - r), radius: Radius.circular(r));

    // 5. Left vertical edge up to the organic shoulder
    path.lineTo(0.0, 108.0);

    // 6. Signature organic concave notch contouring around speaker avatar:
    // Curve 1: Left shoulder into bottom of the circular cutout
    path.cubicTo(0.0, 88.0, 22.0, 78.0, 48.0, 74.0);

    // Curve 2: Circular cutout arc up to top rounded tab
    path.cubicTo(76.0, 70.0, 82.0, 0.0, 106.0, 0.0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _InspireTalkNotchClipper oldDelegate) =>
      oldDelegate.cornerRadius != cornerRadius;
}

/// CustomPainter for the smooth drop shadow following the clipped notch card path
class _InspireTalkCardShadowPainter extends CustomPainter {
  final _InspireTalkNotchClipper clipper;
  final Color shadowColor;
  final double elevation;

  const _InspireTalkCardShadowPainter({
    required this.clipper,
    required this.shadowColor,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    canvas.drawShadow(path, shadowColor, elevation, false);
  }

  @override
  bool shouldRepaint(covariant _InspireTalkCardShadowPainter oldDelegate) => false;
}
