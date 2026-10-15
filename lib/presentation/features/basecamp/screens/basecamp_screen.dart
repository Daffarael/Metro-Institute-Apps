import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/basecamp_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';

/// BasecampScreen — Tab 1 (Home Dashboard Mentee).
/// Connected to live Railway backend API (/api/v1/users/basecamp).
class BasecampScreen extends StatefulWidget {
  const BasecampScreen({super.key});

  @override
  State<BasecampScreen> createState() => _BasecampScreenState();
}

class _BasecampScreenState extends State<BasecampScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ds = sl<BasecampRemoteDataSource>();
      final result = await ds.getBasecampData();
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Fallback: load local cached user
      final authRepo = sl<AuthRepository>();
      final savedUser = await authRepo.getSavedUser();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (savedUser != null) {
          _data = {
            'user': savedUser.toJson(),
            'unreadCount': 0,
          };
        } else {
          _error = e.toString().replaceAll('Exception: ', '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _data?['user'] as Map<String, dynamic>?;
    final unreadCount = (_data?['unreadCount'] as num?)?.toInt() ?? 0;
    final continueLearning = _data?['continueLearning'] as Map<String, dynamic>?;
    final courseEnrollments = (_data?['courseEnrollments'] as List?) ?? [];
    final bootcampEnrollments = (_data?['bootcampEnrollments'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
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
            const Text('Metro Institute', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.notifications),
                color: AppColors.textSecondary,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: _isLoading && _data == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message if any
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ],

                    // ── XP & Badge Card ────────────────────────────────────
                    _XpBadgeCard(user: user),
                    const SizedBox(height: 20),

                    // ── Misi Harian ────────────────────────────────────────
                    _SectionHeader(title: '🎯 Misi Harian', onTap: () {}),
                    const SizedBox(height: 10),
                    const _DailyMissionCard(),
                    const SizedBox(height: 24),

                    // ── Lanjutkan Belajar ──────────────────────────────────
                    if (continueLearning != null) ...[
                      _SectionHeader(title: '▶️ Lanjutkan Belajar', onTap: () => context.go(AppRoutes.learn)),
                      const SizedBox(height: 10),
                      _ContinueLearningCard(data: continueLearning),
                      const SizedBox(height: 24),
                    ],

                    // ── Kelas Aktif ────────────────────────────────────────
                    _SectionHeader(title: '📚 Kelas Aktif Saya', onTap: () => context.go(AppRoutes.learn)),
                    const SizedBox(height: 10),
                    _ActiveCoursesRow(
                      courses: courseEnrollments,
                      bootcamps: bootcampEnrollments,
                    ),
                    const SizedBox(height: 24),

                    // ── Challenge Banner ───────────────────────────────────
                    _ChallengeBanner(onTap: () => context.go(AppRoutes.challenge)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _XpBadgeCard extends StatelessWidget {
  final Map<String, dynamic>? user;
  const _XpBadgeCard({this.user});

  @override
  Widget build(BuildContext context) {
    final name = (user?['name'] as String? ?? 'Mentee').split(' ').first;
    final badge = user?['badgeLevel'] as String? ?? 'METRO_ROOKIE';
    final streak = (user?['currentStreak'] as num?)?.toInt() ?? 0;
    final totalXp = (user?['totalXp'] as num?)?.toInt() ?? 0;

    final targetXp = AppConstants.badgeXpThresholds['METRO_EXPLORER'] ?? 2000;
    final progress = (totalXp / targetXp).clamp(0.0, 1.0);
    final badgeLabel = AppConstants.badgeLabels[badge] ?? 'Metro Rookie';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badgeLabel.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.streakBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak Hari',
                      style: const TextStyle(
                        color: AppColors.streak,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Hai, $name! 👋',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total XP', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              Text('$totalXp / $targetXp XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Menuju Level: Metro Explorer 🎖️', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
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
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _missionItem(icon: '📖', title: 'Tonton 1 Modul Video', xp: '+20 XP', done: true),
          const Divider(height: 16, color: AppColors.border),
          _missionItem(icon: '⚡', title: 'Selesaikan 1 Kuis Harian', xp: '+15 XP', done: false),
        ],
      ),
    );
  }

  Widget _missionItem({required String icon, required String title, required String xp, required bool done}) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? AppColors.textTertiary : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: done ? AppColors.border : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            xp,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: done ? AppColors.textTertiary : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ContinueLearningCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Kelas Digital';
    final sessionTitle = data['sessionTitle'] as String? ?? 'Lanjutkan Belajar';
    final progress = ((data['progress'] as num?)?.toDouble() ?? 0.0) / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(sessionTitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCoursesRow extends StatelessWidget {
  final List courses;
  final List bootcamps;
  const _ActiveCoursesRow({required this.courses, required this.bootcamps});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty && bootcamps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            const Text('Belum ada kelas aktif', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.learn),
              child: const Text('Jelajahi Kelas'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: courses.length + bootcamps.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final isCourse = i < courses.length;
          final item = isCourse ? courses[i]['course'] : bootcamps[i - courses.length]['bootcamp'];
          final title = item?['title'] as String? ?? 'Kelas Metro';

          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCourse ? Colors.blue.withValues(alpha: 0.1) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCourse ? 'MINI COURSE' : 'BOOTCAMP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isCourse ? Colors.blue : AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Text('Lanjutkan >', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
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
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF015A3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Tantangan & Kuis Baru 🏆', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Kumpulkan poin XP dan raih badge sertifikasi lebih cepat!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
