import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../common/widgets/tactile_metro_button.dart';
import '../../../common/widgets/splash_screen.dart';

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
    borderSide: const BorderSide(color: Color(0xFF143E26), width: 1.8),
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
    color: const Color(0xFF143E26),
    letterSpacing: -0.3,
  );
  static final _formSubtitleStyle = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    color: const Color(0xFF64748B),
    height: 1.4,
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
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF143E26),
    decoration: TextDecoration.underline,
    decorationColor: const Color(0xFF143E26),
  );
  static final _forgotPassStyle = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF143E26),
    decoration: TextDecoration.underline,
    decorationColor: const Color(0xFF143E26),
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

  Future<void> _handleLogin(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
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
          backgroundColor: Color(0xFF143E26),
          duration: Duration(seconds: 2),
        ),
      );

      final user = await authRepo.getSavedUser();
      if (user != null && !user.skillTestDone) {
        context.go(AppRoutes.skillTest);
      } else {
        context.go(AppRoutes.basecamp);
      }
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
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
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

  Future<void> _handleRegister(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
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

  Future<void> _handleGoogleSignIn(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
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
        serverClientId:
            '295180634067-ol2hcifrsefnuv7luhhbb5fflp7hj1lq.apps.googleusercontent.com',
      );

      // Reset cache login Google sebelumnya agar selalu menampilkan dialog "Pilih Akun"
      try {
        await googleSignIn.signOut();
      } catch (_) {}

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
            backgroundColor: Color(0xFF143E26),
            duration: Duration(seconds: 2),
          ),
        );
        final user = await authRepo.getSavedUser();
      if (user != null && !user.skillTestDone) {
        context.go(AppRoutes.skillTest);
      } else {
        context.go(AppRoutes.basecamp);
      }
      }
    } catch (e) {
      if (!mounted) return;
      String errText;
      if (e.toString().contains('sign_in_failed') ||
          e.toString().contains('ApiException') ||
          e.toString().contains('Api10')) {
        errText =
            'Login Google gagal. Silakan coba lagi atau gunakan email & kata sandi.';
      } else if (e.toString().contains('network_error') ||
          e.toString().contains('NetworkError')) {
        errText =
            'Koneksi internet bermasalah. Periksa jaringan Anda dan coba lagi.';
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
                  constraints: BoxConstraints(maxHeight: maxCardHeight),
                  padding: EdgeInsets.fromLTRB(
                    26,
                    isKeyboardOpen ? 18 : 30,
                    26,
                    isKeyboardOpen ? 14 : 28,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
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
                                color: Color(0xFF143E26),
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
                              color: Color(0xFF143E26),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Lengkapi data berikut untuk penerbitan sertifikat Anda.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
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
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 18,
                                  ),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            decoration: _inputDecoration(
                              'Contoh: Mark Zuckerberg',
                              Icons.person_outline_rounded,
                            ),
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
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Tercetak resmi di sertifikat kelulusan.',
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            decoration: _inputDecoration(
                              'Contoh: 081234567890',
                              Icons.phone_android_rounded,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Nomor WhatsApp wajib diisi';
                              if (!RegExp(
                                r'^(08|62|\+62)',
                              ).hasMatch(val.trim())) {
                                return 'Nomor harus diawali 08, 62, atau +62';
                              }
                              if (val.trim().length < 10)
                                return 'Nomor minimal 10 digit';
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Untuk grup WhatsApp kelas & mentor.',
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
                                      if (!formKey.currentState!.validate())
                                        return;
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

                                        if (sheetCtx.mounted &&
                                            Navigator.of(sheetCtx).canPop()) {
                                          Navigator.of(sheetCtx).pop();
                                        }

                                        await Future.delayed(
                                          const Duration(milliseconds: 250),
                                        );

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Pendaftaran via Google berhasil diselesaikan!',
                                            ),
                                            backgroundColor: Color(0xFF143E26),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );

                                        final user = await authRepo.getSavedUser();
      if (user != null && !user.skillTestDone) {
        context.go(AppRoutes.skillTest);
      } else {
        context.go(AppRoutes.basecamp);
      }
                                      } catch (e) {
                                        setSheetState(() {
                                          isSubmitting = false;
                                          completeError = e
                                              .toString()
                                              .replaceAll('Exception: ', '');
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF143E26),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                        ),
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
                backgroundColor: Color(0xFF143E26),
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
    _errorMessage = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 950),
        reverseDuration: const Duration(milliseconds: 400),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
        reverseCurve: Curves.easeInCubic,
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

  /// Pre-warms bottom sheet shaders, GoogleFonts glyphs, SVG picture caches,
  /// and input decoration clipping shaders off-screen.
  /// Eliminates 100% of first-click stutter/jank so the first click
  /// is buttery smooth, identical to the 2nd and subsequent clicks.
  Widget _buildPrewarmOffstage() {
    return Positioned(
      left: -9999,
      top: -9999,
      child: IgnorePointer(
        ignoring: true,
        child: RepaintBoundary(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Pre-render and cache Google SVG Skia Picture
                SvgPicture.string(_googleSvg, width: 20, height: 20),

                // 2. Pre-shape all typography glyphs used in sheet
                Text('Masuk ke Akun', style: _formTitleStyle),
                Text(
                  'Masukkan email dan kata sandi Anda untuk melanjutkan.',
                  style: _formSubtitleStyle,
                ),
                Text('Daftar Akun Baru', style: _formTitleStyle),
                Text(
                  'Mulai belajar dan kembangkan skill di Metro Institute.',
                  style: _formSubtitleStyle,
                ),
                Text('or', style: _orTextStyle),
                Text('Belum punya akun mentee? ', style: _switchPromptStyle),
                Text('Daftar Akun', style: _switchActionStyle),
                Text('Sudah punya akun mentee? ', style: _switchPromptStyle),
                Text('Masuk', style: _switchActionStyle),
                Text('Lupa Kata Sandi?', style: _forgotPassStyle),

                // 3. Pre-compile input decoration shaders (rounded corners & borders)
                TextField(
                  decoration: _inputDecoration(
                    'Alamat Email',
                    Icons.mail_outline_rounded,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                TextField(
                  decoration: _inputDecoration(
                    'Kata Sandi',
                    Icons.lock_outline_rounded,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                TextField(
                  decoration: _inputDecoration(
                    'Nama Lengkap',
                    Icons.person_outline_rounded,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                TextField(
                  decoration: _inputDecoration(
                    'Nomor WhatsApp (08...)',
                    Icons.phone_android_rounded,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),

                // 4. Pre-compile 3D Tactile Buttons & Drop Shadows
                TactileMetroButton(
                  onPressed: null,
                  text: 'Masuk',
                  backgroundColor: const Color(0xFF143E26),
                  baseColor: const Color(0xFF092415),
                  textColor: Colors.white,
                  height: 48,
                  fontSize: 15,
                  borderRadius: BorderRadius.circular(14),
                ),
                TactileMetroButton.secondary(
                  onPressed: null,
                  height: 48,
                  isFullWidth: false,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SvgPicture.string(_googleSvg, width: 20, height: 20),
                ),

                // 5. Pre-compile circular close button (X)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF143E26),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF143E26).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
              ],
            ),
          ),
        ),
      ),
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
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 17,
                    ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Email wajib diisi';
                if (!val.contains('@') || !val.contains('.'))
                  return 'Format email tidak valid';
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
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
                    const SnackBar(
                      content: Text(
                        'Silakan hubungi admin untuk reset kata sandi.',
                      ),
                    ),
                  );
                },
                child: Text('Lupa Kata Sandi?', style: _forgotPassStyle),
              ),
            ),
            const SizedBox(height: 16),

            // Row: Button "Masuk" + "or" + Google Button (Side-by-side with 3D tactile push)
            Row(
              children: [
                Expanded(
                  child: TactileMetroButton(
                    onPressed: () => _handleLogin(sheetCtx, setSheetState),
                    isLoading: _isLoading,
                    text: 'Masuk',
                    backgroundColor: const Color(0xFF143E26),
                    baseColor: const Color(0xFF092415),
                    textColor: Colors.white,
                    height: 48,
                    fontSize: 15,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: _orTextStyle),
                ),
                TactileMetroButton.secondary(
                  onPressed: _isLoading
                      ? null
                      : () => _handleGoogleSignIn(sheetCtx, setSheetState),
                  height: 48,
                  isFullWidth: false,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SvgPicture.string(_googleSvg, width: 20, height: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Register Option (Morphs seamlessly within sheet!)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Belum punya akun mentee? ', style: _switchPromptStyle),
                GestureDetector(
                  onTap: onSwitchToRegister,
                  child: Text('Daftar Akun', style: _switchActionStyle),
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
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 17,
                    ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 2)
                  return 'Nama minimal 2 karakter';
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Email wajib diisi';
                if (!val.contains('@') || !val.contains('.'))
                  return 'Format email tidak valid';
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Nomor WhatsApp wajib diisi';
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _regObscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
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
                if (!RegExp(r'[A-Z]').hasMatch(val))
                  return 'Harus mengandung huruf besar (kapital)';
                if (!RegExp(r'[a-z]').hasMatch(val))
                  return 'Harus mengandung huruf kecil';
                if (!RegExp(r'[0-9]').hasMatch(val))
                  return 'Harus mengandung angka';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Row: Button "Daftar Akun" + "or" + Google Button (Side-by-side)
            Row(
              children: [
                Expanded(
                  child: TactileMetroButton(
                    onPressed: () => _handleRegister(sheetCtx, setSheetState),
                    isLoading: _isLoading,
                    text: 'Daftar Akun',
                    backgroundColor: const Color(0xFF143E26),
                    baseColor: const Color(0xFF092415),
                    textColor: Colors.white,
                    height: 48,
                    fontSize: 15,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: _orTextStyle),
                ),
                TactileMetroButton.secondary(
                  onPressed: _isLoading
                      ? null
                      : () => _handleGoogleSignIn(sheetCtx, setSheetState),
                  height: 48,
                  isFullWidth: false,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SvgPicture.string(_googleSvg, width: 20, height: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Switch to Login Option (Morphs seamlessly within sheet!)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sudah punya akun mentee? ', style: _switchPromptStyle),
                GestureDetector(
                  onTap: onSwitchToLogin,
                  child: Text('Masuk', style: _switchActionStyle),
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
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15.5),
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
      backgroundColor: const Color(0xFFFAF7F2),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ── STEP 1: Intro Step (With 'Lanjut' Button) ──────────────
              _buildIntroStep(),

              // ── STEP 2: Action Step (With 'Mulai Sekarang' & 'Daftar') ───
              _buildActionStep(),
            ],
          ),
          // Pre-warm offscreen to ensure Frame 1 of the modal bottom sheet is 100% smooth
          _buildPrewarmOffstage(),
        ],
      ),
    );
  }

  Widget _buildIntroStep() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomBarHeight = 84.0 + (bottomInset > 0 ? bottomInset : 14.0);

    return Container(
      color: const Color(0xFFFAF7F2),
      child: Stack(
        children: [
          // 1. Decorative soft gradient circles (warm yellow & mint accents)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF9C3).withValues(alpha: 0.65),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F5E9).withValues(alpha: 0.55),
              ),
            ),
          ),

          // 2. Foreground Content (Text, illustration, top brand lockup)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Lockup (Green logo matching loading screen) + Step Indicator
                  Row(
                    children: [
                      const MetroShieldIcon(
                        width: 32,
                        height: 38,
                        color: Color(0xFF063D2A),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Metro Institute',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF143E26),
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      // Step Indicator (Step 1 active)
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF143E26),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFACC15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // 3. Crisp HD Vector Illustration (Seamlessly blending into background)
                  Center(
                    child: SizedBox(
                      height: screenHeight * 0.31,
                      child: Image.asset(
                        'assets/images/onboarding_illu_1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 4. Headline
                  Text(
                    'Langkah Awal Menuju\nPotensi Tanpa Batas.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF143E26),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Pelajari keterampilan teknologi masa kini, eksplorasi kurikulum berbasis industri, dan persiapkan karir digital impian Anda.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5C5850),
                      height: 1.55,
                    ),
                  ),

                  // Generous distance ensuring text never crowds the bottom bar
                  SizedBox(height: bottomBarHeight + 20),
                ],
              ),
            ),
          ),

          // 3. "Let's Go" Button anchored FULL DI BAWAH (Flush against screen bottom edge)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FullBottomLetsGoButton(
              onTap: () {
                HapticFeedback.lightImpact();
                if (_pageController.hasClients) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionStep() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomBarHeight = 84.0 + (bottomInset > 0 ? bottomInset : 14.0);

    return Container(
      color: const Color(0xFFFAF7F2),
      child: Stack(
        children: [
          // 1. Decorative soft gradient circles
          Positioned(
            top: -40,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF9C3).withValues(alpha: 0.65),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F5E9).withValues(alpha: 0.55),
              ),
            ),
          ),

          // 2. Foreground Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Lockup + Circular Back Button + Step Indicator
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5E0D8),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: Color(0xFF143E26),
                          ),
                        ),
                      ),
                      const MetroShieldIcon(
                        width: 32,
                        height: 38,
                        color: Color(0xFF063D2A),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Metro Institute',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF143E26),
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      // Step Indicator (Step 2 active)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFACC15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 22,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF143E26),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // 3. Crisp HD Vector Illustration 2 (Seamlessly blending into background)
                  Center(
                    child: SizedBox(
                      height: screenHeight * 0.31,
                      child: Image.asset(
                        'assets/images/onboarding_illu_2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 4. Headline
                  Text(
                    'Kuasai Keahlian Digital,\nPimpin Masa Depan.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF143E26),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Belajar langsung dari mentor praktisi industri, selesaikan tantangan kode nyata, dan raih sertifikasi digital resmi.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5C5850),
                      height: 1.55,
                    ),
                  ),

                  // Generous distance ensuring text never crowds the bottom bar
                  SizedBox(height: bottomBarHeight + 20),
                ],
              ),
            ),
          ),

          // 3. "Sign in/Sign up" Button anchored FULL DI BAWAH (Flush against screen bottom edge)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FullBottomLetsGoButton(
              text: 'Sign in/Sign up',
              pointingUp: true,
              onTap: _openLoginCard,
            ),
          ),
        ],
      ),
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

