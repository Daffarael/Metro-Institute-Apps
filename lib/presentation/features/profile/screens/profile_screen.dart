import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/certificate_remote_datasource.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../common/widgets/tear_ticket_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static void clearCache() {
    _ProfileScreenState._cachedUser = null;
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _keyCustomCover = 'key_mentee_profile_cover';

  final AuthRepository _authRepo = sl<AuthRepository>();
  final CertificateRemoteDataSource _certDs = sl<CertificateRemoteDataSource>();

  UserModel? _user;
  static UserModel? _cachedUser;
  bool _isLoading = true;
  int _certCount = 0;
  String? _customCover;

  @override
  void initState() {
    super.initState();
    if (_cachedUser != null) {
      _user = _cachedUser;
      _isLoading = false;
    }
    _loadCustomCover();
    _loadUser();
  }

  Future<void> _loadCustomCover() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cover = prefs.getString(_keyCustomCover);
      if (mounted) {
        setState(() {
          _customCover = cover;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCustomCover(String cover) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCustomCover, cover);
      if (mounted) {
        setState(() {
          _customCover = cover;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickCoverFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null) {
        await _saveCustomCover('file:${picked.path}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto sampul berhasil diperbarui!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF018556),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memilih gambar: $e',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _renderRawCover() {
    final cover = _customCover ?? 'asset:team';
    if (cover.startsWith('file:')) {
      final path = cover.replaceFirst('file:', '');
      final f = File(path);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/onboarding_team.jpg',
            fit: BoxFit.cover,
          ),
        );
      }
    } else if (cover == 'asset:intro') {
      return Image.asset('assets/images/onboarding_intro.jpg', fit: BoxFit.cover);
    } else if (cover == 'asset:design') {
      return Image.asset('assets/images/challenge_graphic_design.png', fit: BoxFit.cover);
    } else if (cover == 'asset:workshop1') {
      return Image.asset('assets/images/challenge_workshop_1.png', fit: BoxFit.cover);
    } else if (cover == 'asset:workshop2') {
      return Image.asset('assets/images/challenge_workshop_2.png', fit: BoxFit.cover);
    } else if (cover == 'gradient:emerald') {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF018556), Color(0xFF063D2A)],
          ),
        ),
      );
    } else if (cover == 'gradient:sunset') {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF018556), Color(0xFFFAE653)],
          ),
        ),
      );
    } else if (cover == 'gradient:midnight') {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF334155)],
          ),
        ),
      );
    }

    // Default 'asset:team'
    return Image.asset(
      'assets/images/onboarding_team.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF018556)),
    );
  }

  void _showCoverPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ubah Foto Sampul',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (_customCover != null && _customCover != 'asset:team')
                    TextButton(
                      onPressed: () {
                        _saveCustomCover('asset:team');
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Reset Default',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Sesuaikan tampilan background profil Anda sesuka hati.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              // Button: Upload from Gallery
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickCoverFromGallery();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF018556),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih dari Galeri',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Gunakan foto atau wallpaper favorit Anda',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'Pilihan Tema Eksklusif Metro',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),

              // Preset options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetCoverTile(
                      label: 'Team Collab',
                      presetKey: 'asset:team',
                      previewWidget: Image.asset('assets/images/onboarding_team.jpg', fit: BoxFit.cover),
                      onSelect: () {
                        _saveCustomCover('asset:team');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPresetCoverTile(
                      label: 'Metro Intro',
                      presetKey: 'asset:intro',
                      previewWidget: Image.asset('assets/images/onboarding_intro.jpg', fit: BoxFit.cover),
                      onSelect: () {
                        _saveCustomCover('asset:intro');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPresetCoverTile(
                      label: 'Design Lab',
                      presetKey: 'asset:design',
                      previewWidget: Image.asset('assets/images/challenge_graphic_design.png', fit: BoxFit.cover),
                      onSelect: () {
                        _saveCustomCover('asset:design');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPresetCoverTile(
                      label: 'Workshop 1',
                      presetKey: 'asset:workshop1',
                      previewWidget: Image.asset('assets/images/challenge_workshop_1.png', fit: BoxFit.cover),
                      onSelect: () {
                        _saveCustomCover('asset:workshop1');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPresetCoverTile(
                      label: 'Workshop 2',
                      presetKey: 'asset:workshop2',
                      previewWidget: Image.asset('assets/images/challenge_workshop_2.png', fit: BoxFit.cover),
                      onSelect: () {
                        _saveCustomCover('asset:workshop2');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPresetCoverTile(
                      label: 'Emerald Metro',
                      presetKey: 'gradient:emerald',
                      previewWidget: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF018556), Color(0xFF063D2A)],
                          ),
                        ),
                      ),
                      onSelect: () {
                        _saveCustomCover('gradient:emerald');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPresetCoverTile(
                      label: 'Sunset Gold',
                      presetKey: 'gradient:sunset',
                      previewWidget: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF018556), Color(0xFFFAE653)],
                          ),
                        ),
                      ),
                      onSelect: () {
                        _saveCustomCover('gradient:sunset');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPresetCoverTile(
                      label: 'Midnight Slate',
                      presetKey: 'gradient:midnight',
                      previewWidget: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0F172A), Color(0xFF334155)],
                          ),
                        ),
                      ),
                      onSelect: () {
                        _saveCustomCover('gradient:midnight');
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetCoverTile({
    required String label,
    required String presetKey,
    required Widget previewWidget,
    required VoidCallback onSelect,
  }) {
    final isSelected = (_customCover ?? 'asset:team') == presetKey;
    return GestureDetector(
      onTap: onSelect,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF018556) : const Color(0xFFE2E8F0),
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                previewWidget,
                if (isSelected)
                  Container(
                    color: const Color(0xFF018556).withValues(alpha: 0.35),
                    child: const Center(
                      child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF018556) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
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
      final refreshed = results[0] as UserModel?;
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
                    // ── 1. Hero Header with Blur & Seamless Fade (Zero Visible Cut/Line) ──
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Cover Image with Real Gaussian Blur & Multi-stop Seamless Fade
                        SizedBox(
                          height: 250,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Blurred Cover Image / Gradient
                              ClipRect(
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                  child: Transform.scale(
                                    scale: 1.18,
                                    child: _renderRawCover(),
                                  ),
                                ),
                              ),

                              // Translucent dark tint for top contrast
                              Container(
                                color: Colors.black.withValues(alpha: 0.18),
                              ),

                              // Multi-stop seamless gradient fade into #FAF9F5 canvas
                              // Solid #FAF9F5 takes over completely before the bottom edge
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.35),
                                        Colors.transparent,
                                        const Color(0xFFFAF9F5).withValues(alpha: 0.20),
                                        const Color(0xFFFAF9F5).withValues(alpha: 0.60),
                                        const Color(0xFFFAF9F5).withValues(alpha: 0.90),
                                        const Color(0xFFFAF9F5),
                                        const Color(0xFFFAF9F5),
                                      ],
                                      stops: const [0.0, 0.28, 0.52, 0.70, 0.84, 0.93, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Tap anywhere on cover to trigger customize sheet
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showCoverPickerSheet,
                                    splashColor: Colors.white.withValues(alpha: 0.1),
                                    highlightColor: Colors.transparent,
                                  ),
                                ),
                              ),

                              // "Ubah Cover" pill button
                              Positioned(
                                top: topPadding + 46,
                                right: 16,
                                child: GestureDetector(
                                  onTap: _showCoverPickerSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.30),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Ubah Cover',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top Navigation Icons (Back/Home & Notifications) + Title
                        Positioned(
                          top: topPadding + 6,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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

                              Text(
                                'Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),

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
                          top: 175,
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
                    const SizedBox(height: 22),

                    // ── 2. User Name & Subtitle ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
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

                    // ── 3. Integrated 3-Column Stats Row (Total XP | Sertifikat | Day Streak) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                        ),
                        child: Row(
                          children: [
                            // 1. Total XP
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
                            // 2. Sertifikat
                            _buildStatColumn(
                              value: '$_certCount',
                              label: 'Sertifikat',
                              onTap: () => context.push(AppRoutes.certificate),
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                            // 3. Day Streak
                            _buildStatColumn(
                              value: '$streak',
                              label: 'Day Streak',
                              onTap: () => context.push(AppRoutes.xpActivity),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 4. Section 1: Aktivitas & Pembelajaran ────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktivitas & Pembelajaran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
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
                            icon: Icons.military_tech_rounded,
                            iconColor: const Color(0xFF018556),
                            title: 'Sertifikat Saya',
                            subtitle: 'Periksa dan unduh kredensial sertifikat Anda',
                            onTap: () => context.push(AppRoutes.certificate),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 5. Section 2: Pengaturan & Akun ───────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengaturan & Akun',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
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

                    // ── 6. Distinct Destructive Logout Action (Different from standard menu cards) ─
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleLogout,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Keluar dari Akun',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Akhiri sesi dan amankan akun Anda',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF991B1B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFECACA), width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.confirmation_number_outlined,
                                          size: 13,
                                          color: Color(0xFFDC2626),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sobek Tiket',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 110), // Padding for floating bottom navbar
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
