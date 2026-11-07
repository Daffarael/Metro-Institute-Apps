import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/webinar_remote_datasource.dart';

/// BasecampInspireTalkCard — Card khusus "Inspire Talk"
/// Styled 1:1 with the reference design (Royal Purple #6B37EB with signature avatar notch cutout):
/// • Floating circular speaker portrait nested inside an organic concave notch cutout on top-left.
/// • Top row: "[📖/🎙️] Inspire Talk" pill tag and "[⋮]" circular option button.
/// • Centered schedule ("Mon 14:30 PM || Zoom") and field category pill ("[UI/UX Design]").
/// • Bold headline ("UX & Web Design Course" / dynamic Inspire Talk title).
/// • Duration & rating metadata ("2 Jam Sesi  4.9 Rating").
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
      'id': 'inspire-talk-s2-01',
      'title': 'UX & Web Design Course',
      'speakerName': 'Alexander Smith',
      'speakerRole': 'Lead Product Designer',
      'speakerAvatarUrl':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=200&auto=format&fit=crop&q=80',
      'field': 'UI/UX Design',
      'scheduledAt': 'Sabtu, 19:30 WIB',
      'platform': 'Zoom',
      'duration': '2 Jam Sesi',
      'rating': '4.9 Rating',
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _talk ?? _defaultTalkData();
    final title = data['title'] as String? ?? 'UX & Web Design Course';
    final speakerAvatar = data['speakerAvatarUrl'] as String? ??
        'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=200&auto=format&fit=crop&q=80';
    final field = data['field']?.toString() ?? 'UI/UX Design';
    final rawDate = data['scheduledAt']?.toString() ?? 'Sabtu, 19:30 WIB';
    final platform = data['platform']?.toString() ?? 'Zoom';
    final scheduleText = '$rawDate || $platform';
    final duration = data['duration'] != null
        ? '${data['duration']} Menit'
        : '2 Jam Sesi';
    final rating = data['rating']?.toString() ?? '4.9 Rating';

    const clipper = _InspireTalkNotchClipper(
      cornerRadius: 36.0,
      notchSize: 88.0,
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
                          // ── Top Row: Space for cutout + "Inspire Talk" Tag + Options [⋮] ──
                          Row(
                            children: [
                              // Clearance for avatar notch on the left
                              const SizedBox(width: 78),

                              // Tag pill: [🎙️/📖] Inspire Talk
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
                                      'Inspire Talk',
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
                              fontSize: 20,
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
                              Container(
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
            left: 2,
            top: 2,
            child: GestureDetector(
              onTap: _handleOpenDetail,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x240F172A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: speakerAvatar,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 30),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3 Overlapping attendee avatar portraits + white "+12" pill
  Widget _buildAttendeeStack() {
    const attendees = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&auto=format&fit=crop&q=80',
    ];

    return SizedBox(
      height: 34,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 68,
            height: 34,
            child: Stack(
              children: List.generate(attendees.length, (index) {
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
                      child: CachedNetworkImage(
                        imageUrl: attendees[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFCBD5E1),
                          child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
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
/// with rounded corners on the other 3 corners (r = 36).
class _InspireTalkNotchClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchSize;

  const _InspireTalkNotchClipper({
    this.cornerRadius = 36.0,
    this.notchSize = 88.0,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final n = notchSize;

    final path = Path();
    // 1. Top edge starting after the notch
    path.moveTo(n, 0);

    // 2. Top-right rounded corner
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));

    // 3. Right edge to bottom-right corner
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    // 4. Bottom edge to bottom-left corner
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));

    // 5. Left edge up to notch boundary
    path.lineTo(0, n);

    // 6. Smooth organic notch around the avatar:
    // Curves from (0, n) inwards around avatar and joins top edge at (n, 0)
    path.cubicTo(0, n - 18, 12, n - 18, 24, n - 22);
    path.cubicTo(55, n - 32, n - 32, 55, n - 22, 24);
    path.cubicTo(n - 18, 12, n - 18, 0, n, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _InspireTalkNotchClipper oldDelegate) =>
      oldDelegate.cornerRadius != cornerRadius || oldDelegate.notchSize != notchSize;
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
