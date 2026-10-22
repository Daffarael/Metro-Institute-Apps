import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampDailyMissions — Real daily missions checklist synced 1:1 with web mentee basecamp:
/// - Pasang Foto Profil (+20 XP, if photoUrl is empty)
/// - Tonton 1 materi video (+5 XP)
/// - Kerjakan 1 challenge (+10 XP)
/// Clean, minimalist, and uncluttered design.
class BasecampDailyMissions extends StatelessWidget {
  final Map<String, dynamic>? dailyMissions;
  final bool hasPhoto;

  const BasecampDailyMissions({
    super.key,
    this.dailyMissions,
    this.hasPhoto = true,
  });

  @override
  Widget build(BuildContext context) {
    final watchedVideo = dailyMissions?['watchedVideo'] as bool? ?? false;
    final didChallenge = dailyMissions?['didChallenge'] as bool? ?? false;
    final allCompleted = dailyMissions?['allCompleted'] as bool? ?? (watchedVideo && didChallenge);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Misi Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.challenge),
                child: Text(
                  'Tantangan',
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (!hasPhoto) ...[
                  _missionRow(
                    title: 'Pasang Foto Profil',
                    xp: '+20 XP',
                    isDone: false,
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  ),
                ],
                _missionRow(
                  title: 'Tonton 1 materi video',
                  xp: '+5 XP',
                  isDone: watchedVideo,
                  onTap: () => context.go(AppRoutes.learn),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ),
                _missionRow(
                  title: 'Kerjakan 1 challenge',
                  xp: '+10 XP',
                  isDone: didChallenge,
                  onTap: () => context.go(AppRoutes.challenge),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ),

                // Clean minimal footer without star icon or loud multi-badges
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          allCompleted
                              ? 'Semua misi hari ini selesai! 🎉'
                              : 'Selesaikan semua misi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: allCompleted ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: allCompleted ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          allCompleted ? 'Selesai' : '+15 XP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: allCompleted ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _missionRow({
    required String title,
    required String xp,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Clean minimal check indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                ),
              ),
            ),
            // Subtle, clean XP tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Text(
                xp,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
