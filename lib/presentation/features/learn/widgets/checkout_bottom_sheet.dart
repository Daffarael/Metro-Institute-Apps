import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../profile/screens/custom_payment_screen.dart';
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
  }) {
    debugPrint('=== [METRO_CHECKOUT] Membuka showModalBottomSheet (useRootNavigator: false) ===');
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CheckoutBottomSheet(
        title: title,
        price: price,
        productType: productType,
        productId: productId,
        thumbnailUrl: thumbnailUrl,
        subtitle: subtitle,
        onSuccess: onSuccess,
        onStartLearning: onStartLearning,
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
        Navigator.pop(context, true);
        widget.onSuccess?.call();
        ThermalReceiptDialog.show(
          context,
          orderId: orderId,
          title: widget.title,
          amount: 0,
          productType: widget.productType,
          mentorName: widget.subtitle,
          onStartLearning: () {
            Navigator.of(context).pop();
            if (widget.onStartLearning != null) {
              widget.onStartLearning!();
            } else {
              widget.onSuccess?.call();
            }
          },
        );
        return;
      }

      // 3. Paid Flow via Midtrans
      if (redirectUrl.isEmpty) {
        throw Exception('Gagal mendapatkan halaman pembayaran dari payment gateway.');
      }

      // Buka layar pembayaran custom (tampilan 1:1 sesuai mockup native, terhubung ke Midtrans Sandbox asli)
      final result = await Navigator.of(context, rootNavigator: true).push<bool?>(
        MaterialPageRoute(
          builder: (_) => CustomPaymentScreen(
            orderId: orderId,
            amount: _finalAmount,
            productType: widget.productType,
            productId: widget.productId,
            title: widget.title,
            voucherCode: _appliedVoucher?['code']?.toString(),
            redirectUrl: redirectUrl,
            snapToken: snapToken,
            vaNumber: res['vaNumber']?.toString(),
            bank: res['bank']?.toString(),
            qrCodeUrl: res['qrCodeUrl']?.toString(),
            qrString: res['qrString']?.toString(),
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        // Payment successful
        Navigator.pop(context, true);
        widget.onSuccess?.call();
        ThermalReceiptDialog.show(
          context,
          orderId: orderId,
          title: widget.title,
          amount: _finalAmount,
          productType: widget.productType,
          mentorName: widget.subtitle,
          onStartLearning: () {
            Navigator.of(context).pop();
            if (widget.onStartLearning != null) {
              widget.onStartLearning!();
            } else {
              widget.onSuccess?.call();
            }
          },
        );
      } else {
        // Pending or closed
        Navigator.pop(context, false);
        _showPendingDialog(orderId);
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

  void _showPendingDialog(String orderId) {
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
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // Sheet Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checkout Program',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _productBadge,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Card Summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.thumbnailUrl!,
                              width: 76,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: const Color(0xFFE2E8F0)),
                              errorWidget: (context, url, error) => _thumbPlaceholder(),
                            )
                          : _thumbPlaceholder(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Included Benefits Pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _benefitChip(Icons.all_inclusive_rounded, 'Akses Selamanya'),
                  _benefitChip(Icons.verified_rounded, 'Sertifikat Resmi'),
                  _benefitChip(Icons.live_help_rounded, 'Bimbingan Mentor'),
                ],
              ),
              const SizedBox(height: 16),

              // Voucher Section (High Contrast, Bold, No Faded Colors)
              if (_appliedVoucher != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF018556), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x18018556), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF018556),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _appliedVoucher!['code']?.toString() ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: const Color(0xFF018556),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF018556),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _appliedVoucher!['type'] == 'PERCENT'
                                        ? '-${_appliedVoucher!['value']}%'
                                        : '-${_formatRupiah(_appliedVoucher!['value'] as int? ?? 0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hemat ${_formatRupiah(_discountAmount)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 22),
                        tooltip: 'Hapus Voucher',
                        onPressed: _handleRemoveVoucher,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _voucherError != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.confirmation_num_outlined,
                                  size: 18,
                                  color: _voucherError != null ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _voucherController,
                                    textCapitalization: TextCapitalization.characters,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: 0.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Punya kode kupon/voucher?',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF94A3B8),
                                        letterSpacing: 0,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      filled: false,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (_) => _handleApplyVoucher(),
                                    onChanged: (_) {
                                      if (_voucherError != null) setState(() => _voucherError = null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isValidatingVoucher ? null : _handleApplyVoucher,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF018556),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(90, 50),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isValidatingVoucher
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Terapkan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (_voucherError != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _voucherError!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Price Breakdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _priceRow('Harga Program', _formatRupiah(widget.price)),
                    if (_appliedVoucher != null && _discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.discount_rounded, size: 14, color: Color(0xFF018556)),
                              const SizedBox(width: 5),
                              Text(
                                'Diskon Voucher (${_appliedVoucher!['code']})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF018556),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '- ${_formatRupiah(_discountAmount)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF018556),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _priceRow('Biaya Platform / Admin', 'Rp 0 (Gratis)'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _isFree ? 'Rp 0 (Gratis)' : _formatRupiah(_finalAmount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _isFree ? const Color(0xFF018556) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isAuthError) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.login);
                          },
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: Text(
                            'Login Sekarang',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 38),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // CTA Button (Adaptive: Solid Green if Free, Solid Dark if Paid)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleInitiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFree ? const Color(0xFF018556) : const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isFree ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFree
                                ? 'Daftar Gratis Sekarang'
                                : 'Lanjut ke Pembayaran (${_formatRupiah(_finalAmount)})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 10),
              Center(
                child: Text(
                  _isFree
                      ? 'Pendaftaran 100% gratis dengan kupon promo terverifikasi'
                      : 'Transaksi aman & terenkripsi oleh Midtrans Payment Gateway',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 76,
      height: 64,
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Icon(Icons.school_rounded, color: Colors.white54, size: 28),
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF0F172A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
