import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../common/widgets/tear_ticket_dialog.dart';

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
    final confirm = await TearTicketDialog.show(
      context,
      title: 'Keluar dari Akun',
      description: 'Apakah Anda yakin ingin keluar dari akun Metro Institute Anda?',
      ticketLabel: 'Keluar Akun',
      ticketSubtitle: 'Sobek tiket untuk keluar',
      stubLabel: 'SOBEK',
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF063D2A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF063D2A)),
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
                    // Profile Header Card (Clean Solid White - No Shadow)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              color: AppColors.primary, // Solid Hijau Metro
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFAE653), width: 2.5), // Solid Kuning Metro
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF063D2A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAE653), // Solid Kuning Metro
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF063D2A)),
                                      const SizedBox(width: 5),
                                      Text(
                                        badge.replaceAll('_', ' '),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF063D2A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF018556), // Solid Hijau Metro
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                            ),
                            tooltip: 'Edit Profil',
                            onPressed: () async {
                              final updated = await context.push<bool>(AppRoutes.editProfile);
                              if (updated == true) _loadUser();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Gamification Highlights (Solid Flat Colors - No Gradient, No Shadow)
                    Row(
                      children: [
                        // TOTAL XP CARD (SOLID KUNING METRO)
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.xpActivity),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAE653), // Solid Kuning Metro
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFEAB308), width: 1.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF063D2A),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.stars_rounded, color: Color(0xFFFAE653), size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total XP',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: const Color(0xFF063D2A),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$totalXp XP',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF063D2A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // STREAK CARD (SOLID HIJAU METRO)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF018556), // Solid Hijau Metro
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF016B44), width: 1.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAE653),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFF063D2A), size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Streak',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$streak Hari',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Aktivitas & Pembelajaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF063D2A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Section 1: Learning & Gamification (Clean Flat Card - No Shadow)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFF018556), // Solid Hijau Metro
                            title: 'Riwayat Aktivitas XP',
                            subtitle: 'Periksa catatan perolehan poin XP Anda',
                            onTap: () => context.push(AppRoutes.xpActivity),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                          _menuTile(
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF018556), // Solid Hijau Metro
                            title: 'Riwayat Transaksi',
                            subtitle: 'Status pembayaran kelas, webinar, dan bootcamp',
                            onTap: () => context.push(AppRoutes.transactions),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                          _menuTile(
                            icon: Icons.psychology_outlined,
                            iconColor: const Color(0xFF018556), // Solid Hijau Metro
                            title: 'Tes Bakat & Minat (Skill Test)',
                            subtitle: 'Petakan jalur karir digital yang sesuai',
                            onTap: () => context.push(AppRoutes.skillTest),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                          _menuTile(
                            icon: Icons.workspace_premium_rounded,
                            iconColor: const Color(0xFF018556), // Solid Hijau Metro
                            title: 'Sertifikat Saya',
                            subtitle: 'Periksa dan unduh kredensial sertifikat Anda',
                            onTap: () => context.go(AppRoutes.certificate),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Pengaturan & Akun',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF063D2A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Section 2: Account Settings (Clean Flat Card - No Shadow)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF475569),
                            title: 'Edit Informasi Profil',
                            subtitle: 'Perbarui nama, nomor WhatsApp, dan bio',
                            onTap: () async {
                              final updated = await context.push<bool>(AppRoutes.editProfile);
                              if (updated == true) _loadUser();
                            },
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                          _menuTile(
                            icon: Icons.lock_outline_rounded,
                            iconColor: const Color(0xFF475569),
                            title: 'Keamanan & Ganti Sandi',
                            subtitle: 'Atur ulang kata sandi akun Anda',
                            onTap: () => context.push(AppRoutes.changePassword),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                          _menuTile(
                            icon: Icons.notifications_none_rounded,
                            iconColor: const Color(0xFF475569),
                            title: 'Pemberitahuan & Notifikasi',
                            subtitle: 'Lihat pesan sistem dan pengingat kelas',
                            onTap: () => context.push(AppRoutes.notifications),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                          _menuTile(
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFF475569),
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
                                      Text(
                                        'Pusat Bantuan Mentee',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF063D2A),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Jika Anda mengalami kendala terkait materi, sertifikat, atau pembayaran, silakan hubungi tim support Metro Institute melalui WhatsApp atau email resmi kami di support@metroinstitute.id.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: const Color(0xFF64748B),
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF018556),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: Text(
                                          'Mengerti',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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

                    const SizedBox(height: 24),

                    // Destructive Logout Card (Solid Red - No Pale Pink, No Shadow)
                    InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626), // Solid Merah Tegas
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Keluar dari Akun',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Metro Institute Mobile • v1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF063D2A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
