import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/datasources/remote/certificate_remote_datasource.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  static void clearCache() => _CertificateScreenState.clearCache();

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _certDs = sl<CertificateRemoteDataSource>();
  final _userDs = sl<UserRemoteDataSource>();
  static List<dynamic>? _cachedCertificates;
  static String? _cachedUserName;

  static void clearCache() {
    _cachedCertificates = null;
    _cachedUserName = null;
  }

  late bool _isLoading = _cachedCertificates == null;
  List<dynamic> _certificates = _cachedCertificates ?? [];
  String? _userName = _cachedUserName;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    if (_cachedCertificates == null) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await _certDs.getCertificates();
      _cachedCertificates = list;

      // Fetch user profile for mentee name
      if (_userName == null) {
        try {
          final profile = await _userDs.getProfile();
          final name = profile['name']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            _userName = name;
            _cachedUserName = name;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _certificates = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
      'Desember',
    ];
    return n[m];
  }

  String _typeLabel(Map<String, dynamic> c) {
    final t = c['productType']?.toString().toUpperCase() ?? '';
    if (t.contains('BOOTCAMP')) return 'Bootcamp';
    if (t.contains('WEBINAR')) return 'Webinar';
    return 'Mini Course';
  }

  Color _typeColor(Map<String, dynamic> c) {
    final t = c['productType']?.toString().toUpperCase() ?? '';
    if (t.contains('BOOTCAMP')) return const Color(0xFF6366F1);
    if (t.contains('WEBINAR')) return const Color(0xFF0284C7);
    return const Color(0xFF10B981);
  }

  Color _typeBgColor(Map<String, dynamic> c) {
    final t = c['productType']?.toString().toUpperCase() ?? '';
    if (t.contains('BOOTCAMP')) return const Color(0xFFEEF2FF);
    if (t.contains('WEBINAR')) return const Color(0xFFE0F2FE);
    return const Color(0xFFECFDF5);
  }

  int get _bootcampCount => _certificates
      .where((c) => (c['productType']?.toString().toUpperCase() ?? '').contains('BOOTCAMP'))
      .length;

  int get _courseCount => _certificates
      .where((c) =>
          (c['productType']?.toString().toUpperCase() ?? '').contains('COURSE') ||
          (c['productType']?.toString().toUpperCase() ?? '').contains('MINI_COURSE'))
      .length;

  int get _webinarCount => _certificates
      .where((c) => (c['productType']?.toString().toUpperCase() ?? '').contains('WEBINAR'))
      .length;

  List<dynamic> get _filteredCertificates {
    return _certificates.where((item) {
      if (item is! Map<String, dynamic>) return false;
      final type = item['productType']?.toString().toUpperCase() ?? '';

      // Filter by type
      if (_selectedType == 'BOOTCAMP' && !type.contains('BOOTCAMP')) {
        return false;
      }
      if (_selectedType == 'MINI_COURSE' &&
          !type.contains('COURSE') &&
          !type.contains('MINI_COURSE')) {
        return false;
      }
      if (_selectedType == 'WEBINAR' && !type.contains('WEBINAR')) {
        return false;
      }

      // Filter by search query (title or credentialId)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (item['course']?['title'] ??
                item['bootcamp']?['title'] ??
                item['webinar']?['title'] ??
                item['productName'] ??
                '')
            .toString()
            .toLowerCase();
        final credId = (item['credentialId'] ?? '').toString().toLowerCase();

        if (!title.contains(q) && !credId.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCertificates;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5), // Warm ivory canvas
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF0F172A),
          onRefresh: () async {
            _cachedCertificates = null;
            await _loadCertificates();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header (Title & Subtitle) ─────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sertifikat Saya',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kredensial resmi kelulusan & sertifikasi kompetensi.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Unified Metrics Card ──────────────────────────────
                      _buildUnifiedStatsCard(
                        total: _certificates.length,
                        bootcamp: _bootcampCount,
                        course: _courseCount,
                      ),
                      const SizedBox(height: 16),

                      // ── Search Bar ────────────────────────────────────────
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x060F172A),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                cursorColor: const Color(0xFF0F172A),
                                cursorWidth: 1.5,
                                onChanged: (val) {
                                  setState(() => _searchQuery = val.trim());
                                },
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  hintText: 'Cari sertifikat atau ID kredensial...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF64748B),
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Type Filter Pills ──────────────────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'Semua (${_certificates.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('BOOTCAMP', 'Bootcamp ($_bootcampCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('MINI_COURSE', 'Mini Course ($_courseCount)'),
                            if (_webinarCount > 0) ...[
                              const SizedBox(width: 8),
                              _buildFilterChip('WEBINAR', 'Webinar ($_webinarCount)'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Section Header ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Kredensial',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${filtered.length} ditemukan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Certificates List / States ──────────────────────────────
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: _buildCleanEmptyState(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cert = filtered[index] as Map<String, dynamic>;
                        return _CertCard(
                          cert: cert,
                          fallbackUserName: _userName,
                          typeLabel: _typeLabel(cert),
                          typeColor: _typeColor(cert),
                          typeBgColor: _typeBgColor(cert),
                          monthName: _monthName,
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Unified Stats Card ──────────────────────────────────────────────────────
  Widget _buildUnifiedStatsCard({
    required int total,
    required int bootcamp,
    required int course,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatColumn(
              label: 'Total Sertifikat',
              value: '$total',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFF1F5F9),
          ),
          Expanded(
            child: _buildStatColumn(
              label: 'Bootcamp',
              value: '$bootcamp',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFF1F5F9),
          ),
          Expanded(
            child: _buildStatColumn(
              label: 'Mini Course',
              value: '$course',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── Filter Chip Widget ──────────────────────────────────────────────────────
  Widget _buildFilterChip(String typeKey, String label) {
    final isSelected = _selectedType == typeKey;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedType = typeKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1F0F172A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x040F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ── Clean Empty State ───────────────────────────────────────────────────────
  Widget _buildCleanEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty || _selectedType != 'ALL';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 28,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered ? 'Tidak Ada Sertifikat Ditemukan' : 'Belum Ada Sertifikat',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Coba atur ulang kata kunci pencarian atau reset filter tipe.'
                : 'Selesaikan Bootcamp atau Mini Course untuk meraih sertifikat digital resmi yang terverifikasi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (isFiltered)
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedType = 'ALL';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Reset Filter',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.learn),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(
                'Mulai Belajar Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── CERTIFICATE CANVAS WIDGET ────────────────────────────────────────────────
// Renders the template background image + user data exactly according to
// the admin Visual Editor Canvas (800x600 resolution)
class CertificateCanvasWidget extends StatelessWidget {
  final String imageUrl;
  final List<dynamic>? config;
  final String productType;
  final String menteeName;
  final String courseTitle;
  final String dateStr;
  final String credentialId;

  // 1:1 Exact layout configuration from Admin Visual Editor for Mini Course (cmv0lfpfb0000oyrvnprawsn3)
  static const List<Map<String, dynamic>> miniCourseDefaultConfig = [
    {
      "x": 400.0,
      "y": 319.0,
      "id": "MenteeName",
      "type": "text",
      "color": "#000000",
      "label": "NAMA MENTEE",
      "fontSize": 32.0,
    },
    {
      "x": 400.0,
      "y": 215.0,
      "id": "CourseName",
      "type": "text",
      "color": "#4B5563",
      "label": "JUDUL KURSUS / BOOTCAMP",
      "fontSize": 24.0,
    },
    {
      "x": 93.0,
      "y": 53.0,
      "id": "Date",
      "type": "text",
      "color": "#6B7280",
      "label": "Tanggal Lulus",
      "fontSize": 10.0,
    },
    {
      "x": 715.0,
      "y": 53.0,
      "id": "CredentialId",
      "type": "text",
      "color": "#6B7280",
      "label": "ID Kredensial",
      "fontSize": 10.0,
    },
    {
      "x": 247.0,
      "y": 557.0,
      "id": "CeoName",
      "type": "text",
      "color": "#000000",
      "label": "Nama CEO",
      "fontSize": 18.0,
    },
    {
      "x": 561.0,
      "y": 557.0,
      "id": "LeadName",
      "type": "text",
      "color": "#000000",
      "label": "Daffarael Anaqi Ali",
      "fontSize": 18.0,
    },
    {
      "x": 400.0,
      "y": 395.0,
      "id": "Text_1791527787636",
      "type": "text",
      "color": "#000000",
      "label": "Penghargaan ini diberikan atas prestasi luar biasa telah menyelesaikan mini course di Metro Institute.",
      "width": 432.0,
      "fontSize": 12.0,
    },
    {
      "x": 552.0,
      "y": 495.0,
      "id": "Sig_1791558985825",
      "src": "https://res.cloudinary.com/czmvfqaw/image/upload/e_make_transparent:20/v1791558987/metro-institute/admin-uploads/ggql83ovbkrvu9v4hdtw.png",
      "type": "image",
      "color": "#000000",
      "label": "Tanda Tangan",
      "width": 78.0,
      "fontSize": 24.0,
      "transparentBg": true,
    },
  ];

  // 1:1 Exact layout configuration from Admin Visual Editor for Bootcamp (cmuzwv4mk0000trjq2vkuesgy)
  static const List<Map<String, dynamic>> bootcampDefaultConfig = [
    {
      "x": 410.0,
      "y": 279.0,
      "id": "MenteeName",
      "type": "text",
      "color": "#000000",
      "label": "NAMA MENTEE",
      "width": 420.0,
      "fontSize": 21.0,
    },
    {
      "x": 402.0,
      "y": 202.0,
      "id": "CourseName",
      "type": "text",
      "color": "#4B5563",
      "label": "JUDUL KURSUS / BOOTCAMP",
      "fontSize": 12.0,
    },
    {
      "x": 703.0,
      "y": 83.0,
      "id": "Date",
      "type": "text",
      "color": "#6B7280",
      "label": "Tanggal Lulus",
      "fontSize": 11.0,
    },
    {
      "x": 104.0,
      "y": 117.0,
      "id": "CredentialId",
      "type": "text",
      "color": "#6B7280",
      "label": "ID Kredensial",
      "fontSize": 10.0,
    },
    {
      "x": 200.0,
      "y": 500.0,
      "id": "CeoName",
      "type": "text",
      "color": "#000000",
      "label": "Nama CEO",
      "fontSize": 18.0,
    },
    {
      "x": 600.0,
      "y": 500.0,
      "id": "LeadName",
      "type": "text",
      "color": "#000000",
      "label": "Nama Lead Community",
      "fontSize": 18.0,
    },
    {
      "x": 402.0,
      "y": 356.0,
      "id": "Text_1791486489788",
      "type": "text",
      "color": "#000000",
      "label": "Sertifikat ini diberikan sebagai bukti partisipasi dan apresiasi atas kontribusi yang telah diberikan selama masa Bootcamp FTI.",
      "width": 537.0,
      "fontSize": 15.0,
    },
  ];

  static String resolveItemImageUrl(String src, bool transparentBg) {
    if (src.isEmpty) return src;
    if (transparentBg && src.contains('/image/upload/') && !src.contains('e_make_transparent')) {
      return src.replaceFirst('/image/upload/', '/image/upload/e_make_transparent:20/');
    }
    return src;
  }

  const CertificateCanvasWidget({
    super.key,
    required this.imageUrl,
    this.config,
    this.productType = 'MINI_COURSE',
    required this.menteeName,
    required this.courseTitle,
    required this.dateStr,
    required this.credentialId,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 800 / 600, // Exact 4:3 template aspect ratio matching admin
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final scale = w / 800.0;

          // Pick active config: use backend config if present; otherwise fallback to exact admin template
          final items = (config != null && config!.isNotEmpty)
              ? config!
              : (productType.toUpperCase().contains('BOOTCAMP')
                  ? bootcampDefaultConfig
                  : miniCourseDefaultConfig);

          return Container(
            width: w,
            height: h,
            color: Colors.white,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. Template Background Image
                Positioned.fill(
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.fill,
                          placeholder: (context, url) => _buildCanvasPlaceholder(),
                          errorWidget: (context, url, error) => _buildCanvasPlaceholder(),
                        )
                      : _buildCanvasPlaceholder(),
                ),

                // 2. Data Elements Overlay
                for (final item in items)
                  if (item is Map) _buildItem(item, scale, w),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(Map item, double scale, double containerWidth) {
    final id = item['id']?.toString() ?? '';
    final type = item['type']?.toString();
    final rawX = double.tryParse('${item['x']}') ?? 400.0;
    final rawY = double.tryParse('${item['y']}') ?? 300.0;
    final rawFontSize = double.tryParse('${item['fontSize']}') ?? 16.0;
    final colorHex = item['color']?.toString() ?? '#0F172A';
    final color = _parseColor(colorHex);

    final x = rawX * scale;
    final y = rawY * scale;
    final fontSize = (rawFontSize * scale).clamp(6.0, 48.0);

    // Text content mapping
    String text = '';
    if (id == 'MenteeName') {
      text = menteeName;
    } else if (id == 'CourseName') {
      text = courseTitle;
    } else if (id == 'Date') {
      text = dateStr;
    } else if (id == 'CredentialId') {
      text = credentialId;
    } else if (id == 'CeoName') {
      text = item['label']?.toString() ?? 'Nama CEO';
    } else if (id == 'LeadName') {
      text = item['label']?.toString() ?? 'Nama Lead Community';
    } else {
      text = item['label']?.toString() ?? '';
    }

    if (text.isEmpty && type != 'image') {
      return const SizedBox.shrink();
    }

    // Image item (e.g. signature or stamp)
    if (type == 'image' && item['src'] != null) {
      final imgWidth = (double.tryParse('${item['width']}') ?? 78.0) * scale;
      final isTransparent = item['transparentBg'] == true;
      final resolvedUrl = resolveItemImageUrl(item['src'].toString(), isTransparent);
      return Positioned(
        left: x,
        top: y,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: CachedNetworkImage(
            imageUrl: resolvedUrl,
            width: imgWidth,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    // Typography selection based on item ID
    TextStyle textStyle;
    if (id == 'MenteeName') {
      textStyle = GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      );
    } else if (id == 'CourseName') {
      textStyle = GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      );
    } else if (id == 'Date' || id == 'CredentialId') {
      textStyle = GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );
    } else {
      textStyle = GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.35,
      );
    }

    final itemWidth = item['width'] != null
        ? (double.tryParse('${item['width']}') ?? 400.0) * scale
        : (id == 'MenteeName' || id == 'CourseName' ? containerWidth * 0.85 : containerWidth * 0.4);

    return Positioned(
      left: x,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: itemWidth),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: (id == 'MenteeName' || id == 'CourseName' || id == 'Date' || id == 'CredentialId') ? 1 : 4,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF0F172A);
  }

  Widget _buildCanvasPlaceholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Icon(Icons.workspace_premium_outlined, size: 40, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

// ── CERTIFICATE CARD WIDGET ──────────────────────────────────────────────────
class _CertCard extends StatelessWidget {
  final Map<String, dynamic> cert;
  final String? fallbackUserName;
  final String typeLabel;
  final Color typeColor;
  final Color typeBgColor;
  final String Function(int) monthName;

  const _CertCard({
    required this.cert,
    this.fallbackUserName,
    required this.typeLabel,
    required this.typeColor,
    required this.typeBgColor,
    required this.monthName,
  });

  String get _title =>
      cert['course']?['title'] ??
      cert['bootcamp']?['title'] ??
      cert['webinar']?['title'] ??
      cert['productName'] ??
      'Sertifikat Kelulusan';

  String get _credId => cert['credentialId'] ?? 'CERT-0000';

  String get _productType => cert['productType']?.toString().toUpperCase() ?? 'MINI_COURSE';

  String get _dateStr {
    final d = cert['issuedAt'] != null ? DateTime.tryParse(cert['issuedAt'])?.toLocal() : null;
    return d != null ? '${d.day} ${monthName(d.month)} ${d.year}' : '—';
  }

  String get _menteeName {
    final name = cert['user']?['name'] ?? cert['userName'] ?? fallbackUserName;
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }
    return 'Daffarael Anaqi Ali';
  }

  List<dynamic>? get _templateConfig {
    final raw = cert['certificateTemplate']?['config'] ??
        cert['course']?['certificateTemplate']?['config'] ??
        cert['bootcamp']?['certificateTemplate']?['config'] ??
        cert['webinar']?['certificateTemplate']?['config'] ??
        cert['config'];
    if (raw == null) return null;
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return null;
  }

  String _resolveImageUrl() {
    final raw = (cert['imageUrl'] ??
            cert['certificateTemplate']?['bgImage'] ??
            cert['course']?['certificateTemplate']?['bgImage'] ??
            cert['bootcamp']?['certificateTemplate']?['bgImage'] ??
            cert['webinar']?['certificateTemplate']?['bgImage'] ??
            cert['course']?['thumbnailUrl'] ??
            cert['bootcamp']?['thumbnailUrl'] ??
            cert['webinar']?['bannerUrl'] ??
            '')
        .toString()
        .trim();
    if (raw.isEmpty || raw == 'null') return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return 'https://api.metroinstitute.site$raw';
    return 'https://$raw';
  }

  String? get _pdfUrl => cert['pdfUrl'] as String?;

  void _showDetail(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CertDetailSheet(
        cert: cert,
        title: _title,
        credId: _credId,
        dateStr: _dateStr,
        menteeName: _menteeName,
        typeLabel: typeLabel,
        typeColor: typeColor,
        imageUrl: _resolveImageUrl(),
        config: _templateConfig,
        productType: _productType,
        pdfUrl: _pdfUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final imageUrl = _resolveImageUrl();
    final config = _templateConfig;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDetail(ctx),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Certificate Canvas with Admin Layout Positions ───────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              child: CertificateCanvasWidget(
                imageUrl: imageUrl,
                config: config,
                productType: _productType,
                menteeName: _menteeName,
                courseTitle: _title,
                dateStr: _dateStr,
                credentialId: _credId,
              ),
            ),

            // ── Clean Certificate Information (Clean, No AI Slop) ─────────
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program Title
                  Text(
                    _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Minimal category & issue date line
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 3.5,
                        height: 3.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        'Diterbitkan $_dateStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Credential ID Pill with copy action
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: _credId));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('ID Kredensial berhasil disalin!'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ID: $_credId',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons (Detail & Direct PDF Download)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showDetail(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(
                            'Lihat Detail',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadCertificatePdf(
                            context: ctx,
                            imageUrl: imageUrl,
                            config: config,
                            productType: _productType,
                            menteeName: _menteeName,
                            courseTitle: _title,
                            dateStr: _dateStr,
                            credentialId: _credId,
                            pdfUrl: _pdfUrl,
                          ),
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: Text(
                            'Unduh PDF',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CERTIFICATE DETAIL BOTTOM SHEET ──────────────────────────────────────────
class _CertDetailSheet extends StatelessWidget {
  final Map<String, dynamic> cert;
  final String title, credId, dateStr, menteeName, typeLabel, productType;
  final Color typeColor;
  final String imageUrl;
  final List<dynamic>? config;
  final String? pdfUrl;

  const _CertDetailSheet({
    required this.cert,
    required this.title,
    required this.credId,
    required this.dateStr,
    required this.menteeName,
    required this.typeLabel,
    required this.typeColor,
    required this.imageUrl,
    required this.productType,
    this.config,
    this.pdfUrl,
  });

  Future<void> _launchPublicVerify(BuildContext ctx, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
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
  Widget build(BuildContext ctx) {
    final verifyUrl = 'https://metroinstitute.site/certificate/$credId';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF9F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  // ── Full Preview with Filled Canvas ────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CertificateCanvasWidget(
                      imageUrl: imageUrl,
                      config: config,
                      productType: productType,
                      menteeName: menteeName,
                      courseTitle: title,
                      dateStr: dateStr,
                      credentialId: credId,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Title & Meta ───────────────────────────────────
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$typeLabel · Diterbitkan $dateStr',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Minimalist Clean Verification Details (No AI Slop) ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        _buildCleanInfoRow(
                          ctx: ctx,
                          label: 'ID Kredensial',
                          value: credId,
                          isCopyable: true,
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildCleanInfoRow(
                          ctx: ctx,
                          label: 'Penerbit',
                          value: 'Metro Institute',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildCleanInfoRow(
                          ctx: ctx,
                          label: 'Status Validasi',
                          value: 'Terverifikasi Resmi',
                          trailing: const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Primary Action: Direct Download PDF ─────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadCertificatePdf(
                        context: ctx,
                        imageUrl: imageUrl,
                        config: config,
                        productType: productType,
                        menteeName: menteeName,
                        courseTitle: title,
                        dateStr: dateStr,
                        credentialId: credId,
                        pdfUrl: pdfUrl,
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: Text(
                        'Unduh Sertifikat (PDF)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Secondary Action: Buka Halaman Verifikasi Publik ─
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _launchPublicVerify(ctx, verifyUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(
                        'Buka Halaman Verifikasi Publik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
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

  Widget _buildCleanInfoRow({
    required BuildContext ctx,
    required String label,
    required String value,
    bool isCopyable = false,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        if (isCopyable)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('ID Kredensial disalin!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Row(
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
                const SizedBox(width: 4),
                const Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          )
        else
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
                const SizedBox(width: 6),
                trailing,
              ],
            ],
          ),
      ],
    );
  }
}

// ── ON-DEVICE PDF GENERATOR & DOWNLOADER ─────────────────────────────────────
Future<void> _downloadCertificatePdf({
  required BuildContext context,
  required String imageUrl,
  required List<dynamic>? config,
  required String productType,
  required String menteeName,
  required String courseTitle,
  required String dateStr,
  required String credentialId,
  String? pdfUrl,
}) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 12),
          Text('Menyiapkan file PDF sertifikat...'),
        ],
      ),
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );

  try {
    final dir = await getApplicationDocumentsDirectory();
    final cleanId = credentialId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = '${dir.path}/Sertifikat_$cleanId.pdf';

    // If pre-built remote PDF is available, download directly
    if (pdfUrl != null && pdfUrl.isNotEmpty && pdfUrl.startsWith('http')) {
      try {
        await ApiClient.dio.download(pdfUrl, filePath);
        final file = File(filePath);
        if (await file.exists()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sertifikat berhasil diunduh: ${file.path.split('/').last}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          await OpenFile.open(file.path);
          return;
        }
      } catch (_) {
        // Fall back to on-device synthesis if remote download fails
      }
    }

    // On-device vector PDF generation with template background + text coordinates
    Uint8List? bgImageBytes;
    if (imageUrl.isNotEmpty) {
      try {
        final res = await ApiClient.dio.get<List<int>>(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          bgImageBytes = Uint8List.fromList(res.data!);
        }
      } catch (_) {}
    }

    final doc = pw.Document();
    final pwImage = bgImageBytes != null ? pw.MemoryImage(bgImageBytes) : null;

    final items = (config != null && config.isNotEmpty)
        ? config
        : (productType.toUpperCase().contains('BOOTCAMP')
            ? CertificateCanvasWidget.bootcampDefaultConfig
            : CertificateCanvasWidget.miniCourseDefaultConfig);

    // Standard A4 landscape dimensions: 841.89 x 595.28 points
    const pdfWidth = 842.0;
    const pdfHeight = 595.0;
    const scaleX = pdfWidth / 800.0;
    const scaleY = pdfHeight / 600.0;

    // Pre-fetch signature image if present in items
    final Map<String, Uint8List> imageAssets = {};
    for (final item in items) {
      if (item is Map && item['type'] == 'image' && item['src'] != null) {
        final rawSrc = item['src'].toString();
        final isTransparent = item['transparentBg'] == true;
        final resolvedUrl = CertificateCanvasWidget.resolveItemImageUrl(rawSrc, isTransparent);
        try {
          final res = await ApiClient.dio.get<List<int>>(
            resolvedUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.data != null) {
            final bytes = Uint8List.fromList(res.data!);
            imageAssets[resolvedUrl] = bytes;
            imageAssets[rawSrc] = bytes;
          }
        } catch (_) {}
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return pw.Stack(
            children: [
              if (pwImage != null)
                pw.Positioned.fill(
                  child: pw.Image(pwImage, fit: pw.BoxFit.fill),
                )
              else
                pw.Positioned.fill(
                  child: pw.Container(color: PdfColors.white),
                ),
              for (final item in items)
                if (item is Map)
                  _buildPdfItem(
                    item,
                    scaleX,
                    scaleY,
                    menteeName,
                    courseTitle,
                    dateStr,
                    credentialId,
                    imageAssets,
                  ),
            ],
          );
        },
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await doc.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sertifikat berhasil diunduh: ${file.path.split('/').last}'),
          action: SnackBarAction(
            label: 'Buka',
            textColor: const Color(0xFFFBBF24),
            onPressed: () => OpenFile.open(file.path),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await OpenFile.open(file.path);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

pw.Widget _buildPdfItem(
  Map item,
  double scaleX,
  double scaleY,
  String menteeName,
  String courseTitle,
  String dateStr,
  String credentialId,
  Map<String, Uint8List> imageAssets,
) {
  final id = item['id']?.toString() ?? '';
  final type = item['type']?.toString();
  final rawX = double.tryParse('${item['x']}') ?? 400.0;
  final rawY = double.tryParse('${item['y']}') ?? 300.0;
  final rawFontSize = double.tryParse('${item['fontSize']}') ?? 16.0;

  final x = rawX * scaleX;
  final y = rawY * scaleY;
  final fontSize = (rawFontSize * ((scaleX + scaleY) / 2)).clamp(7.0, 48.0);

  // Image item (such as signature) in PDF
  if (type == 'image' && item['src'] != null) {
    final rawSrc = item['src'].toString();
    final isTransparent = item['transparentBg'] == true;
    final resolvedUrl = CertificateCanvasWidget.resolveItemImageUrl(rawSrc, isTransparent);
    final bytes = imageAssets[resolvedUrl] ?? imageAssets[rawSrc];
    if (bytes != null) {
      final imgWidth = (double.tryParse('${item['width']}') ?? 78.0) * scaleX;
      final pwImg = pw.MemoryImage(bytes);
      return pw.Positioned(
        left: x - (imgWidth / 2),
        top: y - (imgWidth * 0.4),
        child: pw.Image(pwImg, width: imgWidth),
      );
    }
    return pw.SizedBox.shrink();
  }

  String text = '';
  if (id == 'MenteeName') {
    text = menteeName;
  } else if (id == 'CourseName') {
    text = courseTitle;
  } else if (id == 'Date') {
    text = dateStr;
  } else if (id == 'CredentialId') {
    text = credentialId;
  } else if (id == 'CeoName') {
    text = item['label']?.toString() ?? 'Nama CEO';
  } else if (id == 'LeadName') {
    text = item['label']?.toString() ?? 'Nama Lead Community';
  } else {
    text = item['label']?.toString() ?? '';
  }

  if (text.isEmpty) return pw.SizedBox.shrink();

  final hexColor = (item['color']?.toString() ?? '#0F172A').replaceAll('#', '').trim();
  PdfColor textColor = PdfColors.black;
  try {
    if (hexColor.length == 6) {
      textColor = PdfColor.fromHex(hexColor);
    }
  } catch (_) {}

  final maxWidth = item['width'] != null
      ? (double.tryParse('${item['width']}') ?? 400.0) * scaleX
      : 550.0;

  return pw.Positioned(
    left: x - (maxWidth / 2),
    top: y - (fontSize * 0.75),
    child: pw.Container(
      width: maxWidth,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: (id == 'MenteeName' || id == 'CourseName')
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    ),
  );
}
