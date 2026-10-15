import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

/// BasecampScreen â€” Tab 1 (Home Dashboard Mentee).
/// Matches website's /mentee/basecamp page.
/// Shows: Badge/XP Card, Misi Harian, Continue Learning,
///        Upcoming Live, Active Courses, Recommendations.
class BasecampScreen extends StatelessWidget {
  const BasecampScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('MI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 8),
            const Text('Metro Institute', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
            color: AppColors.textSecondary,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.notifications),
                color: AppColors.textSecondary,
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppColors.streak, shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ XP & Badge Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _XpBadgeCard(),
              const SizedBox(height: 20),

              // â”€â”€ Misi Harian â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _SectionHeader(title: 'ðŸŽ¯ Misi Harian', onTap: () {}),
              const SizedBox(height: 10),
              _DailyMissionCard(),
              const SizedBox(height: 24),

              // â”€â”€ Lanjutkan Belajar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _SectionHeader(title: 'â–¶ï¸ Lanjutkan Belajar', onTap: () => context.go(AppRoutes.learn)),
              const SizedBox(height: 10),
              _ContinueLearningCard(),
              const SizedBox(height: 24),

              // â”€â”€ Kelas Aktif â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _SectionHeader(title: 'ðŸ“š Kelas Aktif Saya', onTap: () => context.go(AppRoutes.learn)),
              const SizedBox(height: 10),
              _ActiveCoursesRow(),
              const SizedBox(height: 24),

              // â”€â”€ Rekomendasi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _SectionHeader(title: 'ðŸ’¡ Rekomendasi Untukmu', onTap: () => context.go(AppRoutes.learn)),
              const SizedBox(height: 10),
              _RecommendationRow(),
              const SizedBox(height: 24),

              // â”€â”€ Challenge Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _ChallengeBanner(onTap: () => context.go(AppRoutes.challenge)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Sub-widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _XpBadgeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(99)),
            child: const Text('METRO ROOKIE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hai, Daffa! ðŸ‘‹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              // Streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.streakBg, borderRadius: BorderRadius.circular(99)),
                child: const Row(
                  children: [
                    Text('ðŸ”¥', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Text('7 Hari', style: TextStyle(color: AppColors.streak, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('XP', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const Text('1.240 / 2.000', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              value: 0.62,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Menuju: Metro Explorer ðŸ…', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionHeader({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text('Lihat semua â†’', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          _MissionItem(label: 'Lengkapi foto profil', done: true, xp: 20),
          const SizedBox(height: 8),
          _MissionItem(label: 'Tonton 1 materi video', done: true, xp: 30),
          const SizedBox(height: 8),
          _MissionItem(label: 'Selesaikan 1 tantangan kuis', done: false, xp: 50),
        ],
      ),
    );
  }
}

class _MissionItem extends StatelessWidget {
  final String label;
  final bool done;
  final int xp;
  const _MissionItem({required this.label, required this.done, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: done ? AppColors.primary : AppColors.textTertiary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: done ? AppColors.textSecondary : AppColors.textPrimary,
            decoration: done ? TextDecoration.lineThrough : null))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: AppColors.xpBg, borderRadius: BorderRadius.circular(99)),
          child: Text('+$xp XP', style: const TextStyle(color: AppColors.xp, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primaryXLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(99)),
            child: const Text('MINI COURSE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          const Text('UI/UX Design System: Auto Layout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Progress', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('75%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              value: 0.75,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Lanjut Sesi Ini'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCoursesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context2, index2) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _CourseCard(progress: [0.6, 0.3, 1.0][i], title: ['UI/UX Batch', 'React Intro', 'Flutter Dev'][i]),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final double progress;
  final String title;
  const _CourseCard({required this.progress, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(height: 60, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Icon(Icons.play_lesson_outlined, color: AppColors.primary, size: 28))),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ClipRRect(borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? AppColors.success : AppColors.primary))),
          Text(progress >= 1.0 ? 'âœ… Selesai' : '${(progress * 100).toInt()}% selesai',
              style: TextStyle(fontSize: 10, color: progress >= 1.0 ? AppColors.success : AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context2, index2) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 50, decoration: BoxDecoration(color: AppColors.backgroundSubtle, borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Icon(Icons.school_outlined, color: AppColors.textSecondary))),
              Text(['Flutter Pro', 'Backend Go', 'React Native'][i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text([' GRATIS', 'Rp 150.000', 'Rp 120.000'][i],
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: i == 0 ? AppColors.success : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ChallengeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('âš¡', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Challenge Hari Ini', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Selesaikan kuis & raih +50 XP!', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}




