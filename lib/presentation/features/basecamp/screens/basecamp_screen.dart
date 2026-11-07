import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/basecamp_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../widgets/basecamp_active_courses.dart';
import '../widgets/basecamp_daily_missions.dart';
import '../widgets/basecamp_discord_card.dart';
import '../widgets/basecamp_header.dart';
import '../widgets/basecamp_hero_card.dart';
import '../widgets/basecamp_recommendations.dart';
import '../widgets/basecamp_upcoming_live.dart';

/// BasecampScreen — Mentee Dashboard Home.
/// Synchronized 1:1 with web mentee basecamp (page.tsx) without hardcoded/fake data.
/// Styled using the pastel squircle aesthetic with crisp borders from Reference Image.
class BasecampScreen extends StatefulWidget {
  const BasecampScreen({super.key});

  static void clearCache() => _BasecampScreenState.clearCache();

  @override
  State<BasecampScreen> createState() => _BasecampScreenState();
}

class _BasecampScreenState extends State<BasecampScreen> {
  static Map<String, dynamic>? _cachedData;
  static void clearCache() => _cachedData = null;
  late bool _isLoading = _cachedData == null;
  String? _error;
  Map<String, dynamic>? _data = _cachedData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_cachedData == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final ds = sl<BasecampRemoteDataSource>();
      final result = await ds.getBasecampData();
      _cachedData = result;
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final authRepo = sl<AuthRepository>();
      final savedUser = await authRepo.getSavedUser();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (savedUser != null) {
          final fallback = {
            'user': savedUser.toJson(),
            'unreadCount': 0,
          };
          _cachedData ??= fallback;
          _data = _cachedData;
        } else if (_cachedData == null) {
          _error = e.toString().replaceAll('Exception: ', '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    final user = _data?['user'] as Map<String, dynamic>?;
    final unreadCount = (_data?['unreadNotifications'] as num?)?.toInt() ??
        (_data?['unreadCount'] as num?)?.toInt() ??
        0;
    final continueLearning = _data?['continueLearning'] as Map<String, dynamic>?;
    final activeCourses = (_data?['activeCourses'] as List?) ?? [];
    final upcomingLive = (_data?['upcomingLive'] as List?) ?? [];
    final recommendations = (_data?['recommendations'] as List?) ?? [];
    final dailyMissions = _data?['dailyMissions'] as Map<String, dynamic>?;
    final hasPhoto = user?['photoUrl'] != null && (user!['photoUrl'] as String).isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5), // Light warm pastel canvas (Reference Image)
      body: RefreshIndicator(
        color: const Color(0xFF0F172A),
        onRefresh: _loadData,
        child: _isLoading && _data == null
            ? _buildShimmerLoading(context)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Header (Avatar, Greeting, Level, Streak & XP Bar) ─
                    BasecampHeader(
                      user: user,
                      unreadCount: unreadCount,
                    ),

                    const SizedBox(height: 8),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── 2. Lanjutkan Belajar (My Lesson / Continue Learning) ─
                    BasecampHeroCard(
                      continueLearning: continueLearning,
                    ),

                    // ── 3. Kelas Aktif (Only if activeCourses is not empty) ──
                    if (activeCourses.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      BasecampActiveCourses(
                        activeCourses: activeCourses,
                      ),
                    ],

                    // ── 4. Jadwal Live Terdekat (Only if upcomingLive is not empty) ──
                    if (upcomingLive.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      BasecampUpcomingLive(
                        upcomingLive: upcomingLive,
                      ),
                    ],

                    // ── 5. Misi Hari Ini (Daily Missions Checklist) ──────────
                    const SizedBox(height: 22),
                    BasecampDailyMissions(
                      dailyMissions: dailyMissions,
                      hasPhoto: hasPhoto,
                    ),

                    // ── 6. Rekomendasi (Only if recommendations is not empty) ─
                    if (recommendations.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      BasecampRecommendations(
                        recommendations: recommendations,
                      ),
                    ],

                    // ── 7. Komunitas Discord ────────────────────────────────
                    const SizedBox(height: 22),
                    const BasecampDiscordCard(),

                    // Spacing for floating dock
                    const SizedBox(height: 110),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 120,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 90,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
