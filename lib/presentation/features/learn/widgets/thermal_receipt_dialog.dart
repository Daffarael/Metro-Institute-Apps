import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// ThermalReceiptDialog — A photorealistic, delightful thermal receipt printer
/// animation modal.
///
/// Simulates a physical sleek hardware printer slot at the top, out of which
/// the printed digital receipt slides/rolls down smoothly. Once fully printed,
/// the "Payment Successful" confirmation, a direct "Cetak" button (PDF),
/// and the primary "Mulai Belajar Sekarang" button are displayed.
class ThermalReceiptDialog extends StatefulWidget {
  final String orderId;
  final String title;
  final int amount;
  final String productType; // 'MINI_COURSE' | 'BOOTCAMP' | 'WEBINAR'
  final String? menteeName;
  final String? mentorName;
  final VoidCallback onStartLearning;
  final VoidCallback? onViewTransactions;

  const ThermalReceiptDialog({
    super.key,
    required this.orderId,
    required this.title,
    required this.amount,
    required this.productType,
    this.menteeName,
    this.mentorName,
    required this.onStartLearning,
    this.onViewTransactions,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String title,
    required int amount,
    required String productType,
    String? menteeName,
    String? mentorName,
    required VoidCallback onStartLearning,
    VoidCallback? onViewTransactions,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ThermalReceipt',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim, secAnim) {
        return ThermalReceiptDialog(
          orderId: orderId,
          title: title,
          amount: amount,
          productType: productType,
          menteeName: menteeName,
          mentorName: mentorName,
          onStartLearning: onStartLearning,
          onViewTransactions: onViewTransactions,
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        );
      },
    );
  }

  @override
  State<ThermalReceiptDialog> createState() => _ThermalReceiptDialogState();
}

