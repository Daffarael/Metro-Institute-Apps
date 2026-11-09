import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';

class CustomPaymentScreen extends StatefulWidget {
  final String orderId;
  final int amount;
  final String productType;
  final String productId;
  final String title;
  final String? voucherCode;
  final String? redirectUrl;
  final String? snapToken;
  final String? vaNumber;
  final String? bank;
  final String? qrCodeUrl;
  final String? qrString;

  const CustomPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.productType,
    required this.productId,
    required this.title,
    this.voucherCode,
    this.redirectUrl,
    this.snapToken,
    this.vaNumber,
    this.bank,
    this.qrCodeUrl,
    this.qrString,
  });

  @override
  State<CustomPaymentScreen> createState() => _CustomPaymentScreenState();
}

enum PaymentTab { card, gopay, qris }

class _CustomPaymentScreenState extends State<CustomPaymentScreen> {
  final UserRemoteDataSource _userDataSource = sl<UserRemoteDataSource>();
  final AuthRepository _authRepository = sl<AuthRepository>();

  PaymentTab _selectedTab = PaymentTab.card;
  bool _isLoading = false;
  bool _isCheckingStatus = false;
  String? _errorMessage;

  // Real-time Midtrans settlement poller
  Timer? _midtransPollTimer;

  // Page controller for card carousel
  late final PageController _cardPageController;
  int _currentCardIndex = 0;

  // Form Controllers
  final TextEditingController _cardNumberController = TextEditingController(text: '5412 7512 3412 3456');
  final TextEditingController _nameController = TextEditingController(text: 'Koushik Sarkar');
  final TextEditingController _cardTypeController = TextEditingController(text: 'Mastercard');
  final TextEditingController _expiryController = TextEditingController(text: '07/29');
  final TextEditingController _cvvController = TextEditingController(text: '215');

  // GoPay Controller
  final TextEditingController _phoneController = TextEditingController(text: '0812 3456 7890');

  // Preset Card Configurations
  final List<Map<String, dynamic>> _presetCards = [
    {
      'type': 'Mastercard',
      'label': 'Business',
      'sublabel': 'World',
      'number': '5412 7512 3412 3456',
      'expiry': '07/29',
      'cvv': '215',
      'gradient': const [
        Color(0xFFBFE39A), // Soft Organic Lime/Mint
        Color(0xFFD7F07A), // Fresh Lime
        Color(0xFFE5FA92), // Glow Accent
      ],
      'textColor': const Color(0xFF1E293B),
    },
    {
      'type': 'VISA',
      'label': 'Platinum',
      'sublabel': 'Infinite',
      'number': '4242 7512 8831 9024',
      'expiry': '11/28',
      'cvv': '883',
      'gradient': const [
        Color(0xFFC7D2FE), // Soft Periwinkle
        Color(0xFFDDD6FE), // Lavender
        Color(0xFFE0E7FF), // Pale Indigo
      ],
      'textColor': const Color(0xFF1E1B4B),
    },
    {
      'type': 'GPN Debit',
      'label': 'Prioritas GPN',
      'sublabel': 'Debit GPN',
      'number': '6011 3829 4410 7712',
      'expiry': '05/27',
      'cvv': '491',
      'gradient': const [
        Color(0xFFA7F3D0), // Soft Mint Sage
        Color(0xFF6EE7B7), // Emerald Glow
        Color(0xFFD1FAE5), // Pale Mint
      ],
      'textColor': const Color(0xFF064E3B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController(viewportFraction: 0.88, initialPage: 0);

    // Load logged in user name if available
    _loadUserName();

    // Start Real-Time Polling to Midtrans Sandbox Server every 3 seconds!
    _startMidtransSettlementPolling();

    _cardNumberController.addListener(() {
      final text = _cardNumberController.text.replaceAll(' ', '');
      if (text.startsWith('4')) {
        if (_cardTypeController.text != 'VISA') {
          setState(() => _cardTypeController.text = 'VISA');
        }
      } else if (text.startsWith('5')) {
        if (_cardTypeController.text != 'Mastercard') {
          setState(() => _cardTypeController.text = 'Mastercard');
        }
      } else if (text.startsWith('6') || text.startsWith('1')) {
        if (_cardTypeController.text != 'GPN Debit') {
          setState(() => _cardTypeController.text = 'GPN Debit');
        }
      }
      setState(() {});
    });

    _nameController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
    _cvvController.addListener(() => setState(() {}));
  }

  void _startMidtransSettlementPolling() {
    _midtransPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkMidtransStatus(showToast: false);
    });
  }

