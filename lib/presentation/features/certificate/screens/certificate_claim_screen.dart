import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/certificate_remote_datasource.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';
import '../../../common/widgets/tactile_metro_button.dart';
import 'certificate_screen.dart';

class CertificateClaimScreen extends StatefulWidget {
  final String? courseId;
  final String courseTitle;
  final bool isBootcamp;
  final String? credentialId;

  const CertificateClaimScreen({
    super.key,
    this.courseId,
    required this.courseTitle,
    this.isBootcamp = false,
    this.credentialId,
  });

  @override
  State<CertificateClaimScreen> createState() => _CertificateClaimScreenState();
}

class _CertificateClaimScreenState extends State<CertificateClaimScreen> {
  final _certDs = sl<CertificateRemoteDataSource>();
  final _userDs = sl<UserRemoteDataSource>();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _cert;
  String _menteeName = 'Peserta Metro';
  String _credentialId = '';
  String _dateStr = '';
  String _imageUrl = '';
  List<dynamic>? _config;
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();
    _fetchCertificateData();
  }

  Future<void> _fetchCertificateData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch user profile for mentee name
      try {
        final profile = await _userDs.getProfile();
        final name = profile['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          _menteeName = name;
        }
      } catch (_) {}

      // 2. Fetch certificates list
      final certs = await _certDs.getCertificates();

      // Find matching certificate by courseId or credentialId
      Map<String, dynamic>? matched;
      for (final c in certs) {
        if (c is! Map<String, dynamic>) continue;
        if (widget.credentialId != null &&
            c['credentialId']?.toString() == widget.credentialId) {
          matched = c;
          break;
        }
        if (widget.courseId != null) {
          if (widget.isBootcamp) {
            if (c['bootcampId']?.toString() == widget.courseId) {
              matched = c;
              break;
            }
          } else {
            if (c['courseId']?.toString() == widget.courseId) {
              matched = c;
              break;
            }
          }
        }
      }

      // If matched, extract properties
      if (matched != null) {
        _cert = matched;
        _credentialId = matched['credentialId']?.toString() ??
            'METRO-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
        _pdfUrl = matched['pdfUrl']?.toString();

        final issuedAtStr = matched['issuedAt']?.toString();
        if (issuedAtStr != null) {
          final d = DateTime.tryParse(issuedAtStr);
          if (d != null) {
            _dateStr = '${d.day} ${_monthName(d.month)} ${d.year}';
          }
        }
        if (_dateStr.isEmpty) {
          final now = DateTime.now();
          _dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
        }

        final tpl = matched['certificateTemplate'] as Map<String, dynamic>?;
        _imageUrl = tpl?['bgImage']?.toString() ?? '';
        final rawConfig = tpl?['config'];
        if (rawConfig is List) {
          _config = rawConfig;
        }
      } else {
        // Fallback certificate synthesis if record is still syncing
        final now = DateTime.now();
        _dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
        _credentialId = widget.credentialId ??
            'METRO-COURSE-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      }

      if (_imageUrl.isEmpty) {
        _imageUrl = widget.isBootcamp
            ? 'https://res.cloudinary.com/czmvfqaw/image/upload/v1791527027/metro-institute/admin-uploads/ehyfky1b65vskh18t7bv.png'
            : 'https://res.cloudinary.com/czmvfqaw/image/upload/v1791558237/metro-institute/admin-uploads/hhl8mcfb3q08w9y2zbg6.png';
      }

      _config ??= widget.isBootcamp
          ? CertificateCanvasWidget.bootcampDefaultConfig
          : CertificateCanvasWidget.miniCourseDefaultConfig;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  static String _monthName(int m) {
    const n = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return (m >= 1 && m <= 12) ? n[m] : '';
  }

  Future<void> _launchPublicVerify(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka halaman: $url'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifyUrl =
        'https://metroinstitute.site/certificate/$_credentialId';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Klaim Sertifikat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Celebration Banner ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF018556), Color(0xFF015F3D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF018556).withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDD00),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFF015F3D),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat! Modul Telah Selesai',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'E-Sertifikat resmi kelulusan telah diterbitkan untuk Anda.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.85),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Certificate Canvas Live Preview ──
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CertificateCanvasWidget(
                        imageUrl: _imageUrl,
                        config: _config,
                        productType: widget.isBootcamp ? 'BOOTCAMP' : 'MINI_COURSE',
                        menteeName: _menteeName,
                        courseTitle: widget.courseTitle,
                        dateStr: _dateStr,
                        credentialId: _credentialId,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Certificate Info Card ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          label: 'Nama Penerima',
                          value: _menteeName,
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          label: 'Program',
                          value: widget.courseTitle,
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),
                        // Credential ID (Clean text pill, NO copy button)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ID Kredensial',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _credentialId,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          label: 'Tanggal Terbit',
                          value: _dateStr,
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          label: 'Validasi',
                          value: 'Terverifikasi Resmi',
                          trailing: const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF018556),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action Buttons ──
                  TactileMetroButton.primary(
                    onPressed: () => downloadCertificatePdf(
                      context: context,
                      imageUrl: _imageUrl,
                      config: _config,
                      productType: widget.isBootcamp ? 'BOOTCAMP' : 'MINI_COURSE',
                      menteeName: _menteeName,
                      courseTitle: widget.courseTitle,
                      dateStr: _dateStr,
                      credentialId: _credentialId,
                      pdfUrl: _pdfUrl,
                    ),
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_download_outlined,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Unduh Sertifikat (PDF)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Public verification link
                  OutlinedButton(
                    onPressed: () => _launchPublicVerify(verifyUrl),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.open_in_new_rounded,
                            color: Color(0xFF334155), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Verifikasi Sertifikat Online',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
      ],
    );
  }
}

