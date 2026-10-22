import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampActiveCourses — Shows user's real enrolled courses/bootcamps.
/// Synchronized 1:1 with web mentee basecamp (Kelas Aktif).
/// Only renders if user actually has active courses.
class BasecampActiveCourses extends StatelessWidget {
  final List activeCourses;

  const BasecampActiveCourses({super.key, required this.activeCourses});

  @override
  Widget build(BuildContext context) {
    if (activeCourses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Kelas Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.myCourses),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: activeCourses.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final course = activeCourses[i] as Map<String, dynamic>;
              final id = course['id']?.toString() ?? '';
              final title = course['title'] as String? ?? 'Kelas Metro';
              final type = course['type'] as String? ?? 'mini-course';
              final rawProgress = (course['progress'] as num?)?.toDouble() ?? 0.0;
              final progress = (rawProgress / 100).clamp(0.0, 1.0);
              final percent = (progress * 100).toInt();
              final thumbnail = (course['thumbnail'] ?? course['thumbnailUrl'] ?? '') as String;
              final isBootcamp = type.toLowerCase() == 'bootcamp';

              return GestureDetector(
                onTap: () {
                  context.push(
                    '/learn/course/$id',
                    extra: {
                      'id': id,
                      'title': title,
                      'thumbnailUrl': thumbnail,
                      'isBootcamp': isBootcamp,
                      'isEnrolled': true,
                      'progress': percent,
                    },
                  );
                },
                child: Container(
                  width: 225,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C0F172A),
                        blurRadius: 18,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail with guaranteed anti-aliased curved top corners
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: SizedBox(
                            height: 105,
                            width: double.infinity,
                            child: thumbnail.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thumbnail,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: const Color(0xFFF8FAFC)),
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.school_rounded, color: Color(0xFF64748B), size: 30),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.school_rounded, color: Color(0xFF64748B), size: 30),
                                  ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                              child: Text(
                                isBootcamp ? 'BOOTCAMP' : 'MINI-COURSE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$percent%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4.5,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }
}
