import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/course_remote_datasource.dart';
import '../../../../data/datasources/remote/bootcamp_remote_datasource.dart';
import '../../learn/screens/course_detail_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final _courseDs   = sl<CourseRemoteDataSource>();
  final _bootcampDs = sl<BootcampRemoteDataSource>();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filtered = [];

  final _searchCtrl = TextEditingController();
  String _typeFilter   = ''; // '' | 'bootcamp' | 'mini-course'
  String _statusFilter = ''; // '' | 'in-progress' | 'completed'
  String _fieldFilter  = ''; // '' | 'UI_UX' | 'FRONTEND' | 'BACKEND' | 'MOBILE'

  static const Map<String, String> _fieldLabels = {
    'UI_UX':    'UI/UX Design',
    'FRONTEND': 'Frontend Dev',
    'BACKEND':  'Backend Dev',
    'MOBILE':   'Mobile Dev',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _bootcampDs.getEnrolledBootcamps().catchError((_) => <dynamic>[]),
        _courseDs.getEnrolledCourses().catchError((_) => <dynamic>[]),
      ]);

      final bootcamps = results[0]
          .map((b) => {for (final en in (b as Map<String, dynamic>).entries) en.key: en.value, 'type': 'bootcamp'})
          .toList();
      final courses = results[1]
          .map((c) => {for (final en in (c as Map<String, dynamic>).entries) en.key: en.value, 'type': 'mini-course'})
          .toList();

      if (!mounted) return;
      setState(() {
        _allCourses = [...bootcamps, ...courses]
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
      _applyFilters();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allCourses.where((c) {
        final title   = (c['title'] as String? ?? '').toLowerCase();
        final type    = c['type'] as String? ?? '';
        final field   = c['field'] as String? ?? '';
        final prog    = (c['progress'] as num?)?.toDouble() ?? 0;

        if (q.isNotEmpty && !title.contains(q)) return false;
        if (_typeFilter.isNotEmpty && type != _typeFilter) return false;
        if (_fieldFilter.isNotEmpty && field != _fieldFilter) return false;
        if (_statusFilter == 'in-progress' && !(prog > 0 && prog < 100)) return false;
        if (_statusFilter == 'completed'   && prog < 100) return false;
        return true;
      }).toList();
    });
  }

  Widget _chip(String label, String val, String current, void Function(String) onTap) {
    final active = current == val;
    return GestureDetector(
      onTap: () {
        onTap(active ? '' : val);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Kursus Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // ── Search ────────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari kursus saya...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Filter chips ──────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip('Bootcamp', 'bootcamp', _typeFilter, (v) => setState(() => _typeFilter = v)),
                  const SizedBox(width: 8),
                  _chip('Mini Course', 'mini-course', _typeFilter, (v) => setState(() => _typeFilter = v)),
                  const SizedBox(width: 16),
                  _chip('Sedang Belajar', 'in-progress', _statusFilter, (v) => setState(() => _statusFilter = v)),
                  const SizedBox(width: 8),
                  _chip('Selesai', 'completed', _statusFilter, (v) => setState(() => _statusFilter = v)),
                  const SizedBox(width: 16),
                  ..._fieldLabels.entries.map((fieldEntry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _chip(fieldEntry.value.split(' ').first, fieldEntry.key, _fieldFilter, (v) => setState(() => _fieldFilter = v)),
                      )),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.border),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _MyCourseCard(course: _filtered[i], fieldLabels: _fieldLabels),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, idx) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 120,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty || _typeFilter.isNotEmpty || _statusFilter.isNotEmpty || _fieldFilter.isNotEmpty
                  ? 'Tidak ada kursus yang sesuai'
                  : 'Belum ada kursus',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isNotEmpty || _typeFilter.isNotEmpty || _statusFilter.isNotEmpty || _fieldFilter.isNotEmpty
                  ? 'Coba ubah filter atau kata kunci pencarian.'
                  : 'Mulai perjalanan belajarmu sekarang!',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (_searchCtrl.text.isNotEmpty || _typeFilter.isNotEmpty || _statusFilter.isNotEmpty || _fieldFilter.isNotEmpty) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() { _typeFilter = ''; _statusFilter = ''; _fieldFilter = ''; });
                  _applyFilters();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Reset Filter', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── My Course Card ─────────────────────────────────────────────────────────────
class _MyCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final Map<String, String> fieldLabels;

  const _MyCourseCard({required this.course, required this.fieldLabels});

  @override
  Widget build(BuildContext context) {
    final type        = course['type'] as String? ?? '';
    final title       = course['title'] as String? ?? '';
    final field       = course['field'] as String? ?? '';
    final level       = course['level'] as String? ?? '';
    final progress    = (course['progress'] as num?)?.toDouble() ?? 0;
    final thumbnail   = (course['thumbnailUrl'] ?? course['thumbnail']) as String?;
    final isBootcamp  = type == 'bootcamp';
    final isCompleted = progress >= 100;
    final startDate   = course['startDate'] as String?;
    final notStarted  = isBootcamp && startDate != null && DateTime.tryParse(startDate)?.isAfter(DateTime.now()) == true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Thumbnail
          Stack(
            children: [
              Container(
                width: 110,
                height: 120,
                color: AppColors.backgroundSubtle,
                alignment: Alignment.center,
                child: thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: thumbnail,
                        width: 110,
                        height: 120,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, err, stack) => const Icon(Icons.book_outlined, size: 32, color: AppColors.textTertiary),
                      )
                    : const Icon(Icons.book_outlined, size: 32, color: AppColors.textTertiary),
              ),
              // Type badge
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isBootcamp ? AppColors.primary : const Color(0xFF334155),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    isBootcamp ? 'BOOTCAMP' : 'MINI COURSE',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field · Level
                  Row(
                    children: [
                      Text(
                        fieldLabels[field] ?? field,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      if (level.isNotEmpty) ...[
                        Text(' • ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                        Text(
                          _levelLabel(level),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progress', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                          Text(
                            isCompleted ? 'Selesai ✓' : '${progress.toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCompleted ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.backgroundSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Actions
                  Row(
                    children: [
                      _ActionBtn(
                        label: 'Detail',
                        outlined: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                item: {
                                  ...course,
                                  'isBootcamp': isBootcamp,
                                  'isEnrolled': true,
                                },
                                isBootcamp: isBootcamp,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: notStarted
                            ? 'Mulai Belajar ▶'
                            : (progress > 0 ? 'Lanjut ▶' : 'Mulai ▶'),
                        outlined: false,
                        disabled: false,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                item: {
                                  ...course,
                                  'isBootcamp': isBootcamp,
                                  'isEnrolled': true,
                                },
                                isBootcamp: isBootcamp,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _levelLabel(String level) {
    const labels = {
      'BEGINNER':     'Pemula',
      'ELEMENTARY':   'Dasar',
      'INTERMEDIATE': 'Menengah',
      'ADVANCED':     'Mahir',
    };
    return labels[level] ?? level;
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool outlined;
  final bool disabled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.outlined,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.backgroundSubtle
              : outlined
                  ? AppColors.surface
                  : AppColors.primary,
          border: Border.all(
            color: disabled
                ? AppColors.border
                : outlined
                    ? AppColors.border
                    : AppColors.primary,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: disabled
                ? AppColors.textTertiary
                : outlined
                    ? AppColors.textPrimary
                    : Colors.white,
          ),
        ),
      ),
    );
  }
}
