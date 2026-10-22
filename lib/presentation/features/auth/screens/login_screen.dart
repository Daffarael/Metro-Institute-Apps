import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../widgets/verify_email_bottom_sheet.dart';

const String _googleSvg = '''
<svg viewBox="0 0 24 24" width="20" height="20">
  <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"/>
  <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"/>
  <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 10.03 0 12s.45 3.82 1.25 5.42l4.03-3.15z"/>
  <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/>
</svg>
''';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Cached borders & styles for optimal 60/120fps keyboard animation
  static final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
  );
  static final _inputEnabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
  );
  static final _inputFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFF0D1117), width: 1.6),
  );
  static final _inputErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
  );
  static final _inputFocusedErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
  );

  static final _hintStyle = GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF94A3B8),
  );
  static final _inputStyle = GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static final _formTitleStyle = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  static final _formSubtitleStyle = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    color: const Color(0xFF64748B),
    height: 1.4,
  );
  static final _btnTextStyle = GoogleFonts.plusJakartaSans(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
  static final _orTextStyle = GoogleFonts.plusJakartaSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF94A3B8),
  );
  static final _switchPromptStyle = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    color: const Color(0xFF64748B),
  );
  static final _switchActionStyle = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF0D1117),
    decoration: TextDecoration.underline,
  );
  static final _forgotPassStyle = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF0D1117),
    decoration: TextDecoration.underline,
  );

  final _pageController = PageController();

  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _registerFormKey = GlobalKey<FormState>();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _regObscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext sheetContext, StateSetter setSheetState) async {
    final formState = _loginFormKey.currentState;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi email dan kata sandi Anda.'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setSheetState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = sl<AuthRepository>();
      await authRepo.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      FcmService.syncToken();

      if (sheetContext.mounted && Navigator.of(sheetContext).canPop()) {
        Navigator.of(sheetContext).pop();
      }

      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil! Selamat datang kembali.'),
          backgroundColor: Color(0xFF0D1117),
          duration: Duration(seconds: 2),
        ),
      );

      context.go(AppRoutes.basecamp);
    } catch (e) {
      if (!mounted) return;
      final errText = e.toString().replaceAll('Exception: ', '');
      setSheetState(() {
        _errorMessage = errText;
      });
      setState(() {
        _errorMessage = errText;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(errText)),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setSheetState(() {
          _isLoading = false;
        });
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister(BuildContext sheetContext, StateSetter setSheetState) async {
    final formState = _registerFormKey.currentState;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi formulir pendaftaran Anda.'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setSheetState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final registeredEmail = _regEmailController.text.trim();

    try {
      final authRepo = sl<AuthRepository>();
      await authRepo.register(
        _regNameController.text.trim(),
        registeredEmail,
        _regPhoneController.text.trim(),
        _regPasswordController.text,
      );

      if (sheetContext.mounted && Navigator.of(sheetContext).canPop()) {
        Navigator.of(sheetContext).pop();
      }

      if (!mounted) return;

      _openVerifyEmailSheet(email: registeredEmail);
    } catch (e) {
      if (!mounted) return;
      final errText = e.toString().replaceAll('Exception: ', '');
      setSheetState(() {
        _errorMessage = errText;
      });
      setState(() {
        _errorMessage = errText;
      });
    } finally {
      if (mounted) {
        setSheetState(() {
          _isLoading = false;
        });
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext sheetContext, StateSetter setSheetState) async {
    setSheetState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted Google sign-in
        return;
      }

      final googleAuth = await googleUser.authentication;
      final authRepo = sl<AuthRepository>();

      final user = await authRepo.loginWithGoogle(
        email: googleUser.email,
        name: googleUser.displayName,
        googleId: googleUser.id,
        photoUrl: googleUser.photoUrl,
        idToken: googleAuth.idToken,
      );

      // Close the currently opened login/register sheet
      if (sheetContext.mounted && Navigator.of(sheetContext).canPop()) {
        Navigator.of(sheetContext).pop();
      }

      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;

      // Check if user has phone number.
      // If phone is missing, open Complete Registration sheet (exact web flow!)
      if (user.phone == null || user.phone!.trim().isEmpty) {
        final prefilledName = (user.name.isNotEmpty && user.name != 'Mentee')
            ? user.name
            : (googleUser.displayName ?? user.email.split('@')[0]);

        _openCompleteRegistrationSheet(
          initialName: prefilledName,
          email: user.email,
        );
      } else {
        FcmService.syncToken();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil! Selamat datang kembali.'),
            backgroundColor: Color(0xFF0D1117),
            duration: Duration(seconds: 2),
          ),
        );
        context.go(AppRoutes.basecamp);
      }
    } catch (e) {
      if (!mounted) return;
      String errText;
      if (e.toString().contains('sign_in_failed') ||
          e.toString().contains('ApiException') ||
          e.toString().contains('Api10')) {
        errText = 'Login Google gagal. Silakan coba lagi atau gunakan email & kata sandi.';
      } else if (e.toString().contains('network_error') ||
                 e.toString().contains('NetworkError')) {
        errText = 'Koneksi internet bermasalah. Periksa jaringan Anda dan coba lagi.';
      } else {
        errText = e.toString().replaceAll('Exception: ', '');
      }
      setSheetState(() {
        _errorMessage = errText;
      });
      setState(() {
        _errorMessage = errText;
      });
    } finally {
      if (mounted) {
        setSheetState(() {
          _isLoading = false;
        });
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openCompleteRegistrationSheet({
    required String initialName,
    required String email,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
    bool isSubmitting = false;
    String? completeError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 300),
        curve: const Cubic(0.32, 0.72, 0.0, 1.0),
        reverseCurve: const Cubic(0.32, 0.0, 0.67, 1.0),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final isKeyboardOpen = bottomInset > 0;
            final screenH = MediaQuery.of(ctx).size.height;
            final topPadding = MediaQuery.of(ctx).padding.top;
            final minTopClearance = topPadding + 60.0;
            final maxCardHeight = (screenH - bottomInset - minTopClearance)
                .clamp(260.0, screenH * 0.85);

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(ctx).unfocus(),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: maxCardHeight,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    26,
                    isKeyboardOpen ? 18 : 30,
                    26,
                    isKeyboardOpen ? 14 : 28,
                  ),
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
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top drag handle indicator
                        Center(
                          child: Container(
                            width: 44,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/images/logo_clean.png',
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.school_rounded,
                              size: 38,
                              color: Color(0xFF0D1117),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header
                        const Text(
                          'Langkah Terakhir!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1117),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Akun Google Anda ($email) berhasil dihubungkan. Lengkapi data di bawah ini untuk sertifikat dan komunikasi kelas Anda.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.8,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Error Banner
                        if (completeError != null) ...[
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
                                    completeError!,
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
                          const SizedBox(height: 16),
                        ],

                        // Field 1: Nama Lengkap (Untuk Sertifikat)
                        Text(
                          'Nama Lengkap (Untuk Sertifikat)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          decoration: _inputDecoration('Contoh: Mark Zuckerberg', Icons.person_outline_rounded),
                          validator: (val) {
                            if (val == null || val.trim().length < 2) {
                              return 'Nama minimal 2 karakter';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Nama ini yang akan tercetak resmi di sertifikat kelulusan Anda.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Field 2: Nomor WhatsApp Aktif
                        Text(
                          'Nomor WhatsApp Aktif',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          decoration: _inputDecoration('Contoh: 081234567890', Icons.phone_android_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Nomor WhatsApp wajib diisi';
                            if (!RegExp(r'^(08|62|\+62)').hasMatch(val.trim())) {
                              return 'Nomor harus diawali 08, 62, atau +62';
                            }
                            if (val.trim().length < 10) return 'Nomor minimal 10 digit';
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Digunakan untuk undangan grup WhatsApp kelas dan koordinasi mentor.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() {
                                      isSubmitting = true;
                                      completeError = null;
                                    });
                                    try {
                                      final authRepo = sl<AuthRepository>();
                                      await authRepo.updateProfile(
                                        name: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                      );

                                      FcmService.syncToken();

                                      if (sheetCtx.mounted && Navigator.of(sheetCtx).canPop()) {
                                        Navigator.of(sheetCtx).pop();
                                      }

                                      await Future.delayed(const Duration(milliseconds: 250));

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Pendaftaran via Google berhasil diselesaikan!'),
                                          backgroundColor: Color(0xFF0D1117),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );

                                      context.go(AppRoutes.basecamp);
                                    } catch (e) {
                                      setSheetState(() {
                                        isSubmitting = false;
                                        completeError = e.toString().replaceAll('Exception: ', '');
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D1117),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Simpan & Lanjut',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 16),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  void _openVerifyEmailSheet({required String email}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 300),
        curve: const Cubic(0.32, 0.72, 0.0, 1.0),
        reverseCurve: const Cubic(0.32, 0.0, 0.67, 1.0),
      ),
      builder: (sheetCtx) {
        return VerifyEmailBottomSheet(
          email: email,
          onVerified: () {
            Navigator.of(sheetCtx).pop();
            _emailController.text = email;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email berhasil diverifikasi! Silakan masuk.'),
                backgroundColor: Color(0xFF0D1117),
                duration: Duration(seconds: 3),
              ),
            );
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) _openLoginCard();
            });
          },
        );
      },
    );
  }

  void _openLoginCard() => _openAuthModal(initialRegister: false);
  void _openRegisterCard() => _openAuthModal(initialRegister: true);

  void _openAuthModal({bool initialRegister = false}) {
    setState(() {
      _errorMessage = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 380),
        reverseDuration: const Duration(milliseconds: 280),
        curve: const Cubic(0.32, 0.72, 0.0, 1.0), // Apple UIKit presentation curve
        reverseCurve: const Cubic(0.32, 0.0, 0.67, 1.0), // Apple UIKit dismissal curve
      ),
      builder: (sheetCtx) {
        return _AuthModalSheetWidget(
          initialRegister: initialRegister,
          sheetCtx: sheetCtx,
          loginState: this,
        );
      },
    );
  }

  Widget _buildLoginSheetForm({
    Key? key,
    required BuildContext ctx,
    required BuildContext sheetCtx,
    required StateSetter setSheetState,
    required VoidCallback onSwitchToRegister,
  }) {
    return KeyedSubtree(
      key: key,
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top drag handle indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Text(
              'Masuk ke Akun',
              textAlign: TextAlign.center,
              style: _formTitleStyle,
            ),
            const SizedBox(height: 6),
            Text(
              'Masukkan email dan kata sandi Anda untuk melanjutkan.',
              textAlign: TextAlign.center,
              style: _formSubtitleStyle,
            ),
            const SizedBox(height: 18),

            // Error Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Field: Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: _inputStyle,
              decoration: _inputDecoration(
                'Alamat Email',
                Icons.mail_outline_rounded,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                if (!val.contains('@') || !val.contains('.')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Field: Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(sheetCtx, setSheetState),
              style: _inputStyle,
              decoration: _inputDecoration(
                'Kata Sandi',
                Icons.lock_outline_rounded,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    setSheetState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Silakan hubungi admin untuk reset kata sandi.')),
                  );
                },
                child: Text(
                  'Lupa Kata Sandi?',
                  style: _forgotPassStyle,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Row: Button "Masuk" + "or" + Google Button (Side-by-side)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleLogin(sheetCtx, setSheetState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1117),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Masuk',
                              style: _btnTextStyle,
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: _orTextStyle,
                  ),
                ),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleGoogleSignIn(sheetCtx, setSheetState),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      backgroundColor: const Color(0xFFF8FAFC),
                      elevation: 0,
                    ),
                    child: Center(
                      child: SvgPicture.string(_googleSvg, width: 20, height: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Register Option (Morphs seamlessly within sheet!)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Belum punya akun mentee? ',
                  style: _switchPromptStyle,
                ),
                GestureDetector(
                  onTap: onSwitchToRegister,
                  child: Text(
                    'Daftar Akun',
                    style: _switchActionStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterSheetForm({
    Key? key,
    required BuildContext ctx,
    required BuildContext sheetCtx,
    required StateSetter setSheetState,
    required VoidCallback onSwitchToLogin,
  }) {
    return KeyedSubtree(
      key: key,
      child: Form(
        key: _registerFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top drag handle indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Text(
              'Daftar Akun Baru',
              textAlign: TextAlign.center,
              style: _formTitleStyle,
            ),
            const SizedBox(height: 6),
            Text(
              'Mulai belajar dan kembangkan skill di Metro Institute.',
              textAlign: TextAlign.center,
              style: _formSubtitleStyle,
            ),
            const SizedBox(height: 18),

            // Error Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Field 1: Nama Lengkap
            TextFormField(
              controller: _regNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: _inputStyle,
              decoration: _inputDecoration(
                'Nama Lengkap',
                Icons.person_outline_rounded,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 2) return 'Nama minimal 2 karakter';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Field 2: Email
            TextFormField(
              controller: _regEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: _inputStyle,
              decoration: _inputDecoration(
                'Alamat Email',
                Icons.mail_outline_rounded,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                if (!val.contains('@') || !val.contains('.')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Field 3: Nomor WhatsApp
            TextFormField(
              controller: _regPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: _inputStyle,
              decoration: _inputDecoration(
                'Nomor WhatsApp (08...)',
                Icons.phone_android_rounded,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Nomor WhatsApp wajib diisi';
                if (!RegExp(r'^(08|62|\+62)').hasMatch(val.trim())) {
                  return 'Nomor harus diawali 08, 62, atau +62';
                }
                if (val.trim().length < 10) return 'Nomor minimal 10 digit';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Field 4: Kata Sandi
            TextFormField(
              controller: _regPasswordController,
              obscureText: _regObscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(sheetCtx, setSheetState),
              style: _inputStyle,
              decoration: _inputDecoration(
                'Kata Sandi (min. 8 karakter)',
                Icons.lock_outline_rounded,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _regObscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    setSheetState(() {
                      _regObscurePassword = !_regObscurePassword;
                    });
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                if (val.length < 8) return 'Minimal 8 karakter';
                if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Harus mengandung huruf besar (kapital)';
                if (!RegExp(r'[a-z]').hasMatch(val)) return 'Harus mengandung huruf kecil';
                if (!RegExp(r'[0-9]').hasMatch(val)) return 'Harus mengandung angka';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Row: Button "Daftar Akun" + "or" + Google Button (Side-by-side)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleRegister(sheetCtx, setSheetState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1117),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Daftar Akun',
                              style: _btnTextStyle,
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: _orTextStyle,
                  ),
                ),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleGoogleSignIn(sheetCtx, setSheetState),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      backgroundColor: const Color(0xFFF8FAFC),
                      elevation: 0,
                    ),
                    child: Center(
                      child: SvgPicture.string(_googleSvg, width: 20, height: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Switch to Login Option (Morphs seamlessly within sheet!)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah punya akun mentee? ',
                  style: _switchPromptStyle,
                ),
                GestureDetector(
                  onTap: onSwitchToLogin,
                  child: Text(
                    'Masuk',
                    style: _switchActionStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData prefixIcon, {
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 24),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 15.5),
      border: _inputBorder,
      enabledBorder: _inputEnabledBorder,
      focusedBorder: _inputFocusedBorder,
      errorBorder: _inputErrorBorder,
      focusedErrorBorder: _inputFocusedErrorBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── STEP 1: Intro Step (With 'Continue' Button) ──────────────
          _buildIntroStep(),

          // ── STEP 2: Action Step (With 'Mulai Sekarang' & 'Daftar') ───
          _buildActionStep(),
        ],
      ),
    );
  }

  Widget _buildIntroStep() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Cinematic Background Image (Focused Developer at Night)
        Image.asset(
          'assets/images/onboarding_intro.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF0D1117),
          ),
        ),

        // 2. Multi-layer Dark Gradient Overlay for Contrast
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.60),
                Colors.black.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.30, 0.60, 1.0],
            ),
          ),
        ),

        // 3. Foreground Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Lockup + Step Indicator
                Row(
                  children: [
                    Container(
                      height: 38,
                      width: 32,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.12),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/metro_shield.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Image.asset('assets/images/logo.png'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Metro Institute',
                      style: GoogleFonts.plusJakartaSans(
                        textStyle: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Step Indicator (Step 1 active)
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms),

                const Spacer(),

                // Inspiring Large Headline (Step 1)
                Text(
                  'Langkah Awal Menuju\nPotensi Tanpa Batas.',
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Pelajari keterampilan teknologi masa kini, eksplorasi kurikulum berbasis industri, dan persiapkan karir digital impian Anda.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFFCBD5E1),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 52),

                // Primary Button: "Continue" (Moves smoothly to next onboarding step)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D1117),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: Color(0xFF0D1117),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 17, color: Color(0xFF0D1117)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionStep() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Cinematic Background Image (IT Professionals discussing code)
        Image.asset(
          'assets/images/onboarding_team.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF0D1117),
          ),
        ),

        // 2. Multi-layer Dark Gradient Overlay for Contrast
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.60),
                Colors.black.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.32, 0.65, 1.0],
            ),
          ),
        ),

        // 3. Foreground Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Lockup + Back Chevron + Step Indicator
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                    Container(
                      height: 38,
                      width: 32,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.12),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/metro_shield.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Image.asset('assets/images/logo.png'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Metro Institute',
                      style: GoogleFonts.plusJakartaSans(
                        textStyle: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Step Indicator (Step 2 active)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Inspiring Large Headline (Reference style)
                Text(
                  'Kuasai Keahlian Digital,\nPimpin Masa Depan.',
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Belajar langsung dari mentor praktisi industri, selesaikan tantangan kode nyata, dan raih sertifikasi digital resmi.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFFCBD5E1),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 52),

                // Primary Button (White pill button, triggers Login Sheet Card)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _openLoginCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D1117),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mulai Sekarang',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: Color(0xFF0D1117),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 17, color: Color(0xFF0D1117)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 12),

                // Secondary Button (Register)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _openRegisterCard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Daftar Akun Baru',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthModalSheetWidget extends StatefulWidget {
  final bool initialRegister;
  final BuildContext sheetCtx;
  final _LoginScreenState loginState;

  const _AuthModalSheetWidget({
    required this.initialRegister,
    required this.sheetCtx,
    required this.loginState,
  });

  @override
  State<_AuthModalSheetWidget> createState() => _AuthModalSheetWidgetState();
}

class _AuthModalSheetWidgetState extends State<_AuthModalSheetWidget> {
  late bool _isRegisterMode;
  late final ScrollController _sheetScrollController;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegister;
    _sheetScrollController = ScrollController();
  }

  @override
  void dispose() {
    _sheetScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final minTopClearance = topPadding + 40.0;
    final maxCardHeight = (screenH - minTopClearance).clamp(300.0, screenH * 0.90);

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main White Slide-Up Card (Apple Squircle 28px)
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: maxCardHeight,
                ),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: _sheetScrollController,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _isRegisterMode
                        ? widget.loginState._buildRegisterSheetForm(
                            key: const ValueKey('sheet_register_form'),
                            ctx: context,
                            sheetCtx: widget.sheetCtx,
                            setSheetState: setState,
                            onSwitchToLogin: () {
                              FocusScope.of(context).unfocus();
                              if (_sheetScrollController.hasClients && _sheetScrollController.offset > 0) {
                                _sheetScrollController.jumpTo(0);
                              }
                              setState(() {
                                _isRegisterMode = false;
                                widget.loginState._errorMessage = null;
                              });
                            },
                          )
                        : widget.loginState._buildLoginSheetForm(
                            key: const ValueKey('sheet_login_form'),
                            ctx: context,
                            sheetCtx: widget.sheetCtx,
                            setSheetState: setState,
                            onSwitchToRegister: () {
                              FocusScope.of(context).unfocus();
                              if (_sheetScrollController.hasClients && _sheetScrollController.offset > 0) {
                                _sheetScrollController.jumpTo(0);
                              }
                              setState(() {
                                _isRegisterMode = true;
                                widget.loginState._errorMessage = null;
                              });
                            },
                          ),
                  ),
                ),
              ),

              // Floating Circular (X) Close Button (Slides up smoothly with the card)
              Positioned(
                top: -20,
                child: GestureDetector(
                  onTap: () => Navigator.of(widget.sheetCtx).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x25000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
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
            ],
          ),
        ),
      ),
    );
  }
}
