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
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: 'Daffarael Anaqi Ali');
  final TextEditingController _cardTypeController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController(text: '07/29');
  final TextEditingController _cvvController = TextEditingController(text: '215');

  // GoPay Controller
  final TextEditingController _phoneController = TextEditingController(text: '0812 3456 7890');

  // ── 10 PRESET BANK CARDS (4 VISA, 4 GPN, + 2 TEMPLATES, NO MASTERCARD) ─────
  final List<Map<String, dynamic>> _presetCards = [
    // ── KARTU VISA (4 BANK BESAR) ──
    {
      'id': 'bca_visa',
      'fullName': 'BCA Visa',
      'bankName': 'BCA',
      'type': 'VISA',
      'label': 'BCA Visa',
      'sublabel': 'Platinum',
      'number': '4111 2233 4455 6677',
      'expiry': '07/29',
      'cvv': '215',
      'gradient': const [
        Color(0xFF005EAA), // BCA Royal Blue
        Color(0xFF003D73),
        Color(0xFF002244),
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'mandiri_visa',
      'fullName': 'Mandiri Visa',
      'bankName': 'Mandiri',
      'type': 'VISA',
      'label': 'Mandiri Visa',
      'sublabel': 'Signature',
      'number': '4201 9988 7766 5544',
      'expiry': '11/28',
      'cvv': '883',
      'gradient': const [
        Color(0xFF002D62), // Mandiri Deep Navy
        Color(0xFF001B3A),
        Color(0xFFB8860B), // Gold touch
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'bri_visa',
      'fullName': 'BRI Visa',
      'bankName': 'BRI',
      'type': 'VISA',
      'label': 'BRI Visa',
      'sublabel': 'Infinite',
      'number': '4333 5544 2211 8899',
      'expiry': '08/29',
      'cvv': '412',
      'gradient': const [
        Color(0xFF00529C), // BRI Vibrant Blue
        Color(0xFF0066B3),
        Color(0xFF003B70),
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'bni_visa',
      'fullName': 'BNI Visa',
      'bankName': 'BNI',
      'type': 'VISA',
      'label': 'BNI Visa',
      'sublabel': 'Emerald',
      'number': '4455 6677 8899 0011',
      'expiry': '04/28',
      'cvv': '935',
      'gradient': const [
        Color(0xFF005E5D), // BNI Teal
        Color(0xFF003837),
        Color(0xFFE05A10), // Orange touch
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'other_visa',
      'fullName': 'Bank Lainnya (Visa)',
      'bankName': 'Bank Lainnya',
      'type': 'VISA',
      'label': 'Visa Classic',
      'sublabel': 'Classic',
      'number': '4000 1234 5678 9010',
      'expiry': '12/29',
      'cvv': '123',
      'gradient': const [
        Color(0xFFC7D2FE), // Soft Lavender / Periwinkle
        Color(0xFFDDD6FE),
        Color(0xFFE0E7FF),
      ],
      'textColor': const Color(0xFF1E1B4B),
    },

    // ── KARTU DEBIT GPN (4 BANK BESAR) ──
    {
      'id': 'bca_gpn',
      'fullName': 'BCA Debit GPN',
      'bankName': 'BCA',
      'type': 'GPN',
      'label': 'BCA Paspor GPN',
      'sublabel': 'Debit GPN',
      'number': '6011 8822 3344 1122',
      'expiry': '05/27',
      'cvv': '491',
      'gradient': const [
        Color(0xFF005EAA), // BCA Blue-Emerald GPN
        Color(0xFF018556),
        Color(0xFF003D73),
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'mandiri_gpn',
      'fullName': 'Mandiri Debit GPN',
      'bankName': 'Mandiri',
      'type': 'GPN',
      'label': 'Mandiri Debit GPN',
      'sublabel': 'Debit GPN',
      'number': '6011 4455 6677 8899',
      'expiry': '09/27',
      'cvv': '732',
      'gradient': const [
        Color(0xFF002D62), // Mandiri Deep Teal GPN
        Color(0xFF0F766E),
        Color(0xFF001B3A),
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'bri_gpn',
      'fullName': 'BRI Debit GPN',
      'bankName': 'BRI',
      'type': 'GPN',
      'label': 'BRI BritAma GPN',
      'sublabel': 'Debit GPN',
      'number': '6011 1122 3344 5566',
      'expiry': '03/28',
      'cvv': '618',
      'gradient': const [
        Color(0xFF00529C), // BRI Blue-Green GPN
        Color(0xFF047857),
        Color(0xFF003B70),
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'bni_gpn',
      'fullName': 'BNI Debit GPN',
      'bankName': 'BNI',
      'type': 'GPN',
      'label': 'BNI Taplus GPN',
      'sublabel': 'Debit GPN',
      'number': '6011 7788 9900 1122',
      'expiry': '06/28',
      'cvv': '504',
      'gradient': const [
        Color(0xFF005E5D), // BNI Emerald GPN
        Color(0xFF065F46),
        Color(0xFF003B70),
      ],
      'textColor': Colors.white,
    },
    {
      'id': 'other_gpn',
      'fullName': 'Bank Lainnya (Debit GPN)',
      'bankName': 'Bank Lainnya',
      'type': 'GPN',
      'label': 'Nasional GPN',
      'sublabel': 'Debit GPN',
      'number': '6011 0000 1111 2222',
      'expiry': '01/29',
      'cvv': '999',
      'gradient': const [
        Color(0xFFBFE39A), // Signature Soft Mint / Lime Template!
        Color(0xFFD7F07A),
        Color(0xFFE5FA92),
      ],
      'textColor': const Color(0xFF1E293B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController(viewportFraction: 0.88, initialPage: 0);

    // Initial card setup
    final initialCard = _presetCards[0];
    _cardNumberController.text = initialCard['number'] as String;
    _cardTypeController.text = initialCard['fullName'] as String;
    _expiryController.text = initialCard['expiry'] as String;
    _cvvController.text = initialCard['cvv'] as String;

    _loadUserName();
    _startMidtransSettlementPolling();

    _cardNumberController.addListener(() {
      final text = _cardNumberController.text.replaceAll(' ', '');
      if (text.startsWith('4')) {
        if (!_cardTypeController.text.contains('Visa')) {
          setState(() => _cardTypeController.text = 'Visa');
        }
      } else if (text.startsWith('6') || text.startsWith('1') || text.startsWith('5')) {
        if (!_cardTypeController.text.contains('GPN')) {
          setState(() => _cardTypeController.text = 'Debit GPN');
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
    } catch (_) {}
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

  void _selectCardByIndex(int index) {
    if (index < 0 || index >= _presetCards.length) return;
    setState(() {
      _currentCardIndex = index;
      final card = _presetCards[index];
      _cardNumberController.text = card['number'] as String;
      _cardTypeController.text = card['fullName'] as String;
      _expiryController.text = card['expiry'] as String;
      _cvvController.text = card['cvv'] as String;
    });
    if (_cardPageController.hasClients) {
      _cardPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Gratis';
    final str = amount.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(regExp, (m) => '${m[1]}.')}';
  }

  void _showBankPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
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
              const SizedBox(height: 16),
              Text(
                'Pilih Bank & Jenis Kartu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: KARTU VISA
                      _pickerSectionTitle('KARTU KREDIT / DEBIT (VISA)'),
                      ...List.generate(5, (i) {
                        final card = _presetCards[i];
                        final isSelected = _currentCardIndex == i;
                        return _bankPickerItem(card, isSelected, () {
                          Navigator.pop(ctx);
                          _selectCardByIndex(i);
                        });
                      }),

                      const SizedBox(height: 14),
                      // Section 2: DEBIT GPN
                      _pickerSectionTitle('KARTU DEBIT NASIONAL (GPN)'),
                      ...List.generate(5, (i) {
                        final idx = i + 5;
                        final card = _presetCards[idx];
                        final isSelected = _currentCardIndex == idx;
                        return _bankPickerItem(card, isSelected, () {
                          Navigator.pop(ctx);
                          _selectCardByIndex(idx);
                        });
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pickerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _bankPickerItem(Map<String, dynamic> card, bool isSelected, VoidCallback onTap) {
    final isVisa = card['type'] == 'VISA';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: card['gradient'] as List<Color>,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                card['fullName'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: isVisa ? const Color(0xFFEEF2FF) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isVisa ? 'VISA' : 'GPN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isVisa ? const Color(0xFF4338CA) : const Color(0xFFDC2626),
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF018556), size: 18),
            ],
          ],
        ),
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
    final card = _presetCards[_currentCardIndex];
    final cardTitle = '${card['bankName']} (${card['type']})';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _OtpVerificationSheet(
          orderId: activeOrderId,
          amountText: _formatRupiah(widget.amount),
          cardTitle: cardTitle,
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
    final activeCard = _presetCards[_currentCardIndex];

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
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector Tabs (Card VISA/GPN, GoPay, QRIS/GPN)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPaymentSelectorPills(),
                    ),
                    const SizedBox(height: 14),

                    // 2. Tab Content
                    if (_selectedTab == PaymentTab.card) ...[
                      // Combobox: Pilih Bank & Kartu
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildBankCombobox(activeCard),
                      ),
                      const SizedBox(height: 12),

                      // Card Carousel
                      _buildCardCarousel(),
                      const SizedBox(height: 8),
                      _buildCarouselDots(),
                      const SizedBox(height: 14),

                      // Form Fields
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCardFormFields(activeCard),
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
                      const SizedBox(height: 12),
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

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── BOTTOM FLOATING ACTION BUTTON ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
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

  // ── 1. PAYMENT METHOD SELECTOR PILLS (VISA/GPN, GOPAY, QRIS) ─────────────────
  Widget _buildPaymentSelectorPills() {
    return Row(
      children: [
        // Tab 1: Card (VISA / GPN - NO Mastercard)
        Expanded(
          child: _selectorPill(
            isSelected: _selectedTab == PaymentTab.card,
            onTap: () => setState(() => _selectedTab = PaymentTab.card),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFF0F172A)),
                const SizedBox(width: 5),
                Text(
                  'Card',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
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
                const Icon(Icons.qr_code_2_rounded, size: 19, color: Color(0xFF0F172A)),
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
        height: 50,
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

  // ── COMBOBOX PILIH BANK & KARTU (BCA, MANDIRI, BRI, BNI, LAINNYA) ───────────
  Widget _buildBankCombobox(Map<String, dynamic> currentCard) {
    final isVisa = currentCard['type'] == 'VISA';

    return GestureDetector(
      onTap: _showBankPickerBottomSheet,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              isVisa ? Icons.credit_card_rounded : Icons.account_balance_rounded,
              size: 18,
              color: const Color(0xFF0F172A),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentCard['fullName'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isVisa ? const Color(0xFFEEF2FF) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isVisa ? 'VISA' : 'GPN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isVisa ? const Color(0xFF4338CA) : const Color(0xFFDC2626),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  // ── 2. CARD CAROUSEL (DIPILIH DARI COMBOBOX / SWIPE) ─────────────────────────
  Widget _buildCardCarousel() {
    return SizedBox(
      height: 192,
      child: PageView.builder(
        controller: _cardPageController,
        onPageChanged: (idx) {
          setState(() {
            _currentCardIndex = idx;
            final card = _presetCards[idx];
            _cardNumberController.text = card['number'] as String;
            _cardTypeController.text = card['fullName'] as String;
            _expiryController.text = card['expiry'] as String;
            _cvvController.text = card['cvv'] as String;
          });
        },
        itemCount: _presetCards.length,
        itemBuilder: (context, index) {
          final cardData = _presetCards[index];
          final isSelected = index == _currentCardIndex;

          final displayNum = isSelected && _cardNumberController.text.trim().isNotEmpty
              ? _cardNumberController.text.trim()
              : cardData['number'] as String;

          final displayName = isSelected && _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'Daffarael Anaqi Ali';

          final displayExpiry = isSelected && _expiryController.text.trim().isNotEmpty
              ? _expiryController.text.trim()
              : cardData['expiry'] as String;

          final displayCvv = isSelected && _cvvController.text.trim().isNotEmpty
              ? _cvvController.text.trim()
              : cardData['cvv'] as String;

          final textColor = cardData['textColor'] as Color;

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
                  blurRadius: isSelected ? 16 : 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 192),
                  painter: _CardWavePainter(),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Bank Name + Brand Logo (VISA or GPN)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cardData['bankName'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          _buildBrandLogo(cardData['type'] as String),
                        ],
                      ),

                      // Metallic Chip + Sublabel
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
                              color: textColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),

                      // Card Number
                      Text(
                        displayNum,
                        style: GoogleFonts.spaceMono(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: textColor,
                        ),
                      ),

                      // Card Holder, Expires, CVV
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
                                    color: textColor.withValues(alpha: 0.65),
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
                                    color: textColor,
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
                                    color: textColor.withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  displayExpiry,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
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
                                    color: textColor.withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  displayCvv,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
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
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      );
    }

    // Default: Red Official GPN Badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        'GPN',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_presetCards.length, (index) {
        final isActive = index == _currentCardIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ── 3. FORM FIELDS ───────────────────────────────────────────────────────────
  Widget _buildCardFormFields(Map<String, dynamic> currentCard) {
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
                  _fieldLabel('Card ID / Bank'),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: _showBankPickerBottomSheet,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentCard['fullName'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
                        ],
                      ),
                    ),
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
// ── 1. 3D SECURE OTP SHEET ───────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _OtpVerificationSheet extends StatefulWidget {
  final String orderId;
  final String amountText;
  final String cardTitle;
  final String last4Digits;
  final VoidCallback onVerified;

  const _OtpVerificationSheet({
    required this.orderId,
    required this.amountText,
    required this.cardTitle,
    required this.last4Digits,
    required this.onVerified,
  });

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
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
                      '${widget.cardTitle} Authentication',
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
                _summaryRow('Kartu', '${widget.cardTitle} •••• ${widget.last4Digits}'),
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

          // OTP Input Box
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
