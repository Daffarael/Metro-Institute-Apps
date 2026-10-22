import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/webinar_remote_datasource.dart';
import '../../learn/widgets/checkout_bottom_sheet.dart';

class WebinarScreen extends StatefulWidget {
  const WebinarScreen({super.key});

  @override
  State<WebinarScreen> createState() => _WebinarScreenState();
}

class _WebinarScreenState extends State<WebinarScreen>
    with SingleTickerProviderStateMixin {
  final _ds = sl<WebinarRemoteDataSource>();
  late TabController _tabController;

  bool _isLoadingAll  = true;
  bool _isLoadingMy   = true;
  List<dynamic> _allWebinars = [];
  List<dynamic> _myWebinars  = [];
  String _scheduleFilter = ''; // '' | 'UPCOMING' | 'PAST'
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _loadAll();
    _loadMy();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoadingAll = true);
    try {
      final data = await _ds.getWebinars(status: _scheduleFilter.isEmpty ? null : _scheduleFilter);
      if (!mounted) return;
      setState(() { _allWebinars = data; _isLoadingAll = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingAll = false);
    }
  }

  Future<void> _loadMy() async {
    setState(() => _isLoadingMy = true);
    try {
      final data = await _ds.getMyWebinars();
      if (!mounted) return;
      setState(() { _myWebinars = data; _isLoadingMy = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMy = false);
    }
  }

  List<dynamic> get _filteredAll {
    return _allWebinars.where((w) {
      final title   = (w['title'] as String? ?? '').toLowerCase();
      final speaker = (w['speakerName'] as String? ?? '').toLowerCase();
      return _searchQuery.isEmpty || title.contains(_searchQuery) || speaker.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: NestedScrollView(
        headerSliverBuilder: (_, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFFAF9F5),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF0F172A),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFFAF9F5),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Webinar & Workshop',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sesi live interaktif bersama pakar industri',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  tabs: [
                    const Tab(text: 'Jelajahi Webinar'),
                    Tab(text: 'Webinar Saya (${_myWebinars.length})'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: All Webinars ────────────────────────────────────────
            _AllWebinarsTab(
              webinars: _filteredAll,
              isLoading: _isLoadingAll,
              searchCtrl: _searchCtrl,
              scheduleFilter: _scheduleFilter,
              onScheduleChanged: (val) {
                setState(() => _scheduleFilter = val);
                _loadAll();
              },
              onRefresh: _loadAll,
            ),

            // ── Tab 2: My Webinars ─────────────────────────────────────────
            _MyWebinarsTab(
              webinars: _myWebinars,
              isLoading: _isLoadingMy,
              onRefresh: _loadMy,
              onExplore: () => _tabController.animateTo(0),
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Webinars Tab ─────────────────────────────────────────────────────────
class _AllWebinarsTab extends StatelessWidget {
  final List<dynamic> webinars;
  final bool isLoading;
  final TextEditingController searchCtrl;
  final String scheduleFilter;
  final void Function(String) onScheduleChanged;
  final Future<void> Function() onRefresh;

  const _AllWebinarsTab({
    required this.webinars,
    required this.isLoading,
    required this.searchCtrl,
    required this.scheduleFilter,
    required this.onScheduleChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + Filter with crisp borders (Reference Image style)
        Container(
          color: const Color(0xFFFAF9F5),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Cari webinar atau pembicara...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0F172A)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ScheduleChip(label: 'Semua', value: '', current: scheduleFilter, onTap: onScheduleChanged),
                    const SizedBox(width: 8),
                    _ScheduleChip(label: 'Akan Datang', value: 'UPCOMING', current: scheduleFilter, onTap: onScheduleChanged),
                    const SizedBox(width: 8),
                    _ScheduleChip(label: 'Selesai', value: 'PAST', current: scheduleFilter, onTap: onScheduleChanged),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: isLoading
              ? _buildSkeleton()
              : webinars.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: webinars.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _WebinarCard(webinar: webinars[i], onPaymentSuccess: onRefresh),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, idx) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_outlined, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 14),
              Text(
                'Tidak ada webinar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coba ubah kata kunci pencarian atau filter jadwal.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My Webinars Tab ──────────────────────────────────────────────────────────
class _MyWebinarsTab extends StatelessWidget {
  final List<dynamic> webinars;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onExplore;

  const _MyWebinarsTab({
    required this.webinars,
    required this.isLoading,
    required this.onRefresh,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (webinars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9EE),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_seat_outlined, size: 48, color: Color(0xFF0F172A)),
                const SizedBox(height: 14),
                Text(
                  'Belum ada webinar terdaftar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kamu belum mendaftar ke webinar manapun. Jelajahi sesi webinar mendatang dan daftar sekarang!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Material(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onExplore,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      child: Text(
                        'Cari Webinar',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: webinars.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _WebinarCard(webinar: webinars[i], onPaymentSuccess: onRefresh),
        ),
      ),
    );
  }
}

// ── Schedule Filter Chip ─────────────────────────────────────────────────────
class _ScheduleChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;

  const _ScheduleChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? const Color(0xFF0F172A) : Colors.white,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x080F172A),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

// ── Webinar Card (Reference Image: Squircle with Dark Border & Dark Pill CTA) ──
class _WebinarCard extends StatelessWidget {
  final dynamic webinar;
  final VoidCallback? onPaymentSuccess;

  const _WebinarCard({
    required this.webinar,
    this.onPaymentSuccess,
  });

  bool get _isEnded {
    final isEnded = webinar['isEnded'] as bool? ?? false;
    if (isEnded) return true;
    final scheduled = webinar['scheduledAt'] as String?;
    if (scheduled == null) return false;
    return DateTime.tryParse(scheduled)
            ?.add(const Duration(hours: 24))
            .isBefore(DateTime.now()) ??
        false;
  }

  String _formatRupiah(dynamic price) {
    final n = (price as num?)?.toInt() ?? 0;
    if (n == 0) return 'Gratis';
    final str = n.toString();
    final buf = StringBuffer('Rp ');
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(str[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String get _ctaLabel {
    if (_isEnded) return 'Lihat Detail Sesi';
    final isRegistered = webinar['isRegistered'] as bool? ?? false;
    if (isRegistered) return 'Akses Sesi ›';
    final price = (webinar['price'] as num?)?.toInt() ?? 0;
    if (price == 0) return 'Daftar Gratis ›';
    return 'Beli Tiket (${_formatRupiah(price)})';
  }

  Future<void> _openMeetingUrl() async {
    final url = webinar['meetingUrl'] as String? ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleCta(BuildContext context) {
    if (_isEnded) return;
    final isRegistered = webinar['isRegistered'] as bool? ?? false;
    if (isRegistered) {
      _openMeetingUrl();
      return;
    }

    final title = webinar['title'] as String? ?? 'Webinar';
    final price = (webinar['price'] as num?)?.toInt() ?? 0;
    final id = webinar['id']?.toString() ?? '';
    final bannerUrl = webinar['bannerUrl'] as String?;
    final speakerName = webinar['speakerName'] as String?;

    CheckoutBottomSheet.show(
      context,
      title: title,
      price: price,
      productType: 'WEBINAR',
      productId: id,
      thumbnailUrl: bannerUrl,
      subtitle: speakerName != null ? 'Pembicara: $speakerName' : null,
      onSuccess: onPaymentSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title        = webinar['title'] as String? ?? '';
    final description  = (webinar['shortDescription'] ?? webinar['description']) as String? ?? '';
    final speakerName  = webinar['speakerName'] as String? ?? 'Pembicara';
    final speakerRole  = webinar['speakerRole'] as String?;
    final speakerAvatar= webinar['speakerAvatarUrl'] as String?;
    final bannerUrl    = webinar['bannerUrl'] as String?;
    final scheduledAt  = webinar['scheduledAt'] as String?;
    final duration     = (webinar['duration'] as num?)?.toInt() ?? 0;
    final price        = (webinar['price'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner / Thumbnail
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: bannerUrl != null && bannerUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: bannerUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                        errorWidget: (context, url, error) => _bannerPlaceholder(),
                      )
                    : _bannerPlaceholder(),
              ),

              // Price badge (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: price == 0 ? AppColors.primary : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    price == 0 ? 'Gratis' : _formatRupiah(price),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Status badge (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isEnded ? const Color(0xFF64748B) : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isEnded ? 'Selesai' : 'Live',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 14),

                // Speaker Info Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: (speakerAvatar != null && speakerAvatar.isNotEmpty)
                          ? NetworkImage(speakerAvatar)
                          : null,
                      child: (speakerAvatar == null || speakerAvatar.isEmpty)
                          ? Text(
                              speakerName.isNotEmpty ? speakerName[0].toUpperCase() : 'S',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: const Color(0xFF0F172A),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            speakerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (speakerRole != null && speakerRole.isNotEmpty)
                            Text(
                              speakerRole,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Schedule & Duration Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F5F9)),
                      bottom: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(scheduledAt),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Text(
                            '${duration}m',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // CTA (Dark squircle pill button - Reference Image: "Book lesson")
                Material(
                  color: _isEnded ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => _handleCta(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: _isEnded ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                      ),
                      child: Text(
                        _ctaLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _isEnded ? const Color(0xFF94A3B8) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.videocam_rounded, size: 36, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          'Live Workshop',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