class _ThermalReceiptDialogState extends State<ThermalReceiptDialog>
    with TickerProviderStateMixin {
  // Controller 0: Printer hardware entrance (glides up from center to top)
  late final AnimationController _printerEntranceController;
  late final Animation<double> _printerEntranceAnimation;
  late final Animation<double> _printerFadeAnimation;
  late final Animation<double> _printerScaleAnimation;

  // Controller 1: Paper rollout animation (pelan, stabil, dan realistis)
  late final AnimationController _rolloutController;
  late final Animation<double> _rolloutAnimation;

  // Controller 2: Footer and action buttons fade-in
  late final AnimationController _footerController;
  late final Animation<double> _footerFadeAnimation;
  late final Animation<Offset> _footerSlideAnimation;

  bool _isPrinting = true;
  bool _printerVisible = false;
  bool _isAtTop = false;
  bool _paperStarted = false;

  @override
  void initState() {
    super.initState();

    // 0. Printer Entrance Animation (Hardware appears at center and glides smoothly up to top position)
    _printerEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _printerEntranceAnimation = CurvedAnimation(
      parent: _printerEntranceController,
      curve: Curves.easeOutCubic,
    );

    _printerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _printerEntranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _printerScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _printerEntranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    // 1. Rollout Animation — diperlambat ke 4200ms agar keluar santai dan realistis
    _rolloutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _rolloutAnimation = CurvedAnimation(
      parent: _rolloutController,
      curve: Curves.easeOutCubic,
    );

    // 2. Footer actions slide & fade
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _footerFadeAnimation = CurvedAnimation(
      parent: _footerController,
      curve: Curves.easeOut,
    );

    _footerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _footerController, curve: Curves.easeOutCubic));

    // Listen to rollout completion
    _rolloutController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isPrinting = false;
          });
        }
        HapticFeedback.mediumImpact();
        // Langsung tampilkan konfirmasi pembayaran & tombol aksi tanpa kedipan merah
        _footerController.forward();
      }
    });

    // Sequence: printer hardware lands at the top FIRST → wait → paper rolls out slowly
    _startPrinterEntrance();
  }

  void _startPrinterEntrance() {
    setState(() {
      _printerVisible = true;
      _isAtTop = false;
      _paperStarted = false; // Paper is NOT in tree yet — no premature appearance!
      _isPrinting = true;
    });
    HapticFeedback.lightImpact();
    _printerEntranceController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      // Printer has landed firmly at the top!
      HapticFeedback.mediumImpact();
      setState(() {
        _isAtTop = true;
      });
      // Wait a distinct pause (500ms) so user clearly sees the dark navy printer settled at the top first
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startPrintingFlow();
      });
    });
  }

  void _startPrintingFlow() {
    setState(() {
      _paperStarted = true; // NOW the paper is allowed to mount and roll out slowly
      _isPrinting = true;
    });
    _footerController.reset();
    _rolloutController.forward(from: 0.0);

    // Periodic gentle haptic ticks during the printing roll
    _triggerPrintHaptics();
  }

  Future<void> _triggerPrintHaptics() async {
    for (int i = 0; i < 11; i++) {
      await Future.delayed(const Duration(milliseconds: 360));
      if (!mounted || !_isPrinting) break;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _printerEntranceController.dispose();
    _rolloutController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Gratis';
    final str = amount.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(regExp, (m) => '${m[1]}.')}';
  }

  String get _productBadgeLabel {
    switch (widget.productType) {
      case 'BOOTCAMP':
        return 'BOOTCAMP INTENSIF';
      case 'WEBINAR':
        return 'WEBINAR EKSKLUSIF';
      default:
        return 'MINI COURSE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String formattedDate;
    try {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);
    } catch (_) {
      try {
        formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(now);
      } catch (_) {
        const months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
        final day = now.day.toString().padLeft(2, '0');
        final m = months[now.month - 1];
        final h = now.hour.toString().padLeft(2, '0');
        final min = now.minute.toString().padLeft(2, '0');
        formattedDate = '$day $m ${now.year}, $h:$min';
      }
    }
    final clientName = (widget.menteeName != null && widget.menteeName!.trim().isNotEmpty)
        ? widget.menteeName!.trim()
        : 'Mentee Metro';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: _isPrinting
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── THERMAL PRINTER DISPENSER + ROLLING RECEIPT STACK ─────────
                SizedBox(
                  width: 330,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // LAYER 1: RECEIPT PAPER (Rolls down out of the printer slot)
                      // ONLY renders after printer hardware has completely landed at the top!
                      if (_paperStarted)
                        Padding(
                          padding: const EdgeInsets.only(top: 26),
                          child: AnimatedBuilder(
                            animation: _rolloutAnimation,
                            builder: (context, child) {
                              return ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: _rolloutAnimation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildReceiptPaper(
                              clientName: clientName,
                              formattedDate: formattedDate,
                            ),
                          ),
                        ),

                      // LAYER 2: HARDWARE PRINTER DISPENSER — enters from center and glides smoothly to top
                      if (_printerVisible)
                        AnimatedBuilder(
                          animation: _printerEntranceController,
                          builder: (context, child) {
                            final screenHeight = MediaQuery.of(context).size.height;
                            final startOffsetY = (screenHeight * 0.38).clamp(180.0, 360.0);
                            final translateY = (1.0 - _printerEntranceAnimation.value) * startOffsetY;

                            return Transform.translate(
                              offset: Offset(0, translateY),
                              child: Transform.scale(
                                scale: _printerScaleAnimation.value,
                                child: Opacity(
                                  opacity: _printerFadeAnimation.value,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: _buildPrinterHardware(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── FOOTER: SUCCESS CONFIRMATION & ACTION BUTTONS ─────────────
                AnimatedBuilder(
                  animation: _footerFadeAnimation,
                  builder: (context, child) {
                    return IgnorePointer(
                      ignoring: _isPrinting,
                      child: Opacity(
                        opacity: _footerFadeAnimation.value,
                        child: SlideTransition(
                          position: _footerSlideAnimation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'Payment Successful',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Semua materi telah terbuka dan siap kamu pelajari.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Action Buttons
                      SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            // 1. Primary Action: Mulai Belajar Sekarang
                            ElevatedButton(
                              onPressed: widget.onStartLearning,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_fill_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mulai Belajar Sekarang',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. Action: Cetak PDF berlogo Metro Institute
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isPrinting ? null : _printPdfReceipt,
                                icon: const Icon(Icons.print_rounded, size: 18),
                                label: Text(
                                  'Cetak',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. HARDWARE PRINTER DISPENSER (Photorealistic Metallic Capsule with Slit)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPrinterHardware() {
    return Container(
      width: 330,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF334155), // Top specular highlight
            Color(0xFF0F172A), // Dark metallic body
            Color(0xFF020617), // Deep base
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 28,
            offset: Offset(0, 12),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle top reflective shine
          Positioned(
            top: 2,
            left: 32,
            right: 32,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Printer Slit / Opening
          Container(
            width: 284,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              // Micro perforated dot teeth inside slit
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  28,
                  (index) => Container(
                    width: 2.2,
                    height: 2.2,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Status LED Light on left edge
          Positioned(
            left: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isAtTop
                        ? const Color(0xFF10B981)
                        : (_printerVisible ? const Color(0xFF34D399) : const Color(0xFF059669)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: _isAtTop ? 0.9 : 0.4),
                        blurRadius: _isAtTop ? 8 : 4,
                        spreadRadius: _isAtTop ? 1.5 : 0.5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. RECEIPT PAPER (Crisp Thermal Receipt with Jagged Serrated Tear Edge)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildReceiptPaper({
    required String clientName,
    required String formattedDate,
  }) {
    return ClipPath(
      clipper: _TornReceiptClipper(toothWidth: 9, toothHeight: 6),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt Header Brand
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'METRO INSTITUTE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DIGITAL LEARNING RECEIPT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                // Brand Emblem — Metro Institute Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Client & Order Info (Clean monochrome thermal style)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _receiptMetaRow('MENTEE', clientName.toUpperCase()),
                const SizedBox(height: 5),
                _receiptMetaRow('ORDER ID', widget.orderId),
                const SizedBox(height: 5),
                _receiptMetaRow('METODE', 'MIDTRANS PAYMENT'),
                const SizedBox(height: 5),
                _receiptMetaRow('STATUS', 'LUNAS (INVOICE PAID)'),
              ],
            ),

            const SizedBox(height: 20),

            // Big Amount Display
            Text(
              _formatRupiah(widget.amount),
              style: GoogleFonts.spaceMono(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$formattedDate  •  INVOICE PAID',
              style: GoogleFonts.spaceMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 16),
            _dashedLine(),
            const SizedBox(height: 14),

            // Purchased Item Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1X ${widget.title.toUpperCase()}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _productBadgeLabel,
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatRupiah(widget.amount),
                  style: GoogleFonts.spaceMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _dashedLine(),
            const SizedBox(height: 14),

            // Financial Breakdown
            _receiptPriceRow('Subtotal', _formatRupiah(widget.amount)),
            const SizedBox(height: 6),
            _receiptPriceRow('Diskon (Promo)', '-Rp 0', isDiscount: true),
            const SizedBox(height: 6),
            _receiptPriceRow('Biaya Platform', 'Rp 0'),
            const SizedBox(height: 12),

            // Solid Divider
            Container(height: 1.5, color: const Color(0xFF0F172A)),
            const SizedBox(height: 12),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRAND TOTAL',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _formatRupiah(widget.amount),
                  style: GoogleFonts.spaceMono(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Thank You Message
            Center(
              child: Text(
                'TERIMA KASIH TELAH BELAJAR\nBERSAMA METRO INSTITUTE!',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.4,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Official Transaction Reference (Barcode graphic removed as requested)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'TXN-${widget.orderId}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _receiptMetaRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _receiptPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _dashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.2,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PDF GENERATION & NATIVE PRINT (Official Metro Institute Receipt PDF)
  // ───────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfMetaRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfPriceRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromHex('#64748B'),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
      ],
    );
  }

  Future<void> _printPdfReceipt() async {
    try {
      HapticFeedback.lightImpact();

      final doc = pw.Document();

      // Load official logo image from assets
      pw.MemoryImage? logoImage;
      try {
        final bytes = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {}

      final now = DateTime.now();
      String formattedDate;
      try {
        formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);
      } catch (_) {
        formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(now);
      }

      final clientName = (widget.menteeName != null && widget.menteeName!.trim().isNotEmpty)
          ? widget.menteeName!.trim()
          : 'Mentee Metro';

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: 360,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1.5),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Header Brand & Logo
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'METRO INSTITUTE',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#0F172A'),
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'DIGITAL LEARNING RECEIPT',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                color: PdfColor.fromHex('#64748B'),
                              ),
                            ),
                          ],
                        ),
                        if (logoImage != null)
                          pw.Container(
                            width: 42,
                            height: 42,
                            child: pw.Image(logoImage),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1),
                    pw.SizedBox(height: 12),

                    // Metadata
                    _pdfMetaRow('MENTEE', clientName.toUpperCase()),
                    pw.SizedBox(height: 5),
                    _pdfMetaRow('ORDER ID', widget.orderId),
                    pw.SizedBox(height: 5),
                    _pdfMetaRow('METODE', 'MIDTRANS PAYMENT'),
                    pw.SizedBox(height: 5),
                    _pdfMetaRow('STATUS', 'LUNAS (INVOICE PAID)'),
                    pw.SizedBox(height: 18),

                    // Big Amount
                    pw.Text(
                      _formatRupiah(widget.amount),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F172A'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '$formattedDate  •  INVOICE PAID',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        color: PdfColor.fromHex('#64748B'),
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 0.8),
                    pw.SizedBox(height: 12),

                    // Purchased Item
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '1X ${widget.title.toUpperCase()}',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#0F172A'),
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                _productBadgeLabel,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColor.fromHex('#94A3B8'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          _formatRupiah(widget.amount),
                          style: pw.TextStyle(
                            fontSize: 11.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 0.8),
                    pw.SizedBox(height: 10),

                    // Price Breakdown
                    _pdfPriceRow('Subtotal', _formatRupiah(widget.amount)),
                    pw.SizedBox(height: 5),
                    _pdfPriceRow('Diskon (Promo)', '-Rp 0'),
                    pw.SizedBox(height: 5),
                    _pdfPriceRow('Biaya Platform', 'Rp 0'),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColor.fromHex('#0F172A'), thickness: 1.2),
                    pw.SizedBox(height: 10),

                    // Grand Total
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'GRAND TOTAL',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                        pw.Text(
                          _formatRupiah(widget.amount),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 22),

                    // Thank You & Txn ID
                    pw.Center(
                      child: pw.Text(
                        'TERIMA KASIH TELAH BELAJAR\nBERSAMA METRO INSTITUTE!',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#475569'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    pw.Center(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F1F5F9'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
                        ),
                        child: pw.Text(
                          'TXN-${widget.orderId}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColor.fromHex('#64748B'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Save PDF to documents directory and open it
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Struk_Metro_Institute_${widget.orderId}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await doc.save());

      // Open the saved PDF with the system viewer
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. JAGGED SERRATED TEAR CLIPPER (Physical Receipt Cut Teeth Effect)
// ─────────────────────────────────────────────────────────────────────────────
class _TornReceiptClipper extends CustomClipper<Path> {
  final double toothWidth;
  final double toothHeight;

  _TornReceiptClipper({this.toothWidth = 9.0, this.toothHeight = 6.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - toothHeight);

    final count = (size.width / toothWidth).floor();
    final actualWidth = size.width / count;

    for (int i = 0; i < count; i++) {
      final x1 = (i + 0.5) * actualWidth;
      final y1 = size.height;
      final x2 = (i + 1) * actualWidth;
      final y2 = size.height - toothHeight;
      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
