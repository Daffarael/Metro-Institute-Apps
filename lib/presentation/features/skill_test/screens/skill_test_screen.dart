import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/skill_test_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../common/widgets/splash_screen.dart';
import '../../../common/widgets/tactile_metro_button.dart';

class SkillTestScreen extends StatefulWidget {
  const SkillTestScreen({super.key});

  @override
  State<SkillTestScreen> createState() => _SkillTestScreenState();
}

class _SkillTestScreenState extends State<SkillTestScreen> {
  final SkillTestRemoteDataSource _skillTestDataSource = sl<SkillTestRemoteDataSource>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  bool _isLoading = true;
  String? _errorMessage;

  // Mode: 'INTRO', 'TEST', or 'RESULT'
  String _mode = 'INTRO';

  // Questions data
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // questionId -> optionId
  bool _isSubmitting = false;

  // Result data
  Map<String, dynamic>? _resultData;

  @override
  void initState() {
    super.initState();
    _checkStatusAndLoad();
  }

  Future<void> _checkStatusAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepo.getSavedUser();
      if (user?.skillTestDone == true) {
        // Fetch existing result
        try {
          final res = await _skillTestDataSource.getResult();
          if (!mounted) return;
          setState(() {
            _mode = 'RESULT';
            _resultData = res;
            _isLoading = false;
          });
          return;
        } catch (_) {
          // If fetching result fails, fallback to loading questions
        }
      }

