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
  }) {
    return showModalBottomSheet<bool>(
      context: context,
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
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthError = false;

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
        return 'WEBINAR SPESIAL';
      default:
        return 'MINI COURSE';
    }
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

      final res = await _userDataSource.initiateTransaction(
        productType: widget.productType,
        courseId: widget.productType == 'MINI_COURSE' ? widget.productId : null,
        bootcampId: widget.productType == 'BOOTCAMP' ? widget.productId : null,
        webinarId: widget.productType == 'WEBINAR' ? widget.productId : null,
      );

      final orderId = res['orderId']?.toString() ?? 'METRO-${DateTime.now().millisecondsSinceEpoch}';
      final snapToken = res['snapToken']?.toString() ?? '';
      final redirectUrl = res['redirectUrl']?.toString() ??
          (snapToken.isNotEmpty ? 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken' : '');

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (redirectUrl.isEmpty) {
        throw Exception('Gagal mendapatkan halaman pembayaran dari payment gateway.');
      }

      // Open Payment WebView
      final result = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            orderId: orderId,
            paymentUrl: redirectUrl,
            amount: widget.price,
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
          amount: widget.price,
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
      padding: EdgeInsets.fromLTRB(22, 16, 22, 28 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
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
            const SizedBox(height: 18),

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
            const SizedBox(height: 18),

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
            const SizedBox(height: 20),

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
                        _formatRupiah(widget.price),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
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
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
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
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            // CTA Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleInitiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
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
                        const Icon(Icons.lock_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.price == 0 ? 'Daftar Sekarang' : 'Lanjut ke Pembayaran',
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
                'Transaksi aman & terenkripsi oleh Midtrans Payment Gateway',
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
