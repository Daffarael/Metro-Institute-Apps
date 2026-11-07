import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import 'spotlight_search_bar.dart';

/// BasecampHeader — Header beranda Basecamp Metro Institute:
/// • User Avatar + "METRO ROOKIE" & "Hai, [Name]!" + Streak & Notification Bell
/// • XP Progress Bar synced 1:1 dengan Web Mentee Basecamp
/// • Dua kartu ringkasan Dashboard side-by-side (Certificates & Courses) dengan circular gauge
/// • Spotlight Search Bar bergaya flat pill modern di bawah kedua kartu
class BasecampHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final int unreadCount;
  final int certificateCount;
  final int courseCount;

  const BasecampHeader({
    super.key,
    this.user,
    this.unreadCount = 0,
    this.certificateCount = 0,
    this.courseCount = 0,
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

              // Notification Bell Button
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

              // Streak Chip (Api 🔥 dan Angka saja)
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

          const SizedBox(height: 12),

          // ── 2. XP Progress Bar (Synced with Web Basecamp: Total XP / Next Badge) ──
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

          const SizedBox(height: 16),

          // ── 3. Dua Kartu Dashboard (Certificates & Courses) ──────────────
          _buildDashboardStatCards(context),

          const SizedBox(height: 14),

          // ── 4. Spotlight Search Bar (di bawah kedua kartu) ───────────────
          SpotlightSearchBar(
            onTap: () => showSpotlightSearchModal(context),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DASHBOARD STAT CARDS (Side-by-side Courses & Certificates - Kuning & Hijau Metro)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDashboardStatCards(BuildContext context) {
    return Row(
      children: [
        // ── Card 1: Courses (Hijau Metro #018556) ──
        Expanded(
          child: _buildStatCard(
            context: context,
            count: courseCount,
            label: 'Courses',
            progress: courseCount > 0 ? (courseCount / 10).clamp(0.2, 1.0) : 0.65,
            progressColor: AppColors.accent, // Kuning Metro ring
            trackColor: const Color(0xFF016B44),
            cardBgColor: AppColors.primary, // Hijau Metro (#018556)
            badgeIcon: Icons.business_center_rounded,
            iconColor: AppColors.primary,
            isDarkBg: true,
            isCloudShape: false,
            onTap: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.learn);
            },
          ),
        ),

        const SizedBox(width: 14),

        // ── Card 2: Certificates (Kuning Metro #FAE653) ──
        Expanded(
          child: _buildStatCard(
            context: context,
            count: certificateCount,
            label: 'Certificates',
            progress: certificateCount > 0 ? (certificateCount / 5).clamp(0.2, 1.0) : 0.70,
            progressColor: AppColors.primary, // Hijau Metro ring
            trackColor: const Color(0xFFE6D13A),
            cardBgColor: AppColors.accent, // Kuning Metro (#FAE653)
            badgeIcon: Icons.workspace_premium_rounded,
            iconColor: AppColors.primary,
            isDarkBg: false,
            isCloudShape: true,
            onTap: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.certificate);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required int count,
    required String label,
    required double progress,
    required Color progressColor,
    required Color trackColor,
    required Color cardBgColor,
    required IconData badgeIcon,
    required Color iconColor,
    required bool isDarkBg,
    required bool isCloudShape,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDarkBg
                  ? const Color(0xFF018556).withValues(alpha: 0.28)
                  : const Color(0xFFFAE653).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background shape in bottom right corner
            Positioned.fill(
              child: CustomPaint(
                painter: isCloudShape
                    ? const _OrganicCloudPainter(color: Color(0x40E6D13A))
                    : const _GeometricShapePainter(color: Color(0x18FFFFFF)),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top left circular progress badge
                  _buildProgressCircle(
                    progress: progress,
                    progressColor: progressColor,
                    trackColor: trackColor,
                    child: Icon(
                      badgeIcon,
                      color: iconColor,
                      size: 19,
                    ),
                  ),

                  // Center Big Number & Subtitle
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$count',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: isDarkBg ? Colors.white : const Color(0xFF0D1117),
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDarkBg
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : const Color(0xFF0D1117).withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCircle({
    required double progress,
    required Color progressColor,
    required Color trackColor,
    required Widget child,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress ring
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3.5,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            strokeCap: StrokeCap.round,
          ),
          // Inner white circle
          Container(
            width: 33,
            height: 33,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECORATIVE BACKGROUND PAINTERS (Matching Reference Image)
// ─────────────────────────────────────────────────────────────────────────────
class _OrganicCloudPainter extends CustomPainter {
  final Color color;
  const _OrganicCloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.90, size.height * 0.90), radius: 52));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.98, size.height * 0.60), radius: 40));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.70, size.height * 1.00), radius: 44));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.60, size.height * 0.75), radius: 32));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GeometricShapePainter extends CustomPainter {
  final Color color;
  const _GeometricShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.55, h);
    path.lineTo(w * 0.70, h * 0.72);
    path.lineTo(w * 0.98, h * 0.62);
    path.lineTo(w * 0.82, h * 0.42);
    path.lineTo(w, h * 0.32);
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
