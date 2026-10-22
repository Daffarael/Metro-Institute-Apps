import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/skill_test_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';

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

  // Mode: 'TEST' or 'RESULT'
  String _mode = 'TEST';

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
        _mode = 'TEST';
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
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lihat Hasil Rekomendasi', style: TextStyle(fontWeight: FontWeight.w700)),
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
        title: Text(
          _mode == 'RESULT' ? 'Hasil Tes Bakat & Minat' : 'Tes Bakat & Minat',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.basecamp);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : _mode == 'RESULT'
                  ? _buildResultView()
                  : _buildQuestionnaireView(),
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
            ElevatedButton(
              onPressed: _checkStatusAndLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Coba Lagi'),
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
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sebelumnya', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _currentIndex < _questions.length - 1 ? 'Selanjutnya' : 'Selesaikan & Kirim',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
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
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.learn),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1117),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_rounded, size: 20),
                SizedBox(width: 8),
                Text('Eksplorasi Kelas Sesuai Rekomendasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.basecamp),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Kembali ke Basecamp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
