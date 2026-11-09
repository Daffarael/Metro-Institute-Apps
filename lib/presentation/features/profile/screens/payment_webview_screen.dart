import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String orderId;
  final String paymentUrl;
  final int amount;

  const PaymentWebViewScreen({
    super.key,
    required this.orderId,
    required this.paymentUrl,
    required this.amount,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final UserRemoteDataSource _userDs = sl<UserRemoteDataSource>();
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;
  bool _isSimulating = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (url) {
            if (mounted) setState(() => _hasError = false);
            _checkStatusUrl(url);
          },
          onPageFinished: (url) {
            _checkStatusUrl(url);
          },
          onWebResourceError: (error) {
            // Some deep links like intent:// or gopay:// are not standard web resources
            debugPrint('Payment WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            final lower = url.toLowerCase();

            // Detect finish callback from Midtrans
            if (lower.contains('checkout/success') ||
                lower.contains('status_code=200') ||
                lower.contains('transaction_status=settlement') ||
                lower.contains('transaction_status=capture')) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }

            if (lower.contains('checkout/failed') ||
                lower.contains('status_code=202') ||
                lower.contains('transaction_status=deny') ||
                lower.contains('transaction_status=cancel')) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            // Launch e-wallet or banking deep links (GoPay, ShopeePay, BCA OneKlik, etc.)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication).catchError((_) async {
                  return launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
                });
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkStatusUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('checkout/success') ||
        lower.contains('status_code=200') ||
        lower.contains('transaction_status=settlement')) {
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleSimulateSuccess() async {
    setState(() => _isSimulating = true);
    try {
      await _userDs.simulateTransaction(widget.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil disimulasikan lunas!'),
          backgroundColor: Color(0xFF018556),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSimulating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal simulasi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleVerifyPayment() async {
    setState(() => _isVerifying = true);
    try {
      final res = await _userDs.verifyTransaction(widget.orderId);
      if (!mounted) return;
      setState(() => _isVerifying = false);
      final status = res['status']?.toString().toUpperCase();
      if (status == 'SUCCESS' || status == 'SETTLEMENT' || status == 'CAPTURE') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil dikonfirmasi lunas!'),
            backgroundColor: Color(0xFF018556),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Status pembayaran masih menunggu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal cek status: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Batalkan Pembayaran?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Pesanan dengan ID ${widget.orderId} akan tetap tersimpan di Riwayat Transaksi Anda dan dapat dilanjutkan nanti.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Lanjutkan Bayar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(regExp, (m) => '${m[1]}.')}';
  }

  void _closeWithResult(dynamic res) {
    if (!mounted) return;
    Navigator.of(context).pop(res);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave) {
          _closeWithResult(null);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: () async {
              final shouldLeave = await _onWillPop();
              if (shouldLeave) {
                _closeWithResult(null);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembayaran Aman',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${widget.orderId} • ${_formatRupiah(widget.amount)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A), size: 22),
              onPressed: () => _controller.reload(),
              tooltip: 'Muat ulang',
            ),
          ],
          bottom: _loadingProgress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2.5),
                  child: LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                    minHeight: 2.5,
                  ),
                )
              : null,
        ),
        body: _hasError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat halaman pembayaran',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan koneksi internet stabil lalu coba lagi.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _controller.reload(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : WebViewWidget(controller: _controller),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: OutlinedButton.icon(
                    onPressed: (_isVerifying || _isSimulating) ? null : _handleVerifyPayment,
                    icon: _isVerifying
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Cek Status', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: ElevatedButton.icon(
                    onPressed: (_isVerifying || _isSimulating) ? null : _handleSimulateSuccess,
                    icon: _isSimulating
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Simulasi Lunas (Test)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF018556),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
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
