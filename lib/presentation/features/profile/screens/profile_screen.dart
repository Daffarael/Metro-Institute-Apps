import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static void clearCache() => _ProfileScreenState.clearCache();

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepo = sl<AuthRepository>();
  static UserModel? _cachedUser;
  static void clearCache() => _cachedUser = null;
  UserModel? _user = _cachedUser;
  late bool _isLoading = _cachedUser == null;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authRepo.getSavedUser();
    if (user != null) _cachedUser = user;
    if (!mounted) return;
    setState(() {
      _user = _cachedUser ?? user;
      _isLoading = false;
    });

    // Background refresh
    try {
      final refreshed = await _authRepo.refreshProfile();
      _cachedUser = refreshed;
      if (!mounted) return;
      setState(() {
        _user = refreshed;
      });
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Metro Institute?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authRepo.logout();
      if (!mounted) return;
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.name ?? 'Mentee Metro';
    final email = _user?.email ?? '-';
    final badge = _user?.badgeLevel ?? 'METRO_ROOKIE';
    final totalXp = _user?.totalXp ?? 0;
    final streak = _user?.currentStreak ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadUser,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card (Pastel squircle with defined border)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // Clean white card (no purple)
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0E0F172A),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      email,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badge.replaceAll('_', ' '),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                tooltip: 'Edit Profil',
                                onPressed: () async {
                                  final updated = await context.push<bool>(AppRoutes.editProfile);
                                  if (updated == true) {
                                    _loadUser();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Gamification Highlights (Pastel squircle cards from Reference Image)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.xpActivity),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF9EE), // Pastel cream
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A0F172A),
                                    blurRadius: 14,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.stars_rounded, color: AppColors.xp, size: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Total XP', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$totalXp XP',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1FBF6), // Pastel mint
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A0F172A),
                                  blurRadius: 14,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Streak', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$streak Hari',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Aktivitas & Pembelajaran',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    // Section 1: Learning & Gamification (Reference squircle)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.bolt_rounded,
                            iconColor: AppColors.primary,
                            title: 'Riwayat Aktivitas XP',
                            subtitle: 'Periksa catatan perolehan poin XP Anda',
                            onTap: () => context.push(AppRoutes.xpActivity),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                          _menuTile(
                            icon: Icons.receipt_long_rounded,
                            iconColor: AppColors.info,
                            title: 'Riwayat Transaksi',
                            subtitle: 'Status pembayaran kelas, webinar, dan bootcamp',
                            onTap: () => context.push(AppRoutes.transactions),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                          _menuTile(
                            icon: Icons.psychology_outlined,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Tes Bakat & Minat (Skill Test)',
                            subtitle: 'Petakan jalur karir digital yang sesuai',
                            onTap: () => context.push(AppRoutes.skillTest),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Pengaturan & Akun',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    // Section 2: Account Settings
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.person_outline_rounded,
                            iconColor: AppColors.textSecondary,
                            title: 'Edit Informasi Profil',
                            subtitle: 'Perbarui nama, nomor WhatsApp, dan bio',
                            onTap: () async {
                              final updated = await context.push<bool>(AppRoutes.editProfile);
                              if (updated == true) _loadUser();
                            },
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                          _menuTile(
                            icon: Icons.lock_outline_rounded,
                            iconColor: AppColors.textSecondary,
                            title: 'Keamanan & Ganti Password',
                            subtitle: 'Atur ulang kata sandi akun Anda',
                            onTap: () => context.push(AppRoutes.changePassword),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                          _menuTile(
                            icon: Icons.notifications_none_rounded,
                            iconColor: AppColors.textSecondary,
                            title: 'Pemberitahuan & Notifikasi',
                            subtitle: 'Lihat pesan sistem dan pengingat kelas',
                            onTap: () => context.push(AppRoutes.notifications),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                          _menuTile(
                            icon: Icons.help_outline_rounded,
                            iconColor: AppColors.textSecondary,
                            title: 'Bantuan & FAQ',
                            subtitle: 'Panduan platform Metro Institute',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (ctx) => Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text('Pusat Bantuan Mentee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Jika Anda mengalami kendala terkait materi, sertifikat, atau pembayaran, silakan hubungi tim support Metro Institute melalui WhatsApp atau email resmi kami di support@metroinstitute.id.',
                                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F172A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                        ),
                                        child: const Text('Mengerti'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Logout Button (Clean squircle pill)
                    OutlinedButton(
                      onPressed: _handleLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Metro Institute Mobile • v1.0.0',
                        style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
