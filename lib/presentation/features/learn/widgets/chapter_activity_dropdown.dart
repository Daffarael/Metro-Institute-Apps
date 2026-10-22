import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChapterActivityDropdown
///
/// Beautiful, animated accordion dropdown for Course / Bootcamp Chapters & Sessions,
/// inspired by the ActivityDropdown UI & animation spec:
/// • Animated rounded-2xl (18px) to rounded-3xl (26px) container transition (500ms easeInOutCubic).
/// • Header with rounded-xl square icon badge, bold chapter title, and collapsing subtitle when opened.
/// • Smooth rotating ChevronUp (180° when closed, 0° when open).
/// • Staggered slide-up + fade-in animation for each session item (like translate-y-4 opacity-0 to translate-y-0 opacity-100).
/// • Sleek session rows with 40x40 icon badge, title, subtitle description, duration, and preview badge.
class ChapterActivityDropdown extends StatefulWidget {
  final int index;
  final Map<String, dynamic> chapter;
  final bool isExpanded;
  final String? activeSessionId;
  final VoidCallback onToggle;
  final ValueChanged<Map<String, dynamic>> onSelectSession;

  const ChapterActivityDropdown({
    super.key,
    required this.index,
    required this.chapter,
    required this.isExpanded,
    this.activeSessionId,
    required this.onToggle,
    required this.onSelectSession,
  });

  @override
  State<ChapterActivityDropdown> createState() => _ChapterActivityDropdownState();
}

class _ChapterActivityDropdownState extends State<ChapterActivityDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ChapterActivityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getChapterIcon(int index) {
    const icons = [
      Icons.auto_stories_rounded,
      Icons.menu_book_rounded,
      Icons.layers_outlined,
      Icons.lightbulb_outline_rounded,
      Icons.emoji_events_outlined,
      Icons.code_rounded,
      Icons.explore_outlined,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chapter['title'] as String? ?? 'Bab ${widget.index + 1}';
    final sessions = (widget.chapter['sessions'] as List?) ?? [];

    // Sum videoDuration in seconds
    int totalSec = 0;
    for (final s in sessions) {
      if (s is Map<String, dynamic>) {
        final sec = s['videoDuration'];
        if (sec is num) totalSec += sec.toInt();
      }
    }
    final durationStr = totalSec > 0
        ? '${(totalSec / 60).round()} min'
        : (sessions.isNotEmpty ? '${sessions.length * 15} min' : '15 min');

    final lessonCountStr = '${sessions.length} sesi';
    final badgeIcon = _getChapterIcon(widget.index);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isFullyClosed = _controller.isDismissed;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.isExpanded ? 26 : 18),
            border: Border.all(
              color: widget.isExpanded ? const Color(0xFFD6CBC0) : const Color(0xFFEADBCE),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isExpanded ? const Color(0x12000000) : const Color(0x08000000),
                blurRadius: widget.isExpanded ? 18 : 10,
                offset: Offset(0, widget.isExpanded ? 5 : 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── 1. HEADER (Click to expand/collapse) ──────────────────────
              InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.circular(widget.isExpanded ? 26 : 18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Square Icon Box (h-12 w-12 rounded-xl)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFEB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            badgeIcon,
                            color: const Color(0xFF1E1B18),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Collapsing Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF1E1B18),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Subtitle collapses on open (opacity-0 max-h-0)
                            ClipRect(
                              child: Align(
                                alignment: Alignment.topLeft,
                                heightFactor: (1.0 - _expandAnimation.value).clamp(0.0, 1.0),
                                child: Opacity(
                                  opacity: (1.0 - _expandAnimation.value * 2.0).clamp(0.0, 1.0),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '$lessonCountStr • $durationStr',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF8C827A),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Chevron Icon (Rotates 180° when closed, 0° when open)
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: AnimatedRotation(
                          turns: widget.isExpanded ? 0.0 : 0.5,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Color(0xFF8C827A),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. DROPDOWN ACTIVITY LIST (Animated Size & Staggered items) ──
              if (!isFullyClosed && sessions.isNotEmpty)
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    child: Column(
                      children: [
                        // Subtle hairline divider
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: const Color(0xFFF2ECE4),
                        ),

                        // Staggered animated session items
                        ...sessions.asMap().entries.map((sEntry) {
                          final sIdx = sEntry.key;
                          final session = sEntry.value as Map<String, dynamic>;
                          return _buildAnimatedSessionItem(sIdx, session, sessions.length);
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSessionItem(int index, Map<String, dynamic> session, int totalCount) {
    final sTitle = session['title'] as String? ?? 'Sesi ${index + 1}';
    final sSec = session['videoDuration'] as int? ?? 0;
    final sDuration = sSec > 0 ? '${(sSec / 60).round()} min' : 'Materi';
    final isCurrent = widget.activeSessionId != null &&
        widget.activeSessionId == session['id']?.toString();
    final isFreePreview = session['isFreePreview'] == true;
    final rawType = (session['type'] ?? session['sessionType'] ?? 'VIDEO').toString().toUpperCase();

    // Clean description
    final rawDesc = (session['description'] ?? session['assignmentDescription'] ?? '').toString();
    final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final sDesc = cleanDesc.isNotEmpty ? cleanDesc : 'Materi video pembelajaran';

    // Staggered interval: index * 0.08
    final start = (index * 0.08).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.4, 1.0);
    final itemCurve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeInOutCubic),
    );

    return AnimatedBuilder(
      animation: itemCurve,
      builder: (context, child) {
        return Opacity(
          opacity: itemCurve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1.0 - itemCurve.value)), // translate-y-4 to translate-y-0
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSelectSession(session),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFFF7F0E8) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isCurrent
                  ? Border.all(color: const Color(0xFFD6CBC0), width: 1)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Box (h-10 w-10 rounded-xl)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFF1E1B18) : const Color(0xFFF2E9DE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCurrent
                        ? Icons.play_arrow_rounded
                        : (rawType == 'QUIZ'
                            ? Icons.quiz_outlined
                            : (rawType == 'LIVE'
                                ? Icons.videocam_outlined
                                : Icons.play_circle_outline_rounded)),
                    color: isCurrent ? Colors.white : const Color(0xFF5A524C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Subtitle Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sTitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E1B18),
                          fontSize: 13.5,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sDesc,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF8C827A),
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

                // Right Duration / Time & Preview Pill
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sDuration,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF9E948A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isFreePreview) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Preview',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF15803D),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
