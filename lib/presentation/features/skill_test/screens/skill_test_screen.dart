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

            // Title
            const Text(
              'Skill Test Awal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle
            const Text(
              'Sebelum mulai, kami ingin mengetahui kemampuanmu saat ini. Hasil tes ini membantu kami menentukan jalur belajar yang paling sesuai untukmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.4,
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

            // Tombol Mulai Test (Animasi 3D Tactile Push-Down Khas Mobile Metro)
            TactileMetroButton.primary(
              onPressed: () {
                setState(() {
                  _mode = 'TEST';
                  _currentIndex = 0;
                });
              },
              height: 50,
              fontSize: 16,
              borderRadius: BorderRadius.circular(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mulai Test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                ],
              ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
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
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 18,
                        offset: Offset(0, 5),
                      ),
                    ],
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

                // Options List
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
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.6 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : const Color(0x05000000),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
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

        // Navigation Footer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: TactileMetroButton.secondary(
                    onPressed: () {
                      setState(() {
                        _currentIndex--;
                      });
                    },
                    height: 48,
                    fontSize: 13.5,
                    borderRadius: BorderRadius.circular(14),
                    text: 'Sebelumnya',
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TactileMetroButton.primary(
                  onPressed: selectedOption == null
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
                  isDisabled: selectedOption == null,
                  isLoading: _isSubmitting,
                  height: 48,
                  fontSize: 14,
                  borderRadius: BorderRadius.circular(14),
                  text: _currentIndex < _questions.length - 1 ? 'Selanjutnya' : 'Selesaikan & Kirim',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final res = _resultData ?? {};
    final topField = res['topField'] ?? res['recommendation'] ?? 'FRONTEND';
    final scores = (res['scores'] as Map<String, dynamic>?) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recommendation Hero Card (Luxury Dark Squircle)
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13171F), Color(0xFF1A222D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF28313E), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rekomendasi Jalur Karir Anda',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatFieldName(topField.toString()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Pilihan Paling Cocok (Best Fit)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Score Breakdown per Field (Squircle)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kesesuaian Minat & Bakat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Persentase kecocokan Anda dengan bidang keahlian digital.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                if (scores.isEmpty)
                  _scoreRow('Kesesuaian Jalur', 95)
                else
                  ...scores.entries.map((e) {
                    final fieldName = _formatFieldName(e.key);
                    final scoreVal = (e.value as num).toInt();
                    return _scoreRow(fieldName, scoreVal);
                  }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Button: Go to Learning
          TactileMetroButton.dark(
            onPressed: () => context.go(AppRoutes.learn),
            height: 52,
            borderRadius: BorderRadius.circular(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_rounded, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text('Eksplorasi Kelas Sesuai Rekomendasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TactileMetroButton.secondary(
            onPressed: () => context.go(AppRoutes.basecamp),
            height: 48,
            borderRadius: BorderRadius.circular(16),
            text: 'Kembali ke Basecamp',
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, int percentage) {
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              color: percentage >= 70 ? AppColors.primary : AppColors.warning,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
