import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';

class VerifyEmailBottomSheet extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const VerifyEmailBottomSheet({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<VerifyEmailBottomSheet> createState() => _VerifyEmailBottomSheetState();
}

class _VerifyEmailBottomSheetState extends State<VerifyEmailBottomSheet> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSuccess = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  bool _showCloseButton = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.animation != null) {
        void statusListener(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            route!.animation?.removeStatusListener(statusListener);
            if (mounted) setState(() => _showCloseButton = true);
          } else if (status == AnimationStatus.reverse) {
            if (mounted) setState(() => _showCloseButton = false);
          }
        }

        if (route!.animation!.isCompleted) {
          if (mounted) setState(() => _showCloseButton = true);
        } else {
          route.animation!.addStatusListener(statusListener);
        }
      } else {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _showCloseButton = true);
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 440), () {
      if (mounted && !_showCloseButton) {
        setState(() => _showCloseButton = true);
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _resendCountdown = 0);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authRepo = sl<AuthRepository>();
      await authRepo.verifyEmail(widget.email, otp);

      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      // Clear OTP inputs on error so user can re-enter easily
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isVerifying) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      final authRepo = sl<AuthRepository>();
      await authRepo.resendVerify(widget.email);
      _startCountdown();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP baru telah dikirim ke email Anda.'),
          backgroundColor: Color(0xFF0D1117),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final topPadding = MediaQuery.of(context).padding.top;
    final minTopClearance = topPadding + 60.0;
    final maxCardHeight = (MediaQuery.of(context).size.height - bottomInset - minTopClearance)
        .clamp(240.0, MediaQuery.of(context).size.height * 0.85);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: maxCardHeight),
              padding: EdgeInsets.fromLTRB(24, isKeyboardOpen ? 14 : 28, 24, isKeyboardOpen ? 16 : 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x35000000),
                    blurRadius: 30,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: isKeyboardOpen ? 10 : 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header Icon (hidden when keyboard is open to keep compact)
                    if (!isKeyboardOpen) ...[
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117).withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mark_email_read_rounded,
                              size: 28,
                              color: Color(0xFF0D1117),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                // Title
                const Text(
                  'Verifikasi Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  'Masukkan 6 digit kode OTP yang dikirim ke\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 6-Digit OTP Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 44,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.backspace &&
                              _controllers[index].text.isEmpty &&
                              index > 0) {
                            _focusNodes[index - 1].requestFocus();
                            _controllers[index - 1].clear();
                          }
                        },
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          enabled: !_isVerifying && !_isSuccess,
                          style: GoogleFonts.firaCode(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D1117),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0D1117), width: 1.8),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.length > 1) {
                              // Pasted multi-character code
                              final pasted = val.trim();
                              for (int i = 0; i < 6 && i < pasted.length; i++) {
                                _controllers[i].text = pasted[i];
                              }
                              if (pasted.length >= 6) {
                                _focusNodes[5].unfocus();
                                _verifyOtp(pasted.substring(0, 6));
                              } else {
                                _focusNodes[pasted.length].requestFocus();
                              }
                              return;
                            }
                            if (val.isNotEmpty) {
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _focusNodes[index].unfocus();
                              }
                              if (_currentOtp.length == 6) {
                                _verifyOtp(_currentOtp);
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Verifying or Success Feedback Indicator
                if (_isVerifying)
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1117)),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Memverifikasi kode...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isSuccess)
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Verifikasi Berhasil!',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 20),

                const SizedBox(height: 10),

                // Resend OTP Section
                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          'Kirim ulang kode dalam ${_resendCountdown}s',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : TextButton(
                          onPressed: _isVerifying ? null : _resendCode,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0D1117),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Kirim Ulang Kode',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

          // Floating Circular (X) Close Button (Shown smoothly after card has settled)
          Positioned(
            top: -22,
            child: AnimatedOpacity(
              opacity: (_showCloseButton && !isKeyboardOpen) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedScale(
                scale: (_showCloseButton && !isKeyboardOpen) ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: IgnorePointer(
                  ignoring: !_showCloseButton || isKeyboardOpen,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x35000000),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
