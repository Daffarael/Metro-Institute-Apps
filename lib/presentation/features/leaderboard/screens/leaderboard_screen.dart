import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/leaderboard_remote_datasource.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _ds = sl<LeaderboardRemoteDataSource>();

  String _period = 'all-time';
  bool _isLoading = true;
  List<dynamic> _entries = [];
  Map<String, dynamic>? _myRank;

  final List<_PeriodTab> _tabs = const [
    _PeriodTab(key: 'all-time', label: 'Sepanjang Waktu'),
    _PeriodTab(key: 'monthly',  label: 'Bulan Ini'),
    _PeriodTab(key: 'weekly',   label: 'Minggu Ini'),
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _ds.getLeaderboard(period: _period);
      if (!mounted) return;
      setState(() {
        _entries = (data['entries'] as List<dynamic>?) ?? [];
        _myRank  = data['myRank'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF018556), Color(0xFF01643f)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        '🏆  Leaderboard',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bersaing dengan sesama mentee',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Period Tabs ─────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildPeriodTabs(),
            ),

            // ── My Rank Banner ──────────────────────────────────────────────
            if (_myRank != null && !_entries.any((e) => e['userId'] == _myRank!['userId']))
              _buildMyRankBanner(),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildSkeletonList()
                  : _entries.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadLeaderboard,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: _entries.length,
                            itemBuilder: (context, idx) {
                              final entry = _entries[idx] as Map<String, dynamic>;
                              final isMe = entry['userId'] == _myRank?['userId'];
                              return _LeaderboardRow(
                                entry: entry,
                                isMe: isMe,
                                showDivider: idx < _entries.length - 1,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _tabs.map((tab) {
          final isActive = _period == tab.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_period != tab.key) {
                  setState(() => _period = tab.key);
                  _loadLeaderboard();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isActive
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  tab.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyRankBanner() {
    final entry = _myRank!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryXLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Posisimu Saat Ini',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _LeaderboardRow(entry: entry, isMe: true, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            _SkeletonBox(width: 36, height: 36, radius: 8),
            const SizedBox(width: 12),
            _SkeletonBox(width: 40, height: 40, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 120, height: 12, radius: 4),
                  const SizedBox(height: 6),
                  _SkeletonBox(width: 80, height: 10, radius: 4),
                ],
              ),
            ),
            _SkeletonBox(width: 50, height: 12, radius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Belum ada data',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Mulai belajar untuk masuk leaderboard!',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard Row ──────────────────────────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isMe;
  final bool showDivider;

  const _LeaderboardRow({
    required this.entry,
    required this.isMe,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final rank = (entry['rank'] as num?)?.toInt() ?? 0;
    final name = entry['name'] as String? ?? '';
    final photoUrl = entry['photoUrl'] as String?;
    final totalXp = (entry['totalXp'] as num?)?.toInt() ?? 0;
    final badgeLevel = entry['badgeLevel'] as String? ?? '';
    final currentStreak = (entry['currentStreak'] as num?)?.toInt() ?? 0;

    return Container(
      color: isMe ? AppColors.primaryXLight : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          // Rank Badge
          _RankBadge(rank: rank),
          const SizedBox(width: 12),

          // Avatar
          _Avatar(name: name, photoUrl: photoUrl),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Saya',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _badgeLabel(badgeLevel),
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                    if (currentStreak > 0) ...[
                      const SizedBox(width: 8),
                      const Text('🔥', style: TextStyle(fontSize: 11)),
                      Text(
                        '${currentStreak}d',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.streak),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text('⚡', style: const TextStyle(fontSize: 12)),
                  Text(
                    _formatNum(totalXp),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                'XP',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _badgeLabel(String level) {
    const labels = {
      'METRO_ROOKIE':   'Metro Rookie',
      'METRO_EXPLORER': 'Metro Explorer',
      'METRO_ACHIEVER': 'Metro Achiever',
      'METRO_EXPERT':   'Metro Expert',
      'METRO_MASTER':   'Metro Master',
    };
    return labels[level] ?? level;
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Rank Badge ───────────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fgColor;
    String? icon;

    switch (rank) {
      case 1:
        bg = const Color(0xFFFEF3C7);
        fgColor = const Color(0xFFD97706);
        icon = '👑';
        break;
      case 2:
        bg = const Color(0xFFF1F5F9);
        fgColor = const Color(0xFF475569);
        icon = '🥈';
        break;
      case 3:
        bg = const Color(0xFFFEF2F2);
        fgColor = const Color(0xFFB45309);
        icon = '🥉';
        break;
      default:
        bg = AppColors.border.withValues(alpha: 0.4);
        fgColor = AppColors.textSecondary;
        icon = null;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: icon != null
          ? Text(icon, style: const TextStyle(fontSize: 16))
          : Text(
              '#$rank',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: fgColor),
            ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _Avatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
        image: photoUrl != null
            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
            )
          : null,
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _PeriodTab {
  final String key;
  final String label;
  const _PeriodTab({required this.key, required this.label});
}
