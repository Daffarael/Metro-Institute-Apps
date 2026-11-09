import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/webinar_remote_datasource.dart';
import '../../learn/widgets/checkout_bottom_sheet.dart';

class InspireTalkDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const InspireTalkDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<InspireTalkDetailScreen> createState() => _InspireTalkDetailScreenState();
}

class _InspireTalkDetailScreenState extends State<InspireTalkDetailScreen> {
  final _webinarDs = sl<WebinarRemoteDataSource>();

  Map<String, dynamic>? _detail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final id = widget.item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final res = await _webinarDs.getWebinarDetail(id);
      if (!mounted) return;
      setState(() {
        _detail = res;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get _activeData => _detail ?? widget.item;

  bool get _isRegistered {
    final data = _activeData;
    return data['isRegistered'] == true || data['isEnrolled'] == true;
  }

  bool get _isEnded {
    final data = _activeData;
    if (data['isEnded'] == true || (data['status'] ?? '').toString().toUpperCase() == 'COMPLETED') return true;
    final scheduled = (data['scheduledAt'] ?? data['eventDate']) as String?;
    if (scheduled == null) return false;
    final sched = DateTime.tryParse(scheduled);
    if (sched == null) return false;
    final durMin = (data['duration'] as num?)?.toInt() ?? 90;
    return DateTime.now().isAfter(sched.add(Duration(minutes: durMin)));
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Jadwal segera diumumkan';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${DateFormat('HH:mm').format(dt)} WIB';
    } catch (_) {
      return '-';
    }
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Gratis';
    final str = amount.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(regExp, (m) => '${m[1]}.')}';
  }

  String _getItemImage() {
    final data = _activeData;
    final raw = (data['bannerUrl'] ??
            data['thumbnailUrl'] ??
            data['thumbnail'] ??
            data['banner'] ??
            widget.item['bannerUrl'] ??
            widget.item['thumbnailUrl'] ??
            widget.item['thumbnail'] ??
            widget.item['banner'] ??
            '') as String;
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return 'https://api.metroinstitute.site$raw';
    return 'https://$raw';
  }

