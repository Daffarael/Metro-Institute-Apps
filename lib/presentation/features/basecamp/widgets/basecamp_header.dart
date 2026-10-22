import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import 'spotlight_search_bar.dart';

/// BasecampHeader — Light, clean header matching Web Mentee Dashboard:
/// • Spotlight Search Bar at the very top with 🔍 "Basecamp" placeholder
/// • User Avatar + "METRO ROOKIE" & "Hai, [Name]!" + Streak & Notification Bell
/// • XP Progress Bar synced 1:1 with Web Mentee Basecamp
class BasecampHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final int unreadCount;

  const BasecampHeader({
    super.key,
    this.user,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final rawName = user?['name'] as String? ?? 'Mentee';
    final firstName = rawName.trim().split(' ').first;
    final photoUrl = user?['photoUrl'] as String?;
    final streak = (user?['currentStreak'] as num?)?.toInt() ?? 0;
    final badge = user?['badgeLevel'] as String? ?? 'METRO_ROOKIE';
    final badgeLabel = AppConstants.badgeLabels[badge] ?? 'Metro Rookie';
    final totalXp = (user?['totalXp'] as num?)?.toInt() ?? 0;
    final nextXp = AppConstants.badgeXpThresholds['METRO_EXPLORER'] ?? 2000;
    final progress = (totalXp / nextXp).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. User Greeting Row: Avatar + Name/Badge + Streak & Notif Bell ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Avatar
              GestureDetector(
                onTap: () => context.go(AppRoutes.profile),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : 'M',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Greeting & Badge (Synced with Web: METRO ROOKIE / Hai, Daffarael!)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      badgeLabel.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.badgeColor(badge),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Hai, $firstName!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Notification Bell Button (di sebelah kiri streak)
              GestureDetector(
                onTap: () => context.push(AppRoutes.notifications),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Streak Chip (paling kanan: Api 🔥 dan Angka saja)
              if (streak > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFEE2E2), width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // ── 2. Spotlight Search Bar (Under Greeting Row) ──
          SpotlightSearchBar(
            onTap: () => showSpotlightSearchModal(context),
          ),

          const SizedBox(height: 14),

          // ── XP Progress Bar (Synced with Web Basecamp: Total XP / Next Badge) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pencapaian Belajar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$totalXp / $nextXp XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
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
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
