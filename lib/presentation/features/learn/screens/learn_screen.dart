import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import 'video_player_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _courseDs = sl<CourseRemoteDataSource>();

  bool _isLoadingAll = true;
  bool _isLoadingEnrolled = true;
  List<dynamic> _allCourses = [];
  List<dynamic> _enrolledCourses = [];
  String? _selectedField;

  final List<String> _fields = ['ALL', 'UI_UX', 'FRONTEND', 'BACKEND', 'MOBILE'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
    _loadEnrolled();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoadingAll = true);
    try {
      final list = await _courseDs.getCourses(field: _selectedField);
      if (!mounted) return;
      setState(() {
        _allCourses = list;
        _isLoadingAll = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingAll = false);
    }
  }

  Future<void> _loadEnrolled() async {
    setState(() => _isLoadingEnrolled = true);
    try {
      final list = await _courseDs.getEnrolledCourses();
      if (!mounted) return;
      setState(() {
        _enrolledCourses = list;
        _isLoadingEnrolled = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingEnrolled = false);
    }
  }

  void _openCourseDetail(Map<String, dynamic> course) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CourseDetailSheet(
        course: course,
        onWatchSession: (session, courseTitle) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                title: session['title'] ?? 'Materi Video',
                courseTitle: courseTitle,
                videoUrl: session['videoUrl'] as String?,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Ruang Belajar Mentee 🎓',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Kelas Saya'),
            Tab(text: 'Katalog Kursus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Kelas Saya ──────────────────────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadEnrolled,
            child: _isLoadingEnrolled
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _enrolledCourses.isEmpty
                    ? _emptyState(
                        title: 'Belum ada kelas yang diikuti',
                        subtitle: 'Yuk pilih kursus atau bootcamp digital impianmu di tab Katalog!',
                        buttonText: 'Buka Katalog Kursus',
                        onAction: () => _tabController.animateTo(1),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _enrolledCourses.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final item = _enrolledCourses[i];
                          final course = item['course'] as Map<String, dynamic>? ?? {};
                          final progress = ((item['progress'] as num?)?.toDouble() ?? 0.0) / 100;

                          return _enrolledCard(course, progress);
                        },
                      ),
          ),

          // ── Tab 2: Katalog Kursus ──────────────────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadAll,
            child: Column(
              children: [
                // Field Filter Chips
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: _fields.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _fields[i];
                      final isSelected = (_selectedField == null && f == 'ALL') || _selectedField == f;
                      final label = f == 'ALL' ? 'Semua' : f.replaceAll('_', '/');

                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedField = (f == 'ALL') ? null : f;
                          });
                          _loadAll();
                        },
                      );
                    },
                  ),
                ),

                // Course List
                Expanded(
                  child: _isLoadingAll
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _allCourses.isEmpty
                          ? _emptyState(
                              title: 'Tidak ada kursus ditemukan',
                              subtitle: 'Coba ubah filter kategori ke Semua.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _allCourses.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 14),
                              itemBuilder: (context, i) {
                                final course = _allCourses[i] as Map<String, dynamic>;
                                return _catalogCard(course);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enrolledCard(Map<String, dynamic> course, double progress) {
    final title = course['title'] as String? ?? 'Kelas Metro';
    final field = (course['field'] as String? ?? 'DIGITAL').replaceAll('_', ' ');

    return GestureDetector(
      onTap: () => _openCourseDetail(course),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                  child: Text(field, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text('${(progress * 100).toInt()}% Selesai', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text('Lanjutkan Modul', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogCard(Map<String, dynamic> course) {
    final title = course['title'] as String? ?? 'Kursus Digital';
    final shortDesc = course['shortDescription'] as String? ?? '';
    final price = (course['price'] as num?)?.toInt() ?? 0;
    final rating = (course['rating'] as num?)?.toDouble() ?? 5.0;
    final priceStr = price == 0 ? 'GRATIS' : 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return GestureDetector(
      onTap: () => _openCourseDetail(course),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(priceStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: price == 0 ? AppColors.primary : AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (shortDesc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(shortDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Akses Penuh + E-Sertifikat', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                Text('Lihat Silabus >', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({required String title, required String subtitle, String? buttonText, VoidCallback? onAction}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Course Detail Bottom Sheet with Sessions ─────────────────────────────────

class _CourseDetailSheet extends StatefulWidget {
  final Map<String, dynamic> course;
  final Function(Map<String, dynamic> session, String courseTitle) onWatchSession;

  const _CourseDetailSheet({required this.course, required this.onWatchSession});

  @override
  State<_CourseDetailSheet> createState() => _CourseDetailSheetState();
}

class _CourseDetailSheetState extends State<_CourseDetailSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final courseId = widget.course['id'] as String;
      final ds = sl<CourseRemoteDataSource>();
      final res = await ds.getCourseDetail(courseId);
      if (mounted) {
        setState(() {
          _detail = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course['title'] as String? ?? 'Detail Kursus';
    final chapters = (_detail?['chapters'] as List?) ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 2),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : chapters.isEmpty
                    ? const Center(child: Text('Belum ada modul silabus.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: chapters.length,
                        itemBuilder: (context, i) {
                          final ch = chapters[i] as Map<String, dynamic>;
                          final chTitle = ch['title'] as String? ?? 'Chapter ${i + 1}';
                          final sessions = (ch['sessions'] as List?) ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: i == 0,
                              title: Text(chTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              children: sessions.map((s) {
                                final session = s as Map<String, dynamic>;
                                final sTitle = session['title'] as String? ?? 'Sesi';
                                final duration = session['videoDuration'] != null ? '${(session['videoDuration'] / 60).round()} mnt' : '';

                                return ListTile(
                                  leading: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary),
                                  title: Text(sTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  trailing: Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                  onTap: () => widget.onWatchSession(session, title),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
