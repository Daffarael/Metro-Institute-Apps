import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../profile/screens/payment_webview_screen.dart';
import 'thermal_receipt_dialog.dart';

class CheckoutBottomSheet extends StatefulWidget {
  final String title;
  final int price;
  final String productType; // 'MINI_COURSE' | 'BOOTCAMP' | 'WEBINAR'
  final String productId;
  final String? thumbnailUrl;
  final String? subtitle;
  final VoidCallback? onSuccess;
  final VoidCallback? onStartLearning;

  const CheckoutBottomSheet({
    super.key,
    required this.title,
    required this.price,
    required this.productType,
    required this.productId,
    this.thumbnailUrl,
    this.subtitle,
    this.onSuccess,
    this.onStartLearning,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required int price,
    required String productType,
    required String productId,
    String? thumbnailUrl,
    String? subtitle,
    VoidCallback? onSuccess,
    VoidCallback? onStartLearning,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: CheckoutBottomSheet(
          title: title,
          price: price,
          productType: productType,
          productId: productId,
          thumbnailUrl: thumbnailUrl,
          subtitle: subtitle,
          onSuccess: onSuccess,
          onStartLearning: onStartLearning,
        ),
      ),
    );

    if (result == null) return false;

    if (result['success'] == true) {
      onSuccess?.call();
      if (context.mounted) {
        ThermalReceiptDialog.show(
          context,
          orderId: result['orderId']?.toString() ?? 'METRO-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          amount: (result['amount'] as num?)?.toInt() ?? 0,
          productType: productType,
          mentorName: subtitle,
          onStartLearning: () {
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).maybePop();
            }
            if (onStartLearning != null) {
              onStartLearning();
            } else {
              onSuccess?.call();
            }
          },
        );
      }
      return true;
    } else if (result['pending'] == true) {
      if (context.mounted) {
        _showPendingDialogStatic(context, result['orderId']?.toString() ?? '');
      }
      return false;
    }

    return false;
  }

  static void _showPendingDialogStatic(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Menunggu Pembayaran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan $orderId telah tersimpan. Silakan selesaikan pembayaran sesuai instruksi bank atau e-wallet pilihan Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.transactions);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Lihat Riwayat Transaksi',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Tutup',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final UserRemoteDataSource _userDataSource = sl<UserRemoteDataSource>();
  final AuthRepository _authRepository = sl<AuthRepository>();
  final TextEditingController _voucherController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthError = false;

  // Voucher states
  bool _isValidatingVoucher = false;
  String? _voucherError;
  Map<String, dynamic>? _appliedVoucher;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  int get _discountAmount {
    if (_appliedVoucher == null) return 0;
    final disc = _appliedVoucher!['discountAmount'];
    if (disc is int) return disc;
    if (disc is num) return disc.toInt();
    return 0;
  }

  int get _finalAmount {
    if (_appliedVoucher != null && _appliedVoucher!['finalPrice'] != null) {
      final fp = _appliedVoucher!['finalPrice'];
      if (fp is int) return fp;
      if (fp is num) return fp.toInt();
    }
    return widget.price;
  }

  bool get _isFree => widget.price > 0 ? _finalAmount == 0 : widget.price == 0;

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Gratis';
    final str = amount.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(regExp, (m) => '${m[1]}.')}';
  }

  String get _productBadge {
    switch (widget.productType) {
      case 'BOOTCAMP':
        return 'BOOTCAMP INTENSIF';
      case 'WEBINAR':
        return 'INSPIRE TALK';
      default:
        return 'MINI COURSE';
    }
  }

  Future<void> _handleApplyVoucher() async {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isValidatingVoucher = true;
      _voucherError = null;
    });

    try {
      final result = await _userDataSource.validateVoucher(
        code: code,
        productType: widget.productType,
        productId: widget.productId,
      );

      if (!mounted) return;
      setState(() {
        _appliedVoucher = result;
        _isValidatingVoucher = false;
        _voucherError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidatingVoucher = false;
        _voucherError = e.toString().replaceFirst('Exception: ', '');
        _appliedVoucher = null;
      });
    }
  }

  void _handleRemoveVoucher() {
    setState(() {
      _appliedVoucher = null;
      _voucherError = null;
      _voucherController.clear();
    });
  }

  Future<void> _handleInitiatePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAuthError = false;
    });

    try {
      // 1. Verify user is logged in
      final isLogged = await _authRepository.isLoggedIn();
      if (!isLogged) {
        setState(() {
          _isLoading = false;
          _isAuthError = true;
          _errorMessage = 'Sesi Anda telah berakhir atau belum masuk. Silakan login kembali ke akun Anda.';
        });
        return;
      }

      if (widget.productId.trim().isEmpty) {
        throw Exception('ID Program tidak ditemukan. Silakan muat ulang halaman detail program.');
      }

      final res = await _userDataSource.initiateTransaction(
        productType: widget.productType,
        courseId: widget.productType == 'MINI_COURSE' ? widget.productId : null,
        bootcampId: widget.productType == 'BOOTCAMP' ? widget.productId : null,
        webinarId: widget.productType == 'WEBINAR' ? widget.productId : null,
        voucherCode: _appliedVoucher?['code']?.toString(),
      );

      final orderId = res['orderId']?.toString() ?? 'METRO-${DateTime.now().millisecondsSinceEpoch}';
      final snapToken = res['snapToken']?.toString() ?? '';
      final redirectUrl = res['redirectUrl']?.toString() ??
          (snapToken.isNotEmpty ? 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken' : '');

      final bool isFreeEnrollment = (res['isFree'] == true) || (_finalAmount == 0 && redirectUrl.isEmpty);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 2. Free Enrollment flow (Diskon 100% / Gratis)
      if (isFreeEnrollment) {
        Navigator.pop(context, {
          'success': true,
          'orderId': orderId,
          'amount': 0,
        });
        return;
      }

      // 3. Paid Flow via Midtrans
      if (redirectUrl.isEmpty) {
        throw Exception('Gagal mendapatkan halaman pembayaran dari payment gateway.');
      }

      // Open Payment WebView as a full root screen
      final result = await Navigator.of(context, rootNavigator: true).push<bool?>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            orderId: orderId,
            paymentUrl: redirectUrl,
            amount: _finalAmount,
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        // Payment successful
        Navigator.pop(context, {
          'success': true,
          'orderId': orderId,
          'amount': _finalAmount,
        });
      } else {
        // Pending or closed
        Navigator.pop(context, {
          'pending': true,
          'orderId': orderId,
        });
      }
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString().replaceFirst('Exception: ', '');
      final isAuth = msg.toLowerCase().contains('token') ||
          msg.toLowerCase().contains('autentikasi') ||
          msg.toLowerCase().contains('unauthorized') ||
          msg.toLowerCase().contains('401');
      if (isAuth) {
        msg = 'Sesi login Anda telah berakhir. Silakan login kembali ke akun Anda untuk melanjutkan pembayaran.';
      }
      setState(() {
        _isLoading = false;
        _isAuthError = isAuth;
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. MODAL HEADER (1:1 with Web Mentee CheckoutModal) ──────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Pendaftaran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Periksa rincian pesanan & gunakan voucher diskon',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _isLoading ? null : () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 16),

                // ── 2. PRODUCT INFO CARD ─────────────────────────────────────
                _buildProductCard(),

                const SizedBox(height: 16),

                // ── 3. VOUCHER SECTION ───────────────────────────────────────
                _buildVoucherSection(),

                const SizedBox(height: 16),

                // ── 4. COST SUMMARY BOX ──────────────────────────────────────
                _buildCostSummaryBox(),

                // Error Banner
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorBanner(),
                ],

                const SizedBox(height: 20),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 16),

                // ── 5. MODAL FOOTER BUTTONS ──────────────────────────────────
                _buildFooterButtons(),
              ],
            ),
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('Error building CheckoutBottomSheet: $e\n$stack');
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat rincian checkout: $e',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  // ── PRODUCT CARD ─────────────────────────────────────────────────────────────
  Widget _buildProductCard() {
    final mentorText = widget.subtitle?.replaceFirst('Mentor: ', '').trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF018556),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _productBadge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (mentorText != null && mentorText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mentorText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Harga Normal: ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                _formatRupiah(widget.price),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _appliedVoucher != null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                  decoration: _appliedVoucher != null ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── VOUCHER SECTION ──────────────────────────────────────────────────────────
  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined, size: 15, color: Color(0xFF018556)),
            const SizedBox(width: 6),
            Text(
              'Punya Kode Voucher?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_appliedVoucher == null) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'CONTOH: METROPROMO',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _voucherError != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _voucherError != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF018556), width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _handleApplyVoucher(),
                    onChanged: (_) {
                      if (_voucherError != null) setState(() => _voucherError = null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValidatingVoucher ? null : _handleApplyVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF018556),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _isValidatingVoucher
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Terapkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (_voucherError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _voucherError!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF018556)),
                const SizedBox(width: 8),
                Text(
                  _appliedVoucher!['code']?.toString() ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF065F46),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF018556),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hemat ${_formatRupiah(_discountAmount)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _handleRemoveVoucher,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Hapus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── COST SUMMARY BOX ─────────────────────────────────────────────────────────
  Widget _buildCostSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              Text(
                _formatRupiah(widget.price),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          if (_appliedVoucher != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF018556)),
                    const SizedBox(width: 4),
                    Text(
                      'Diskon Voucher (${_appliedVoucher!['code']})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF018556),
                      ),
                    ),
                  ],
                ),
                Text(
                  '- ${_formatRupiah(_discountAmount)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF018556),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFCBD5E1), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                _isFree ? 'GRATIS (Rp 0)' : _formatRupiah(_finalAmount),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _isFree ? const Color(0xFF018556) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ERROR BANNER ─────────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FOOTER BUTTONS ───────────────────────────────────────────────────────────
  Widget _buildFooterButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleInitiatePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF018556),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shadowColor: const Color(0xFF018556).withValues(alpha: 0.25),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isFree ? 'Daftar Gratis Sekarang' : 'Lanjut ke Pembayaran',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