class _AuthModalSheetWidgetState extends State<_AuthModalSheetWidget>
    with SingleTickerProviderStateMixin {
  late bool _isRegisterMode;
  late final ScrollController _sheetScrollController;
  late final AnimationController _cardSlideController;
  late final Animation<Offset> _cardSlideAnimation;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegister;
    _sheetScrollController = ScrollController();
    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
      value: 1.0,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardSlideController,
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _cardSlideController.dispose();
    _sheetScrollController.dispose();
    super.dispose();
  }

  Future<void> _switchToMode(bool toRegister) async {
    if (_isSwitching) return;
    _isSwitching = true;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    // 1. Geser card lama meluncur turun ke bawah layar secara mulus
    await _cardSlideController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInCubic,
    );

    if (!mounted) return;

    // 2. Ganti konten form & reset scroll saat card berada di bawah layar
    setState(() {
      _isRegisterMode = toRegister;
      widget.loginState._errorMessage = null;
    });
    if (_sheetScrollController.hasClients) {
      _sheetScrollController.jumpTo(0);
    }

    // 3. Card baru meluncur naik dari bawah ke atas persis seperti saat klik "Sign in/Sign up"
    await _cardSlideController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 950),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );

    _isSwitching = false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final minTopClearance = topPadding + 40.0;
    final maxCardHeight = (screenH - minTopClearance).clamp(
      300.0,
      screenH * 0.90,
    );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SlideTransition(
            position: _cardSlideAnimation,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Main White Slide-Up Card (Apple Squircle 32px)
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: maxCardHeight),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: _sheetScrollController,
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: _isRegisterMode
                        ? widget.loginState._buildRegisterSheetForm(
                            key: const ValueKey('sheet_register_form'),
                            ctx: context,
                            sheetCtx: widget.sheetCtx,
                            setSheetState: setState,
                            onSwitchToLogin: () => _switchToMode(false),
                          )
                        : widget.loginState._buildLoginSheetForm(
                            key: const ValueKey('sheet_login_form'),
                            ctx: context,
                            sheetCtx: widget.sheetCtx,
                            setSheetState: setState,
                            onSwitchToRegister: () => _switchToMode(true),
                          ),
                  ),
                ),

                // Floating Circular (X) Close Button (Docked right at the top of the card)
                if (bottomInset == 0)
                  Positioned(
                    top: -20,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(widget.sheetCtx).pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF143E26),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF143E26,
                              ).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
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
      ),
    );
  }
}
