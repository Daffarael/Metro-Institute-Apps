import 'package:cached_network_image/cached_network_image.dart';
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
    final activeCourses = (_data?['activeCourses'] as List?) ?? [
      ...((_data?['courseEnrollments'] as List?) ?? []),
      ...((_data?['bootcampEnrollments'] as List?) ?? []),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Metro Institute',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              ),
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: _isLoading && _data == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message if any
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ],

                    // ── XP & Badge Card ────────────────────────────────────
                    _XpBadgeCard(user: user),
                    const SizedBox(height: 24),

                    // ── Misi Harian ────────────────────────────────────────
                    _SectionHeader(title: 'Misi Harian', onTap: () {}),
                    const SizedBox(height: 12),
                    const _DailyMissionCard(),
                    const SizedBox(height: 28),

                    // ── Lanjutkan Belajar ──────────────────────────────────
                    if (continueLearning != null) ...[
                      _SectionHeader(title: 'Lanjutkan Belajar', onTap: () => context.go(AppRoutes.learn)),
                      const SizedBox(height: 12),
                      _ContinueLearningCard(data: continueLearning),
                      const SizedBox(height: 28),
                    ],

                    // ── Kelas Aktif ────────────────────────────────────────
                    _SectionHeader(title: 'Kelas Aktif Saya', onTap: () => context.go(AppRoutes.learn)),
                    const SizedBox(height: 12),
                    _ActiveCoursesRow(
                      activeCourses: activeCourses,
                    ),
                    const SizedBox(height: 28),

                    // ── Challenge Banner ───────────────────────────────────
                    _ChallengeBanner(onTap: () => context.go(AppRoutes.challenge)),
                    const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang kembali,',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Perkembangan XP', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              Text('$totalXp / $targetXp XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target: Metro Explorer', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              Text(
                streak > 0 ? '$streak Hari Streak' : 'Mulai Streak Belajar',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text('Lihat Semua', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _missionItem(title: 'Tonton 1 Modul Pembelajaran', xp: '+20 XP', done: true),
          const Divider(height: 18, color: AppColors.border),
          _missionItem(title: 'Selesaikan 1 Kuis Praktik', xp: '+15 XP', done: false),
        ],
      ),
    );
  }

  Widget _missionItem({required String title, required String xp, required bool done}) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: done ? AppColors.primary : AppColors.textTertiary,
          size: 20,
        ),
        const SizedBox(width: 12),
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
            color: done ? AppColors.backgroundSubtle : AppColors.primaryLight,
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
    final thumbnail = (data['thumbnail'] ?? data['thumbnailUrl']) as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail.isNotEmpty)
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.backgroundSubtle),
                    errorWidget: (context, url, error) => Container(color: AppColors.primaryLight),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    right: 14,
                    child: Text(
                      sessionTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progres Kelas', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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

class _ActiveCoursesRow extends StatelessWidget {
  final List activeCourses;
  const _ActiveCoursesRow({required this.activeCourses});

  @override
  Widget build(BuildContext context) {
    if (activeCourses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
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
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: activeCourses.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final item = activeCourses[i] as Map<String, dynamic>;
          final course = (item['course'] as Map<String, dynamic>?) ?? item;
          final title = course['title'] as String? ?? 'Kelas Metro';
          final thumbnail = (course['thumbnail'] ?? course['thumbnailUrl']) as String? ?? '';
          final type = (course['type'] as String? ?? 'COURSE').toUpperCase();
          final progress = ((item['progress'] as num?)?.toDouble() ?? 0.0) / 100;

          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: thumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbnail,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.backgroundSubtle),
                          errorWidget: (context, url, error) => Container(color: AppColors.primaryLight),
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Center(
                            child: Icon(Icons.play_circle_outline_rounded, size: 32, color: AppColors.primary),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: type.contains('BOOTCAMP') ? AppColors.primaryLight : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type.contains('BOOTCAMP') ? 'BOOTCAMP' : 'MINI COURSE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: type.contains('BOOTCAMP') ? AppColors.primary : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${(progress * 100).toInt()}% Selesai', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const Text('Lanjutkan >', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
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
                  Text('Tantangan & Uji Kemampuan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Uji pemahaman materi dan raih poin XP lebih cepat.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