  Future<void> _openMeetingUrl() async {
    final url = (_activeData['meetingUrl'] ?? '').toString();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan sesi live akan dibuka menjelang sesi dimulai.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka tautan sesi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openAttendanceDialog() {
    final id = _activeData['id']?.toString() ?? widget.item['id']?.toString() ?? '';
    final title = (_activeData['title'] ?? widget.item['title'] ?? 'Inspire Talk').toString();
    final feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Presensi Kehadiran',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tuliskan feedback singkat atau kesimpulan materi yang Anda dapatkan:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Materinya sangat relevan dan aplikatif...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setModalState(() => isSubmitting = true);
                      try {
                        await _webinarDs.attendWebinar(id, feedback: feedbackController.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Presensi berhasil dicatat. Terima kasih!'), backgroundColor: AppColors.primary),
                        );
                        _fetchDetail();
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSubmitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kirim Presensi'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCheckout() {
    final data = _activeData;
    final title = (data['title'] ?? widget.item['title'] ?? 'Inspire Talk').toString();
    final rawPrice = data['price'] ?? widget.item['price'] ?? 0;
    final price = (rawPrice is num) ? rawPrice.toInt() : 0;
    final id = (data['id'] ?? widget.item['id'] ?? '').toString();
    final thumbnail = _getItemImage();
    final speakerName = (data['speakerName'] ?? widget.item['speakerName']) as String?;

    CheckoutBottomSheet.show(
      context,
      title: title,
      price: price,
      productType: 'WEBINAR',
      productId: id,
      thumbnailUrl: thumbnail,
      subtitle: speakerName != null ? 'Pembicara: $speakerName' : null,
      onSuccess: () {
        setState(() {
          if (_detail != null) {
            _detail!['isRegistered'] = true;
          }
          widget.item['isRegistered'] = true;
          widget.item['isEnrolled'] = true;
        });
        _fetchDetail();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _activeData;
    final title = (data['title'] ?? widget.item['title'] ?? 'Inspire Talk').toString();
    final rawDesc = (data['description'] ?? data['shortDescription'] ?? widget.item['description'] ?? widget.item['shortDescription'] ?? '').toString();
    final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final field = (data['field'] ?? widget.item['field'] ?? 'DEVELOPMENT').toString().replaceAll('_', ' ');
    final speakerName = (data['speakerName'] ?? widget.item['speakerName'] ?? 'Pembicara Praktisi').toString();
    final speakerRole = (data['speakerRole'] ?? widget.item['speakerRole'] ?? 'Industry Expert').toString();
    final speakerAvatar = (data['speakerAvatarUrl'] ?? widget.item['speakerAvatarUrl']) as String?;
    final scheduledAt = (data['scheduledAt'] ?? widget.item['scheduledAt']) as String?;
    final duration = (data['duration'] ?? widget.item['duration'] ?? 90) as num;
    final rawPrice = data['price'] ?? widget.item['price'] ?? 0;
    final price = (rawPrice is num) ? rawPrice.toInt() : 0;
    final priceStr = _formatRupiah(price);
    final thumbnail = _getItemImage();
    final isReg = _isRegistered;
    final isEnded = _isEnded;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Inspire Talk',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Full Banner Container (16:9)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C0F172A),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(Icons.videocam_outlined, color: Color(0xFF64748B), size: 48),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.videocam_outlined, color: Color(0xFF64748B), size: 48),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Badges Row (Field, Inspire Talk, Status)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        field.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        'INSPIRE TALK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047857),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEnded ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isEnded ? const Color(0xFFCBD5E1) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        isEnded ? 'BERAKHIR' : 'LIVE INTERAKTIF',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isEnded ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Schedule Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildScheduleRow(
                        Icons.calendar_month_rounded,
                        'Hari & Tanggal',
                        _formatDate(scheduledAt),
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildScheduleRow(
                        Icons.access_time_rounded,
                        'Waktu Pelaksanaan',
                        '${_formatTime(scheduledAt)} (${duration.toInt()} Menit)',
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildScheduleRow(
                        Icons.videocam_rounded,
                        'Platform Sesi',
                        'Google Meet / Video Conference Live',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Speaker Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: (speakerAvatar != null && speakerAvatar.isNotEmpty)
                            ? NetworkImage(speakerAvatar)
                            : null,
                        child: (speakerAvatar == null || speakerAvatar.isEmpty)
                            ? Text(
                                speakerName.isNotEmpty ? speakerName[0].toUpperCase() : 'S',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: const Color(0xFF0F172A),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemateri Sesi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              speakerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              speakerRole,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 6. Section: Tentang Sesi
                Text(
                  'Tentang Sesi Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cleanDesc.isNotEmpty
                      ? cleanDesc
                      : 'Ikuti sesi Inspire Talk interaktif bersama praktisi industri terkemuka. Dapatkan wawasan langsung mengenai strategi karir, perkembangan teknologi, dan tips praktis di dunia kerja nyata.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF475569),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 22),

                // 7. Benefits Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benefit Peserta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(Icons.live_tv_rounded, 'Akses live interaktif & tanya jawab (Q&A) langsung'),
                      const SizedBox(height: 10),
                      _buildBenefitItem(Icons.verified_rounded, 'Sertifikat resmi kehadiran dari Metro Institute'),
                      const SizedBox(height: 10),
                      _buildBenefitItem(Icons.stars_rounded, 'Reward +50 XP akun Metro Institute'),
                      const SizedBox(height: 10),
                      _buildBenefitItem(Icons.video_library_rounded, 'Akses rekaman video (recording) setelah sesi selesai'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── STICKY BOTTOM BAR ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: isReg
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openAttendanceDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Presensi',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: isEnded
                                ? ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                                      disabledForegroundColor: const Color(0xFF94A3B8),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.videocam_off_rounded, size: 18, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Sesi Live Telah Berakhir',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _openMeetingUrl,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00584B),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.videocam_rounded, size: 18, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Masuk Sesi Live',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Investasi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                priceStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isEnded ? null : _openCheckout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEnded ? const Color(0xFF94A3B8) : const Color(0xFF00584B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                isEnded ? 'Sesi Telah Berakhir' : (price == 0 ? 'Daftar Gratis Sekarang' : 'Daftar Sesi Sekarang'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF0F172A), size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF00584B), size: 15),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}

