import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import 'tactile_metro_button.dart';

class LiveJoinConfirmDialog extends StatefulWidget {
  final String meetingUrl;

  const LiveJoinConfirmDialog({
    super.key,
    required this.meetingUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required String meetingUrl,
  }) async {
    final trimmed = meetingUrl.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan sesi live akan dibuka menjelang sesi dimulai.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LiveJoinConfirmDialog(meetingUrl: trimmed),
    );
  }

  @override
  State<LiveJoinConfirmDialog> createState() => _LiveJoinConfirmDialogState();
}

class _LiveJoinConfirmDialogState extends State<LiveJoinConfirmDialog> {
  int _countdown = 3;
  Timer? _timer;
  String _userEmail = '-';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        setState(() => _countdown = 0);
        timer.cancel();
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      final authRepo = sl<AuthRepository>();
      final saved = await authRepo.getSavedUser();
      if (saved != null && mounted) {
        setState(() {
          _userEmail = saved.email.isNotEmpty ? saved.email : '-';
          _userName = saved.name;
        });
        return;
      }
      final fresh = await authRepo.refreshProfile();
      if (mounted) {
        setState(() {
          _userEmail = fresh.email.isNotEmpty ? fresh.email : '-';
          _userName = fresh.name;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    if (_countdown > 0) return;

    String rawUrl = widget.meetingUrl.trim();
    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      rawUrl = 'https://$rawUrl';
    }

    if (_userEmail.isNotEmpty &&
        _userEmail != '-' &&
        rawUrl.contains('meet.google.com') &&
        !rawUrl.contains('authuser=')) {
      final sep = rawUrl.contains('?') ? '&' : '?';
      rawUrl = '$rawUrl${sep}authuser=${Uri.encodeComponent(_userEmail)}';
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();

    final uri = Uri.tryParse(rawUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka tautan sesi.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Konfirmasi Akun Presensi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Pastikan Anda login dan bergabung ke Google Meet menggunakan akun Gmail yang terdaftar berikut agar kehadiran Anda tercatat otomatis:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.55,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 14),

              // Account Info Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF475569),
                        ),
                        children: [
                          const TextSpan(
                            text: 'Gmail Terdaftar: ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: _userEmail,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_userName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: const Color(0xFF475569),
                          ),
                          children: [
                            const TextSpan(
                              text: 'Nama Akun: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: _userName,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TactileMetroButton.secondary(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'Batal',
                      height: 42,
                      fontSize: 13,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TactileMetroButton.primary(
                      onPressed: _countdown > 0 ? null : _handleProceed,
                      isDisabled: _countdown > 0,
                      text: _countdown > 0
                          ? 'Lanjutkan (${_countdown}s)'
                          : 'Lanjutkan ke Meet',
                      height: 42,
                      fontSize: 13,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
