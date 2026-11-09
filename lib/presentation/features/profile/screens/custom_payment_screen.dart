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

    // Start Real-Time Polling to Midtrans Sandbox Server every 3 seconds
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
      _checkMidtransStatus();
    });
  }

  Future<void> _checkMidtransStatus() async {
    if (widget.orderId.isEmpty) return;

    try {
      final res = await _userDataSource.verifyTransaction(widget.orderId);
      final status = res['status']?.toString();

      if (status == 'SUCCESS') {
        _midtransPollTimer?.cancel();
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Ignored during passive polling
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
            // ── TOP BAR (Back chevron + "Payment" title) ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

            // ── SCROLLABLE CONTENT ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector Tabs (Card, GoPay, QRIS/GPN)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPaymentSelectorPills(),
                    ),
                    const SizedBox(height: 16),

                    // 2. Tab Content
                    if (_selectedTab == PaymentTab.card) ...[
                      _buildCardCarousel(),
                      const SizedBox(height: 10),
                      _buildCarouselDots(),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 14),
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

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── BOTTOM FLOATING ACTION BUTTON ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleProcessPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4F05A),
                    foregroundColor: const Color(0xFF1E293B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    minimumSize: const Size(double.infinity, 54),
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
        height: 54,
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
      height: 196,
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
              : 'Metro Student';

          final displayExpiry = isSelected && _expiryController.text.trim().isNotEmpty
              ? _expiryController.text.trim()
              : cardData['expiry'] as String;

          final displayCvv = isSelected && _cvvController.text.trim().isNotEmpty
              ? _cvvController.text.trim()
              : cardData['cvv'] as String;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: cardData['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0x18000000) : const Color(0x08000000),
                  blurRadius: isSelected ? 18 : 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 196),
                  painter: _CardWavePainter(),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                              fontSize: 16,
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
                            width: 36,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 14,
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
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: (cardData['textColor'] as Color).withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),

                      Text(
                        displayNum,
                        style: GoogleFonts.spaceMono(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
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
                                    fontSize: 8.5,
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
                                    fontSize: 11.5,
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
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                    color: (cardData['textColor'] as Color).withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  displayExpiry,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
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
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                    color: (cardData['textColor'] as Color).withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  displayCvv,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
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
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: const Color(0xFF1E3A8A),
        ),
      );
    } else if (type.contains('GPN')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'GPN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 19,
          height: 19,
          decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle),
        ),
        Transform.translate(
          offset: const Offset(-7, 0),
          child: Container(
            width: 19,
            height: 19,
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
        const SizedBox(height: 5),
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
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Name'),
                  const SizedBox(height: 5),
                  _pillTextField(
                    controller: _nameController,
                    hint: 'Nama Pemegang Kartu',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Card ID'),
                  const SizedBox(height: 5),
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
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Expiration Date'),
                  const SizedBox(height: 5),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('CVV'),
                  const SizedBox(height: 5),
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
        fontSize: 12.5,
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
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
        borderRadius: BorderRadius.circular(22),
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
                    'GoPay E-Wallet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Pembayaran instan via GoPay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _fieldLabel('Nomor Handphone Terdaftar'),
          const SizedBox(height: 5),
          _pillTextField(
            controller: _phoneController,
            hint: '0812 3456 7890',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          Text(
            'Setelah menekan tombol Payment, Anda akan diarahkan untuk memvalidasi transaksi dengan aman.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), height: 1.45),
          ),
        ],
      ),
    );
  }

  // ── QRIS / GPN CONTENT ───────────────────────────────────────────────────────
  Widget _buildQrisGpnContent() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
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
                'QRIS Standar Nasional',
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

          Text(
            'Mendukung semua Bank GPN (BCA, Mandiri, BRI, BNI) & E-Wallet (GoPay, OVO, Dana, ShopeePay)',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 1. 3D SECURE OTP SHEET (DESAIN OTENTIKASI BANK PROFESIONAL) ──────────────
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
  // Pre-filled with valid Sandbox OTP so it feels seamless & realistic
  final TextEditingController _otpController = TextEditingController(text: '112233');
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
      setState(() => _error = 'Masukkan 6 digit kode OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    // Realistic banking network delay (1.2 seconds)
    await Future.delayed(const Duration(milliseconds: 1200));

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
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi 3D Secure',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF475569)),
                    const SizedBox(width: 4),
                    Text(
                      '256-bit SSL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Merchant & Transaction Summary Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _summaryRow('Merchant', 'Metro Institute'),
                const SizedBox(height: 6),
                _summaryRow('Kartu', '${widget.cardType} •••• ${widget.last4Digits}'),
                const SizedBox(height: 6),
                _summaryRow('Total Pembayaran', widget.amountText, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Untuk keamanan transaksi, masukkan 6 digit kode OTP yang telah dikirimkan ke nomor ponsel Anda.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569), height: 1.45),
          ),
          const SizedBox(height: 14),

          // Clean OTP Input Box
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '• • • • • •',
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
          const SizedBox(height: 12),

          Center(
            child: Text(
              _secondsRemaining > 0
                  ? 'Kirim ulang kode dalam $_secondsRemaining detik'
                  : 'Kirim Ulang Kode OTP',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: _secondsRemaining > 0 ? FontWeight.w500 : FontWeight.w700,
                color: _secondsRemaining > 0 ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 18),

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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Memverifikasi...',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  : Text(
                      'Konfirmasi Pembayaran',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batalkan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
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
  final TextEditingController _pinController = TextEditingController(text: '123456');
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

    await Future.delayed(const Duration(milliseconds: 1200));

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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _summaryRow('Merchant', 'Metro Institute'),
                const SizedBox(height: 6),
                _summaryRow('Total Pembayaran', widget.amountText, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Masukkan 6 digit PIN GoPay untuk otorisasi pembayaran:',
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
          const SizedBox(height: 18),

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
// ── 3. QRIS CONFIRMATION SHEET ───────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _QrisConfirmationSheet extends StatefulWidget {
  final String orderId;
  final String amountText;
  final String? qrString;
  final VoidCallback onVerified;

  const _QrisConfirmationSheet({
    required this.orderId,
    required this.amountText,
    this.qrString,
    required this.onVerified,
  });

  @override
  State<_QrisConfirmationSheet> createState() => _QrisConfirmationSheetState();
}

class _QrisConfirmationSheetState extends State<_QrisConfirmationSheet> {
  bool _isProcessing = false;

  Future<void> _handleConfirm() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
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
                'Pembayaran QRIS',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
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
                _summaryRow('Merchant', 'Metro Institute'),
                const SizedBox(height: 6),
                _summaryRow('Total Pembayaran', widget.amountText, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Pastikan Anda telah memindai kode QRIS menggunakan aplikasi Bank atau E-Wallet Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569), height: 1.45),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF018556),
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
                  : Text('Saya Sudah Membayar', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
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
