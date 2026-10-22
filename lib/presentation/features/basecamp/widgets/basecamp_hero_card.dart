import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampHeroCard — "My Lesson / Lanjutkan Belajar" Card.
/// Styled like "My lesson" from Reference Image:
/// Soft pastel container with crisp defined border, squircle tags, and dark pill action button.
/// Strictly maps to web basecamp data: continueLearning or empty state with Bootcamp/Course search.
class BasecampHeroCard extends StatelessWidget {
  final Map<String, dynamic>? continueLearning;

  const BasecampHeroCard({super.key, this.continueLearning});

  @override
  Widget build(BuildContext context) {
    if (continueLearning == null) {
      return _buildEmptyStateCard(context);
    }

    final title = continueLearning?['title'] as String? ?? 'Kelas Digital';
    final sessionTitle = continueLearning?['sessionTitle'] as String? ?? 'Lanjutkan Belajar';
    final rawProgress = (continueLearning?['progress'] as num?)?.toDouble() ?? 0.0;
    final progress = (rawProgress / 100).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    final sessionId = continueLearning?['sessionId'] as String? ?? '';
    final type = continueLearning?['type'] as String? ?? 'mini-course';
    final courseId = continueLearning?['id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, // Clean white card (no purple)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lanjutkan Belajar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.learn),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Inner Squircle Content (Image 2 style)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row: Upcoming & Type Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type == 'bootcamp' ? 'BOOTCAMP' : 'MINI COURSE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$percent% Selesai',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Course Title & Session
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  sessionTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Slim Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                  ),
                ),

                const SizedBox(height: 14),

                // Action Button: Clean Dark Pill Button
                Material(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () {
                      if (sessionId.isNotEmpty) {
                        context.push(AppRoutes.learningPlayer.replaceAll(':sessionId', sessionId));
                      } else if (courseId.isNotEmpty) {
                        context.push(
                          AppRoutes.courseDetail.replaceAll(':id', courseId),
                          extra: {
                            'id': courseId,
                            'title': title,
                            'isBootcamp': type == 'bootcamp',
                            'isEnrolled': true,
                          },
                        );
                      } else {
                        context.go(AppRoutes.learn);
                      }
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lanjutkan Belajar',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state matching 1:1 with web mentee basecamp:
  /// "Mulai Perjalananmu - Belum ada kelas aktif" with "Cari Bootcamp" and "Cari Mini Course"
  Widget _buildEmptyStateCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9EE), // Warm pastel vanilla
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'MULAI PERJALANANMU',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada kelas aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Eksplorasi Bootcamp atau Mini Course untuk memulai perjalanan belajarmu.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.learn),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 38,
                      alignment: Alignment.center,
                      child: Text(
                        'Cari Bootcamp',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.learn),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Text(
                        'Cari Mini Course',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
