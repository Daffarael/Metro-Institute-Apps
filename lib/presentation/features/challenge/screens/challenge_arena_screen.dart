import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/challenge_remote_datasource.dart';

class ChallengeArenaScreen extends StatefulWidget {
  final String challengeId;
  final String title;
  final int timeLimitMinutes;
  final int xpReward;

  const ChallengeArenaScreen({
    super.key,
    required this.challengeId,
    required this.title,
    this.timeLimitMinutes = 15,
    this.xpReward = 100,
  });

  @override
  State<ChallengeArenaScreen> createState() => _ChallengeArenaScreenState();
}

class _ChallengeArenaScreenState extends State<ChallengeArenaScreen> {
  final _challengeDs = sl<ChallengeRemoteDataSource>();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<int, dynamic> _selectedAnswers = {}; // questionIndex -> optionId
  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeLimitMinutes * 60;
    _loadChallenge();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _submitChallenge();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _challengeDs.getChallengeDetail(widget.challengeId);
      final rawQuestions = detail['questions'];
      List<dynamic> qList = [];
      if (rawQuestions is List) {
        qList = rawQuestions;
      } else if (rawQuestions is String) {
        // Fallback or empty
        qList = [];
      }

      if (qList.isEmpty) {
        // Generate placeholder demo questions if empty
        qList = [
          {
            'id': 'q1',
            'question': 'Apa tujuan utama dari prinsip Clean Architecture dalam pengembangan aplikasi?',
            'options': [
              {'id': 'a', 'text': 'Memisahkan concern bisnis dari UI dan framework', 'isCorrect': true},
              {'id': 'b', 'text': 'Membuat ukuran APK sekecil mungkin', 'isCorrect': false},
              {'id': 'c', 'text': 'Menghindari penggunaan database lokal', 'isCorrect': false},
              {'id': 'd', 'text': 'Mempercepat waktu build hingga 100%', 'isCorrect': false},
            ]
          },
          {
            'id': 'q2',
            'question': 'Manakah HTTP Status Code yang tepat untuk menandakan autentikasi berhasil dibuat?',
            'options': [
              {'id': 'a', 'text': '200 OK', 'isCorrect': false},
              {'id': 'b', 'text': '201 Created', 'isCorrect': true},
              {'id': 'c', 'text': '204 No Content', 'isCorrect': false},
              {'id': 'd', 'text': '401 Unauthorized', 'isCorrect': false},
            ]
          },
          {
            'id': 'q3',
            'question': 'Dalam Flutter, widget manakah yang cocok untuk menampilkan list data dinamis dalam jumlah besar secara efisien?',
            'options': [
              {'id': 'a', 'text': 'SingleChildScrollView + Column', 'isCorrect': false},
              {'id': 'b', 'text': 'ListView.builder', 'isCorrect': true},
              {'id': 'c', 'text': 'Wrap', 'isCorrect': false},
              {'id': 'd', 'text': 'Stack', 'isCorrect': false},
            ]
          },
        ];
      }

      if (!mounted) return;
      setState(() {
        _questions = qList;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _submitChallenge() async {
    _timer?.cancel();
    if (_isSubmitted) return;
    _isSubmitted = true;

    // Calculate score
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final opts = (q['options'] as List?) ?? [];
      final correctOpt = opts.firstWhere((o) => o['isCorrect'] == true, orElse: () => null);
      if (correctOpt != null && _selectedAnswers[i] == correctOpt['id']) {
        correctCount++;
      }
    }

    final score = _questions.isNotEmpty ? ((correctCount / _questions.length) * 100).round() : 100;
    final isPassed = score >= 70;
    final timeSpent = (widget.timeLimitMinutes * 60) - _remainingSeconds;

    // Call submit API in background
    try {
      await _challengeDs.submitChallenge(
        widget.challengeId,
        score: score,
        timeSpentSeconds: timeSpent,
      );
    } catch (_) {}

    if (!mounted) return;

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed ? AppColors.primaryLight : const Color(0xFFFEE2E2),
              ),
              child: Center(
                child: Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                  size: 40,
                  color: isPassed ? AppColors.primary : AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isPassed ? 'Tantangan Selesai! 🎉' : 'Belum Memenuhi Syarat',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isPassed
                  ? 'Selamat! Anda memperoleh skor $score% dan mendapatkan +${widget.xpReward} XP.'
                  : 'Skor Anda $score%. Minimal benar 70% untuk lulus tantangan ini. Silakan pelajari kembali materi dan coba lagi.',
              style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text('Skor Akhir', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('$score%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isPassed ? AppColors.primary : AppColors.error)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text('Reward XP', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          isPassed ? '+${widget.xpReward} XP' : '+0 XP',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Back to challenge screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Selesai & Kembali', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_error ?? 'Belum ada pertanyaan untuk tantangan ini.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQ = _questions[_currentQuestionIndex];
    final options = (currentQ['options'] as List?) ?? [];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Keluar Tantangan?', style: TextStyle(fontWeight: FontWeight.w700)),
                content: const Text('Progres pengerjaan saat ini tidak akan tersimpan jika Anda keluar sekarang.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Lanjutkan', style: TextStyle(color: AppColors.primary)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _remainingSeconds < 60 ? const Color(0xFFFEE2E2) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 15, color: _remainingSeconds < 60 ? AppColors.error : AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  _formatTimer(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _remainingSeconds < 60 ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pertanyaan ${_currentQuestionIndex + 1} dari ${_questions.length}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${widget.xpReward} XP',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      currentQ['question'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Jawaban yang Tepat:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(options.length, (optIdx) {
                    final opt = options[optIdx];
                    final optId = opt['id'];
                    final isSelected = _selectedAnswers[_currentQuestionIndex] == optId;
                    final optionLetter = String.fromCharCode(65 + optIdx);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = optId;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primary : AppColors.background,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  optionLetter,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                opt['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0) ...[
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Sebelumnya', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _selectedAnswers[_currentQuestionIndex] == null
                          ? null
                          : () {
                              if (_currentQuestionIndex < _questions.length - 1) {
                                setState(() {
                                  _currentQuestionIndex++;
                                });
                              } else {
                                _submitChallenge();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: AppColors.border,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _currentQuestionIndex == _questions.length - 1 ? 'Kirim Jawaban' : 'Selanjutnya',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
}