      // Load questions
      final questions = await _skillTestDataSource.getQuestions();
      if (!mounted) return;
      setState(() {
        _mode = 'INTRO';
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap jawab semua pertanyaan sebelum mengirim.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final res = await _skillTestDataSource.submitAnswers(_answers);
      await _authRepo.refreshProfile();

      if (!mounted) return;
      setState(() {
        _resultData = res;
        _mode = 'RESULT';
        _isSubmitting = false;
      });

      _showSuccessDialog(res['xpEarned'] ?? 50);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showSuccessDialog(dynamic xp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.xpBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: AppColors.xp, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tes Minat Selesai!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Selamat! Anda mendapatkan +$xp XP dan rekomendasi jalur belajar yang telah dipersonalisasi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            TactileMetroButton.primary(
              onPressed: () => Navigator.pop(ctx),
              height: 48,
              fontSize: 14.5,
              borderRadius: BorderRadius.circular(14),
              text: 'Lihat Hasil Rekomendasi',
            ),
          ],
        ),
      ),
    );
  }

  String _formatFieldName(String? raw) {
    if (raw == null) return 'Digital Specialist';
    switch (raw.toUpperCase()) {
      case 'UI_UX':
      case 'UI/UX':
        return 'UI/UX & Product Design';
      case 'FRONTEND':
        return 'Frontend Web Development';
      case 'BACKEND':
        return 'Backend Engineering';
      case 'MOBILE':
        return 'Mobile App Development';
      case 'DATA_SCIENCE':
        return 'Data Science & Analytics';
      case 'AI_ML':
        return 'Artificial Intelligence';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          _mode == 'RESULT'
              ? 'Hasil Tes Bakat & Minat'
              : _mode == 'INTRO'
                  ? 'Skill Test Awal'
                  : 'Tes Bakat & Minat',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  if (_mode == 'TEST') {
                    setState(() {
                      _mode = 'INTRO';
                    });
                  } else {
                    context.pop();
                  }
                },
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : _mode == 'RESULT'
                  ? _buildResultView()
                  : _mode == 'INTRO'
                      ? _buildIntroView()
                      : _buildQuestionnaireView(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INTRO VIEW (Skill Test Awal - Locked to Viewport, No Scroll, Metro Green & Yellow)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildIntroView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),

            // Metro Institute Logo Resmi (Sesuai Card Login Web Beserta Tulisannya)
            Center(
              child: Image.asset(
                'assets/images/logo_metro_clean.png',
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/logo_metro_color.png',
                  height: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Subtitle
            const Text(
              'Sebelum mulai, kami ingin mengetahui kemampuanmu saat ini. Hasil tes ini membantu kami menentukan jalur belajar yang paling sesuai untukmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),

            const Spacer(flex: 3),

            // ── 4 KARTU INFO (Grid 2x2 Sejajar & Rapi - Hijau & Kuning Metro) ──
            // Baris 1: Jumlah Soal (Hijau) & Waktu per Soal (Kuning)
            Row(
              children: [
                Expanded(
                  child: _buildIntroCard(
                    label: 'JUMLAH SOAL',
                    value: '${_questions.isNotEmpty ? _questions.length : 12} Pertanyaan',
                    icon: Icons.assignment_outlined,
                    cardBg: AppColors.primary, // Hijau Metro (#018556)
                    badgeBg: AppColors.accent,  // Kuning Metro (#FAE653)
                    iconColor: AppColors.primary,
                    textColor: Colors.white,
                    labelColor: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIntroCard(
                    label: 'WAKTU PER SOAL',
                    value: '30 Detik',
                    icon: Icons.timer_outlined,
                    cardBg: AppColors.accent,  // Kuning Metro (#FAE653)
                    badgeBg: AppColors.primary, // Hijau Metro (#018556)
                    iconColor: Colors.white,
                    textColor: AppColors.textPrimary,
                    labelColor: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Baris 2: Tipe Soal (Kuning) & Tujuan (Hijau)
            Row(
              children: [
                Expanded(
                  child: _buildIntroCard(
                    label: 'TIPE SOAL',
                    value: 'Pilihan Ganda',
                    icon: Icons.check_box_outlined,
                    cardBg: AppColors.accent,  // Kuning Metro (#FAE653)
                    badgeBg: AppColors.primary, // Hijau Metro (#018556)
                    iconColor: Colors.white,
                    textColor: AppColors.textPrimary,
                    labelColor: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIntroCard(
                    label: 'TUJUAN',
                    value: 'Personalisasi Belajar',
                    icon: Icons.track_changes_rounded,
                    cardBg: AppColors.primary, // Hijau Metro (#018556)
                    badgeBg: AppColors.accent,  // Kuning Metro (#FAE653)
                    iconColor: AppColors.primary,
                    textColor: Colors.white,
                    labelColor: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 3),

            // Tips Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Tips: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          TextSpan(
                            text: 'Jawab dengan jujur sesuai kemampuanmu sekarang. Tidak ada nilai benar atau salah.',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Tombol Mulai Test dengan Animasi Blinking Chevrons (>>>) & Scale Press Khas Mobile Metro
            _MetroAnimatedCtaButton(
              onTap: () {
                setState(() {
                  _mode = 'TEST';
                  _currentIndex = 0;
                });
              },
              text: 'Mulai Test',
              height: 50,
              fontSize: 16,
              borderRadius: BorderRadius.circular(16),
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard({
    required String label,
    required String value,
    required IconData icon,
    required Color cardBg,
    required Color badgeBg,
    required Color iconColor,
    required Color textColor,
    required Color labelColor,
  }) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBg == AppColors.primary ? Colors.transparent : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, size: 54, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TactileMetroButton.primary(
              onPressed: _checkStatusAndLoad,
              height: 44,
              fontSize: 14,
              borderRadius: BorderRadius.circular(12),
              text: 'Coba Lagi',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireView() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Belum ada pertanyaan tes yang aktif.'));
    }

    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final qId = q['id'].toString();
    final questionText = q['question'] ?? '';
    final options = (q['options'] as List<dynamic>?) ?? [];
    final selectedOption = _answers[qId];

    return Column(
      children: [
        // Top Progress Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pertanyaan ${_currentIndex + 1} dari ${_questions.length}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${(((_currentIndex + 1) / _questions.length) * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // Question & Options Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question Card (Squircle)
                // Question Card (Squircle Clean - No Shadow)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Options List (Clean - No Shadow)
                ...options.map((opt) {
                  final optMap = opt as Map<String, dynamic>;
                  final optId = optMap['id']?.toString() ?? '';
                  final optText = optMap['text'] ?? optMap['label'] ?? '';
                  final isSelected = selectedOption == optId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _answers[qId] = optId;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.6 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                optText.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigation Footer (Clean Flat Buttons - No Shadow, No Overflow)
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_currentIndex > 0) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sebelumnya',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: _currentIndex > 0 ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: (selectedOption == null || _isSubmitting)
                        ? null
                        : () {
                            if (_currentIndex < _questions.length - 1) {
                              setState(() {
                                _currentIndex++;
                              });
                            } else {
                              _handleSubmit();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF018556),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF64748B),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Text(
                            _currentIndex < _questions.length - 1 ? 'Selanjutnya' : 'Selesaikan & Kirim',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: selectedOption == null ? const Color(0xFF64748B) : Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getFieldDescription(String? raw) {
    if (raw == null) return 'Temukan potensimu di dunia teknologi bersama Metro Institute.';
    final key = raw.toUpperCase().replaceAll('/', '_').replaceAll('-', '_');
    if (key.contains('UI') || key.contains('UX')) {
      return 'Kamu memiliki insting visual dan empati yang baik terhadap pengguna. Karir yang ideal: Product Designer, UX Researcher, atau UI Engineer.';
    }
    if (key.contains('FRONTEND')) {
      return 'Kamu memiliki logika terstruktur dan ketertarikan pada interaksi visual. Kuasai React & Next.js untuk membangun antarmuka web modern.';
    }
    if (key.contains('BACKEND')) {
      return 'Pemikiran sistematis adalah kekuatanmu. Bangun fondasi aplikasi yang kokoh, arsitektur data yang skalabel, dan API berkinerja tinggi.';
    }
    if (key.contains('MOBILE')) {
      return 'Kamu tertarik pada produk yang digunakan langsung di genggaman. Pelajari pengembangan aplikasi native atau cross-platform (Flutter/React Native).';
    }
    return 'Hasil analisismu menunjukkan kecocokan pada bidang keahlian ini. Eksplorasi sekarang untuk memperdalam potensimu.';
  }

  Widget _buildResultView() {
    final res = _resultData ?? {};
    final topField = res['topField'] ?? res['recommendation'] ?? 'FRONTEND';
    final scores = (res['scores'] as Map<String, dynamic>?) ?? {};
    final xpEarned = res['xpEarned'] ?? 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero Recommendation Card (Hijau & Kuning Metro) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            decoration: BoxDecoration(
              color: const Color(0xFF018556), // Solid Hijau Metro (No Gradient, No Shadow)
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Top circular badge in Kuning Metro
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAE653), // Kuning Metro solid
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Color(0xFF018556), // Hijau Metro
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),

                // Label Hasil Analisis (matching Web)
                const Text(
                  'HASIL ANALISIS',
                  style: TextStyle(
                    color: Color(0xFFFAE653), // Kuning Metro
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Field Title (matching Web)
                Text(
                  _formatFieldName(topField.toString()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Field Description (Exact Web Text from FIELD_DESCRIPTIONS!)
                Text(
                  _getFieldDescription(topField.toString()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Score Breakdown per Field (Kesesuaian Minat & Bakat - Clean Flat) ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kesesuaian Minat & Bakat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1117),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Persentase kecocokan Anda dengan bidang keahlian digital.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                if (scores.isEmpty)
                  _scoreRow('Kesesuaian Jalur', 95, isTop: true)
                else
                  ...scores.entries.map((e) {
                    final fieldName = _formatFieldName(e.key);
                    final scoreVal = (e.value as num).toInt();
                    final isTop = e.key.toUpperCase() == topField.toString().toUpperCase();
                    return _scoreRow(fieldName, scoreVal, isTop: isTop);
                  }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action Button: Eksplorasi Sekarang (Solid Hijau Metro - Clean Flat) ──
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.learn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF018556),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_rounded, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Eksplorasi Sekarang',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // XP Earned note below button
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, size: 16, color: Color(0xFF018556)),
                const SizedBox(width: 5),
                Text(
                  '+$xpEarned XP diperoleh dari test ini',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          // Secondary Action: Kembali ke Basecamp (Clean Outline Button)
          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.basecamp);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Kembali ke Basecamp',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, int percentage, {bool isTop = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isTop ? FontWeight.w700 : FontWeight.w600,
                    color: const Color(0xFF0D1117),
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isTop ? const Color(0xFF018556) : const Color(0xFF063D2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              color: isTop ? const Color(0xFF018556) : const Color(0xFFFAE653),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated Metro CTA Button matching the onboarding/splash screen animation:
/// • Continuous sequential travelling wave animation on trailing chevrons (>>>)
/// • Smooth tactile scale compression on press (1.0 -> 0.96)
/// • Crisp haptic feedback on tap
/// • Signature Metro Green (#018556) with 3D base shadow
class _MetroAnimatedCtaButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;
  final double height;
  final double fontSize;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final bool isLoading;
  final bool isDisabled;
  final bool showArrow;

  const _MetroAnimatedCtaButton({
    required this.onTap,
    this.text = 'Mulai Test',
    this.height = 50,
    this.fontSize = 16,
    this.borderRadius,
    this.backgroundColor = AppColors.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.showArrow = false,
  });

  @override
  State<_MetroAnimatedCtaButton> createState() => _MetroAnimatedCtaButtonState();
}

class _MetroAnimatedCtaButtonState extends State<_MetroAnimatedCtaButton>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _pulseController;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _getChevronOpacity(double t, int index) {
    final start = index * 0.16;
    final end = start + 0.38;
    if (t >= start && t <= end) {
      final p = (t - start) / (end - start);
      final sine = math.sin(p * math.pi);
      return 0.25 + 0.75 * sine;
    }
    return 0.25;
  }

  void _handleTap() async {
    if (widget.isDisabled || widget.isLoading || widget.onTap == null) return;
    if (_isTapped) return;
    _isTapped = true;
    HapticFeedback.lightImpact();
    await _animController.forward();
    await _animController.reverse();
    await Future.delayed(const Duration(milliseconds: 70));
    if (mounted) {
      widget.onTap?.call();
    }
    _isTapped = false;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final bool canPress = !widget.isDisabled && !widget.isLoading && widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: canPress ? (_) => _animController.forward() : null,
      onTapUp: canPress ? (_) => _animController.reverse() : null,
      onTapCancel: canPress ? () => _animController.reverse() : null,
      onTap: canPress ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          alignment: Alignment.center,
          child: child,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: widget.isDisabled ? 0.5 : 1.0,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: radius,
            ),
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    ),
                  )
                : Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.text,
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        if (widget.showArrow) ...[
                          const SizedBox(width: 10),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              final t = _pulseController.value;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12.5,
                                    color: Colors.white.withValues(
                                      alpha: _getChevronOpacity(t, 0),
                                    ),
                                  ),
                                  const SizedBox(width: 2.5),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12.5,
                                    color: Colors.white.withValues(
                                      alpha: _getChevronOpacity(t, 1),
                                    ),
                                  ),
                                  const SizedBox(width: 2.5),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12.5,
                                    color: Colors.white.withValues(
                                      alpha: _getChevronOpacity(t, 2),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
