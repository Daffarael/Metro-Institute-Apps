import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampRecommendations — Real course recommendations synced 1:1 with web mentee basecamp.
/// Only renders if data.recommendations is not empty.
class BasecampRecommendations extends StatelessWidget {
  final List recommendations;

  const BasecampRecommendations({super.key, required this.recommendations});

  static String _formatRupiah(num? price) {
    if (price == null || price == 0) return 'Gratis';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Rekomendasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
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
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: recommendations.take(3).map((rec) {
              final raw = rec as Map<String, dynamic>;
              final id = raw['id']?.toString() ?? '';
              final title = raw['title'] as String? ?? 'Kelas Digital';
              final price = raw['price'] as num? ?? 0;
              final thumbnail = (raw['thumbnail'] ?? raw['thumbnailUrl'] ?? '') as String;

              return GestureDetector(
                onTap: () => context.push('/learn/course/$id'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 56,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: thumbnail.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: thumbnail,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.school_rounded, color: Color(0xFF64748B), size: 20),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.school_rounded, color: Color(0xFF64748B), size: 20),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatRupiah(price),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
