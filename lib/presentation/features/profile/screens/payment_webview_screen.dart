import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';

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
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;

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
                launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
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
      ),
    );
  }
}