  Future<void> _checkMidtransStatus({bool showToast = false}) async {
    if (widget.orderId.isEmpty) return;
    if (_isCheckingStatus) return;

    if (showToast) setState(() => _isCheckingStatus = true);

    try {
      final res = await _userDataSource.verifyTransaction(widget.orderId);
      final status = res['status']?.toString();

      if (status == 'SUCCESS') {
        _midtransPollTimer?.cancel();
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status Midtrans: ${status ?? 'PENDING'} (Menunggu Pembayaran)'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (_) {
      // Ignored during passive polling
    } finally {
      if (showToast && mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = await _authRepository.getSavedUser();
      if (user != null && user.name.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _nameController.text = user.name.trim();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _midtransPollTimer?.cancel();
    _cardPageController.dispose();
    _cardNumberController.dispose();
    _nameController.dispose();
    _cardTypeController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onCardPageChanged(int index) {
    setState(() {
      _currentCardIndex = index;
      final card = _presetCards[index];
      _cardNumberController.text = card['number'] as String;
      _cardTypeController.text = card['type'] as String;
      _expiryController.text = card['expiry'] as String;
      _cvvController.text = card['cvv'] as String;
    });
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Gratis';
    final str = amount.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(regExp, (m) => '${m[1]}.')}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        backgroundColor: const Color(0xFF018556),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── TRIGGER VERIFICATION FLOW ────────────────────────────────────────────────
  void _handleProcessPayment() {
    setState(() => _errorMessage = null);

    final activeOrderId = widget.orderId.isNotEmpty
        ? widget.orderId
        : 'METRO-${DateTime.now().millisecondsSinceEpoch}';

    if (_selectedTab == PaymentTab.card) {
      _show3dSecureDialog(activeOrderId);
    } else if (_selectedTab == PaymentTab.gopay) {
      _showGopayPinDialog(activeOrderId);
    } else {
      _showQrisConfirmationDialog(activeOrderId);
    }
  }

  // ── 1. 3D SECURE BANK VERIFICATION MODAL ─────────────────────────────────────
  void _show3dSecureDialog(String activeOrderId) {
    final rawNumber = _cardNumberController.text.replaceAll(' ', '');
    final last4 = rawNumber.length >= 4 ? rawNumber.substring(rawNumber.length - 4) : '3456';
    final cardType = _cardTypeController.text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _OtpVerificationSheet(
          orderId: activeOrderId,
          amountText: _formatRupiah(widget.amount),
          cardType: cardType,
          last4Digits: last4,
          onVerified: () async {
            Navigator.pop(bottomSheetContext);
            await _finalizeSuccessfulPayment(activeOrderId);
          },
        );
      },
    );
  }

  // ── 2. GOPAY PIN MODAL ───────────────────────────────────────────────────────
  void _showGopayPinDialog(String activeOrderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _GopayPinSheet(
          orderId: activeOrderId,
          phone: _phoneController.text.trim(),
          amountText: _formatRupiah(widget.amount),
          onVerified: () async {
            Navigator.pop(bottomSheetContext);
            await _finalizeSuccessfulPayment(activeOrderId);
          },
        );
      },
    );
  }

  // ── 3. QRIS CONFIRMATION MODAL ───────────────────────────────────────────────
  void _showQrisConfirmationDialog(String activeOrderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _QrisConfirmationSheet(
          orderId: activeOrderId,
          amountText: _formatRupiah(widget.amount),
          qrString: widget.qrString,
          onCheckStatus: () => _checkMidtransStatus(showToast: true),
          onVerified: () async {
            Navigator.pop(bottomSheetContext);
            await _finalizeSuccessfulPayment(activeOrderId);
          },
        );
      },
    );
  }

  Future<void> _finalizeSuccessfulPayment(String activeOrderId) async {
    setState(() => _isLoading = true);

    try {
      await _userDataSource.simulateTransaction(activeOrderId);
      _midtransPollTimer?.cancel();

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Payment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // ── MIDTRANS LIVE BADGE ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Midtrans Sandbox: ${widget.orderId}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyToClipboard(widget.orderId, 'Order ID Midtrans'),
                    child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── SCROLLABLE CONTENT ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector Tabs (Card, GoPay, QRIS/GPN)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPaymentSelectorPills(),
                    ),
                    const SizedBox(height: 20),

                    // 2. Tab Content
                    if (_selectedTab == PaymentTab.card) ...[
                      _buildCardCarousel(),
                      const SizedBox(height: 14),
                      _buildCarouselDots(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCardFormFields(),
                      ),
                    ] else if (_selectedTab == PaymentTab.gopay) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildGoPayContent(),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildQrisGpnContent(),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── BOTTOM FLOATING ACTION BUTTON ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleProcessPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4F05A),
                        foregroundColor: const Color(0xFF1E293B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF1E293B),
                              ),
                            )
                          : Text(
                              'Payment',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                                letterSpacing: -0.2,
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
    );
  }

  // ── 1. PAYMENT METHOD SELECTOR PILLS ─────────────────────────────────────────
  Widget _buildPaymentSelectorPills() {
    return Row(
      children: [
        // Tab 1: Card
        Expanded(
          child: _selectorPill(
            isSelected: _selectedTab == PaymentTab.card,
            onTap: () => setState(() => _selectedTab = PaymentTab.card),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle),
                        ),
                        Transform.translate(
                          offset: const Offset(-2, 0),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFFF79E1B), shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Tab 2: GoPay
        Expanded(
          child: _selectorPill(
            isSelected: _selectedTab == PaymentTab.gopay,
            onTap: () => setState(() => _selectedTab = PaymentTab.gopay),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(color: Color(0xFF00AED6), shape: BoxShape.circle),
                  child: const Center(
                    child: Icon(Icons.account_balance_wallet_rounded, size: 11, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'gopay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00AED6),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Tab 3: QRIS / GPN
        Expanded(
          child: _selectorPill(
            isSelected: _selectedTab == PaymentTab.qris,
            onTap: () => setState(() => _selectedTab = PaymentTab.qris),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xFF0F172A)),
                const SizedBox(width: 4),
                Text(
                  'GPN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectorPill({
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 3)),
                ]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }

  // ── 2. CARD CAROUSEL ─────────────────────────────────────────────────────────
  Widget _buildCardCarousel() {
    return SizedBox(
      height: 206,
      child: PageView.builder(
        controller: _cardPageController,
        onPageChanged: _onCardPageChanged,
        itemCount: _presetCards.length,
        itemBuilder: (context, index) {
          final cardData = _presetCards[index];
          final isSelected = index == _currentCardIndex;

          final displayNum = isSelected && _cardNumberController.text.trim().isNotEmpty
              ? _cardNumberController.text.trim()
              : cardData['number'] as String;

          final displayName = isSelected && _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'Koushik Sarkar';

          final displayExpiry = isSelected && _expiryController.text.trim().isNotEmpty
              ? _expiryController.text.trim()
              : cardData['expiry'] as String;

          final displayCvv = isSelected && _cvvController.text.trim().isNotEmpty
              ? _cvvController.text.trim()
              : cardData['cvv'] as String;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: cardData['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0x18000000) : const Color(0x08000000),
                  blurRadius: isSelected ? 20 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 206),
                  painter: _CardWavePainter(),
                ),

                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cardData['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: cardData['textColor'] as Color,
                              letterSpacing: -0.2,
                            ),
                          ),
                          _buildBrandLogo(cardData['type'] as String),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 38,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            ),
                            child: Center(
                              child: Container(
                                width: 22,
                                height: 16,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF94A3B8), width: 0.8),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            cardData['sublabel'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: (cardData['textColor'] as Color).withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),

                      Text(
                        displayNum,
                        style: GoogleFonts.spaceMono(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: cardData['textColor'] as Color,
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Card Holder',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: (cardData['textColor'] as Color).withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cardData['textColor'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expires',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: (cardData['textColor'] as Color).withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  displayExpiry,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cardData['textColor'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CVV',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: (cardData['textColor'] as Color).withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  displayCvv,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cardData['textColor'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandLogo(String type) {
    if (type.contains('VISA')) {
      return Text(
        'VISA',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: const Color(0xFF1E3A8A),
        ),
      );
    } else if (type.contains('GPN')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'GPN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle),
        ),
        Transform.translate(
          offset: const Offset(-8, 0),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_presetCards.length, (index) {
        final isActive = index == _currentCardIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 7,
          height: isActive ? 8 : 7,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF818CF8) : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ── 3. FORM FIELDS ───────────────────────────────────────────────────────────
  Widget _buildCardFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Card Number'),
        const SizedBox(height: 6),
        _pillTextField(
          controller: _cardNumberController,
          hint: '1234 5678 1234 5678',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberInputFormatter(),
            LengthLimitingTextInputFormatter(19),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Name'),
                  const SizedBox(height: 6),
                  _pillTextField(
                    controller: _nameController,
                    hint: 'Koushik Sarkar',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Card ID'),
                  const SizedBox(height: 6),
                  _pillTextField(
                    controller: _cardTypeController,
                    hint: 'Mastercard',
                    readOnly: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Expiration Date'),
                  const SizedBox(height: 6),
                  _pillTextField(
                    controller: _expiryController,
                    hint: '07/29',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryDateInputFormatter(),
                      LengthLimitingTextInputFormatter(5),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('CVV'),
                  const SizedBox(height: 6),
                  _pillTextField(
                    controller: _cvvController,
                    hint: '215',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _pillTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ── GOPAY CONTENT ────────────────────────────────────────────────────────────
  Widget _buildGoPayContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFF00AED6), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GoPay E-Wallet (Midtrans)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Terhubung langsung ke Sandbox Midtrans',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _fieldLabel('Nomor Handphone Terdaftar'),
          const SizedBox(height: 6),
          _pillTextField(
            controller: _phoneController,
            hint: '0812 3456 7890',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          Text(
            'Klik tombol Payment di bawah untuk konfirmasi PIN, atau lunaskan transaksi order ${widget.orderId} via website Midtrans Simulator.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), height: 1.45),
          ),
        ],
      ),
    );
  }

  // ── QRIS / GPN CONTENT ───────────────────────────────────────────────────────
  Widget _buildQrisGpnContent() {
    final qrCodeValue = widget.qrString ?? 'https://simulator.sandbox.midtrans.com/qris/index';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'GPN',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'QRIS Standar Nasional (Midtrans)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Box Graphic
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2_rounded, size: 140, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 14),

          // Midtrans QRIS Simulator Copy Button
          GestureDetector(
            onTap: () => _copyToClipboard(qrCodeValue, 'Kode QRIS Midtrans'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    'Salin Kode QRIS untuk Midtrans Simulator',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Buka simulator.sandbox.midtrans.com/qris/index lalu paste kode QRIS untuk bayar di Midtrans Simulator. Aplikasi akan mendeteksi status settlement secara otomatis!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          // Check Status Button
          TextButton.icon(
            onPressed: () => _checkMidtransStatus(showToast: true),
            icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF0F172A)),
            label: Text(
              'Cek Status Midtrans Sekarang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 1. 3D SECURE OTP SHEET ───────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _OtpVerificationSheet extends StatefulWidget {
  final String orderId;
  final String amountText;
  final String cardType;
  final String last4Digits;
  final VoidCallback onVerified;

  const _OtpVerificationSheet({
    required this.orderId,
    required this.amountText,
    required this.cardType,
    required this.last4Digits,
    required this.onVerified,
  });

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _error;
  int _secondsRemaining = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Masukkan 6 digit kode OTP Midtrans/Bank');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Otorisasi 3D Secure (Midtrans)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${widget.cardType} Authentication',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _summaryRow('Merchant', 'PT METRO INSTITUTE INDONESIA'),
                const SizedBox(height: 6),
                _summaryRow('Order ID', widget.orderId),
                const SizedBox(height: 6),
                _summaryRow('Kartu', '${widget.cardType} •••• ${widget.last4Digits}'),
                const SizedBox(height: 6),
                _summaryRow('Total Pembayaran', widget.amountText, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Kode OTP Midtrans 6-digit simulasi default adalah 112233.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 12),

          Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _error != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: GoogleFonts.spaceMono(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '• • • • • •',
                hintStyle: GoogleFonts.spaceMono(fontSize: 22, letterSpacing: 8, color: const Color(0xFFCBD5E1)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFFDC2626)),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              setState(() {
                _otpController.text = '112233';
                _error = null;
              });
            },
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Isi Cepat OTP Midtrans (112233)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _submitOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      'Konfirmasi & Otorisasi',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? const Color(0xFF018556) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 2. GOPAY PIN SHEET ───────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _GopayPinSheet extends StatefulWidget {
  final String orderId;
  final String phone;
  final String amountText;
  final VoidCallback onVerified;

  const _GopayPinSheet({
    required this.orderId,
    required this.phone,
    required this.amountText,
    required this.onVerified,
  });

  @override
  State<_GopayPinSheet> createState() => _GopayPinSheetState();
}

class _GopayPinSheetState extends State<_GopayPinSheet> {
  final TextEditingController _pinController = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 6) {
      setState(() => _error = 'Masukkan 6 digit PIN GoPay Anda');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFF00AED6), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Konfirmasi PIN GoPay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Tagihan', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF166534))),
                Text(
                  widget.amountText,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF166534)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Masukkan 6 digit PIN GoPay untuk nomor ${widget.phone}:',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 12),

          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _error != null ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: GoogleFonts.spaceMono(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 10,
                color: const Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(border: InputBorder.none, hintText: '••••••', contentPadding: EdgeInsets.zero),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFFDC2626)),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              setState(() {
                _pinController.text = '123456';
                _error = null;
              });
            },
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'Isi Cepat PIN Demo (123456)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _submitPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AED6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text('Bayar Sekarang', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 3. QRIS CONFIRMATION SHEET ───────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _QrisConfirmationSheet extends StatelessWidget {
  final String orderId;
  final String amountText;
  final String? qrString;
  final VoidCallback onCheckStatus;
  final VoidCallback onVerified;

  const _QrisConfirmationSheet({
    required this.orderId,
    required this.amountText,
    this.qrString,
    required this.onCheckStatus,
    required this.onVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(6)),
                child: Text('GPN', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text(
                'Pembayaran QRIS Midtrans',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Order ID: $orderId\nTotal: $amountText\n\nJika Anda sudah membayar di website Midtrans Simulator (simulator.sandbox.midtrans.com/qris/index), tekan tombol di bawah untuk memeriksa status lunas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569), height: 1.45),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onCheckStatus,
              icon: const Icon(Icons.sync_rounded, color: Colors.white),
              label: Text('Cek Status Pembayaran Midtrans', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: onVerified,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF018556), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text(
                '⚡ Simulasikan Lunas Langsung',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF018556)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DECORATIVE CARD WAVE PAINTER ─────────────────────────────────────────────
class _CardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path();
    path.moveTo(size.width * 0.45, size.height);
    path.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.45,
      size.width,
      size.height * 0.35,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── INPUT FORMATTERS ─────────────────────────────────────────────────────────
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) {
        buffer.write(' ');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 && digits.length > 2) {
        buffer.write('/');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
