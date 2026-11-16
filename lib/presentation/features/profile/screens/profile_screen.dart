import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/certificate_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/entities/user.dart';
import '../../../common/widgets/tear_ticket_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepo = sl<AuthRepository>();
  final CertificateRemoteDataSource _certDs = sl<CertificateRemoteDataSource>();

  User? _user;
  static User? _cachedUser;
  bool _isLoading = true;
  int _certCount = 0;

  @override
  void initState() {
    super.initState();
    if (_cachedUser != null) {
      _user = _cachedUser;
      _isLoading = false;
    }
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

    // Background refresh user profile & certificate count
    try {
      final results = await Future.wait([
        _authRepo.refreshProfile(),
        _certDs.getCertificates().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final refreshed = results[0] as User?;
      final certs = results[1] as List;
      _cachedUser = refreshed;
      if (!mounted) return;
      setState(() {
        if (refreshed != null) _user = refreshed;
        _certCount = certs.length;
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
    final photoUrl = _user?.photoUrl;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadUser,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // ── 1. Hero Header with Image & Fade Mask (Matching Reference) ──
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Cover Image with Gradient Fade into #FAF9F5
                        SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/onboarding_team.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF018556),
                                ),
                              ),
                              // Dark translucent tint
                              Container(
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                              // Vertical Fade into background canvas
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.2),
                                        Colors.transparent,
                                        const Color(0xFFFAF9F5).withValues(alpha: 0.85),
                                        const Color(0xFFFAF9F5),
                                      ],
                                      stops: const [0.0, 0.45, 0.85, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top Navigation Icons (Back & Notifications) + Title
                        Positioned(
                          top: topPadding + 6,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back button in frosted circle (or empty placeholder if cannot pop)
                              context.canPop()
                                  ? _circleIconButton(
                                      icon: Icons.arrow_back_ios_new_rounded,
                                      iconSize: 16,
                                      onTap: () => context.pop(),
                                    )
                                  : _circleIconButton(
                                      icon: Icons.home_rounded,
                                      iconSize: 20,
                                      onTap: () => context.go(AppRoutes.basecamp),
                                    ),

                              // Header Title "Profile" in white
                              Text(
                                'Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),

                              // Notification Bell in frosted circle
                              _circleIconButton(
                                icon: Icons.notifications_none_rounded,
                                iconSize: 20,
                                hasBadge: true,
                                onTap: () => context.push(AppRoutes.notifications),
                              ),
                            ],
                          ),
                        ),

                        // Centered Avatar overlapping the bottom of the hero
                        Positioned(
                          top: 145,
                          child: GestureDetector(
                            onTap: () async {
                              final updated = await context.push<bool>(AppRoutes.editProfile);
                              if (updated == true) _loadUser();
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.white, width: 3.5),
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: const Color(0xFF018556),
                                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: (photoUrl == null || photoUrl.isEmpty)
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                // Edit Camera Badge
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF018556),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Spacer for the overlapping avatar
                    const SizedBox(height: 30),

                    // ── 2. User Name & Subtitle ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${badge.replaceAll('_', ' ')} • $email',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 3. Integrated 3-Column Stats Row (Matching Reference) ─
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _buildStatColumn(
                            value: '$totalXp',
                            label: 'Total XP',
                            onTap: () => context.push(AppRoutes.xpActivity),
                          ),
                          Container(
                            height: 32,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildStatColumn(
                            value: '$_certCount',
                            label: 'Sertifikat',
                            onTap: () => context.go(AppRoutes.certificate),
                          ),
                          Container(
                            height: 32,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildStatColumn(
                            value: '$streak',
                            label: 'Day Streak',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── 4. Section 1: Aktivitas & Pembelajaran ────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktivitas & Pembelajaran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMenuCard(
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFF018556),
                            title: 'Riwayat Aktivitas XP',
                            subtitle: 'Periksa catatan perolehan poin XP Anda',
                            onTap: () => context.push(AppRoutes.xpActivity),
                          ),
                          _buildMenuCard(
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF018556),
                            title: 'Riwayat Transaksi',
                            subtitle: 'Status pembayaran kelas, webinar, dan bootcamp',
                            onTap: () => context.push(AppRoutes.transactions),
                          ),
                          _buildMenuCard(
                            icon: Icons.psychology_rounded,
                            iconColor: const Color(0xFF018556),
                            title: 'Tes Bakat & Minat (Skill Test)',
                            subtitle: 'Petakan jalur karir digital yang sesuai',
                            onTap: () => context.push(AppRoutes.skillTest),
                          ),
                          _buildMenuCard(
                            icon: Icons.workspace_premium_rounded,
                            iconColor: const Color(0xFF018556),
                            title: 'Sertifikat Saya',
                            subtitle: 'Periksa dan unduh kredensial sertifikat Anda',
                            onTap: () => context.go(AppRoutes.certificate),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 5. Section 2: Pengaturan & Akun ───────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengaturan & Akun',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMenuCard(
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF475569),
                            title: 'Edit Informasi Profil',
                            subtitle: 'Perbarui nama, nomor WhatsApp, dan bio',
                            onTap: () async {
                              final updated = await context.push<bool>(AppRoutes.editProfile);
                              if (updated == true) _loadUser();
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.lock_outline_rounded,
                            iconColor: const Color(0xFF475569),
                            title: 'Keamanan & Ganti Sandi',
                            subtitle: 'Atur ulang kata sandi akun Anda',
                            onTap: () => context.push(AppRoutes.changePassword),
                          ),
                          _buildMenuCard(
                            icon: Icons.notifications_none_rounded,
                            iconColor: const Color(0xFF475569),
                            title: 'Pemberitahuan & Notifikasi',
                            subtitle: 'Lihat pesan sistem dan pengingat kelas',
                            onTap: () => context.push(AppRoutes.notifications),
                          ),
                          _buildMenuCard(
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFF475569),
                            title: 'Bantuan & FAQ',
                            subtitle: 'Panduan platform Metro Institute',
                            onTap: _showHelpSheet,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 6. Logout Card (Matching Card Style, triggers Tiket Sobek) ─
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMenuCard(
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFDC2626),
                        iconBgColor: const Color(0xFFFEE2E2),
                        title: 'Keluar dari Akun',
                        titleColor: const Color(0xFFDC2626),
                        subtitle: 'Keluar dan akhiri sesi login Anda',
                        chevronColor: const Color(0xFFDC2626),
                        onTap: _handleLogout,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Version Tag
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

                    const SizedBox(height: 110), // Padding for bottom navbar
                  ],
                ),
              ),
            ),
    );
  }

  // ── Frosted Glass Circular Icon Button ─────────────────────────────────────
  Widget _circleIconButton({
    required IconData icon,
    required double iconSize,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            if (hasBadge)
              Positioned(
                top: 8,
                right: 8,
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
    );
  }

  // ── 3-Column Minimalist Stat Column ────────────────────────────────────────
  Widget _buildStatColumn({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Individual Menu Item Card (Matching Reference UI) ──────────────────────
  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    Color? iconBgColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    Color? chevronColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor ?? const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconBgColor != null ? Colors.transparent : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
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
                          color: titleColor ?? const Color(0xFF0F172A),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: chevronColor ?? const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Help Modal Sheet ───────────────────────────────────────────────────────
  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                color: const Color(0xFF0F172A),
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
                padding: const EdgeInsets.symmetric(vertical: 13),
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
  }
}
