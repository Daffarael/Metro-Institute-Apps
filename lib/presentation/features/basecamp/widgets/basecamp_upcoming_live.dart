import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/widgets/live_join_confirm_dialog.dart';

/// BasecampUpcomingLive — Displays real upcoming live sessions from web mentee basecamp (Jadwal Live Terdekat).
/// Only renders if upcomingLive is not empty.
class BasecampUpcomingLive extends StatelessWidget {
  final List upcomingLive;

  const BasecampUpcomingLive({super.key, required this.upcomingLive});

  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      return '$day $month $year';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (upcomingLive.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    // Hanya tampilkan sesi yang jadwalnya belum berakhir (integrasi jadwal nyata)
    final validUpcoming = upcomingLive.where((live) {
      if (live is! Map<String, dynamic>) return false;
      final scheduledAt = live['scheduledAt']?.toString() ?? '';
      if (scheduledAt.isEmpty) return true;
      final dt = DateTime.tryParse(scheduledAt)?.toLocal();
      if (dt == null) return true;
      final duration = (live['durationMinutes'] as num?)?.toInt() ?? 90;
      return now.isBefore(dt.add(Duration(minutes: duration)));
    }).toList();

    if (validUpcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Jadwal Live Terdekat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: validUpcoming.map((live) {
              final raw = live as Map<String, dynamic>;
              final title = raw['title'] as String? ?? 'Sesi Live Mentoring';
              final scheduledAt = raw['scheduledAt']?.toString() ?? '';
              final liveUrl = raw['liveUrl']?.toString() ?? '';

              DateTime? dt;
              int duration = 90;
              bool isPast = false;
              if (scheduledAt.isNotEmpty) {
                dt = DateTime.tryParse(scheduledAt)?.toLocal();
                duration = (raw['durationMinutes'] as num?)?.toInt() ?? 90;
                if (dt != null) {
                  isPast = now.isAfter(dt.add(Duration(minutes: duration)));
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Clean soft slate container with dark navy videocam icon (no red/pink)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (scheduledAt.isNotEmpty)
                            Text(
                              _formatDate(scheduledAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isPast && liveUrl.isNotEmpty)
                      Material(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            LiveJoinConfirmDialog.show(
                              context,
                              meetingUrl: liveUrl,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                            child: Text(
                              'Masuk',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
