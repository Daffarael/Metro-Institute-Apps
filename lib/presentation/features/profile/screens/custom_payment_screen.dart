import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';
import '../../../../data/repositories/auth_repository.dart';

// ── OFFICIAL REAL VECTOR LOGOS (BCA, MANDIRI, BRI, BNI, VISA, GPN) ───────────
const String _svgBca = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 110 32" width="110" height="32">
  <g transform="translate(0, 1)">
    <path d="M15 0 L30 15 L15 30 L0 15 Z" fill="#005EAA"/>
    <path d="M15 4.5 L25.5 15 L15 25.5 L4.5 15 Z" fill="#FFFFFF"/>
    <path d="M15 9 L21 15 L15 21 L9 15 Z" fill="#005EAA"/>
    <path d="M15 13 L17 15 L15 17 L13 15 Z" fill="#FFFFFF"/>
  </g>
  <text x="38" y="24" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-size="22" fill="#FFFFFF" letter-spacing="1.5">BCA</text>
</svg>''';

const String _svgMandiri = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 130 36" width="130" height="36">
  <path d="M82 4 C94 -1 112 1 126 9 C114 6 100 6 88 11 Z" fill="#F59E0B"/>
  <path d="M88 9 C102 3 120 7 130 16 C116 11 102 11 92 15 Z" fill="#FBBF24"/>
  <text x="2" y="28" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-size="22" fill="#FFFFFF" letter-spacing="-0.5">mandiri</text>
</svg>''';

const String _svgBri = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 110 32" width="110" height="32">
  <rect x="0" y="2" width="28" height="28" rx="7" fill="#FFFFFF"/>
  <path d="M6 8 C14 8 20 12 22 17 C18 15 12 13 6 15 Z" fill="#00529C"/>
  <path d="M6 18 C16 16 22 20 25 25 C19 23 13 22 6 24 Z" fill="#F59E0B"/>
  <text x="36" y="24" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-size="22" fill="#FFFFFF" letter-spacing="1">BRI</text>
</svg>''';

const String _svgBni = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 115 32" width="115" height="32">
  <text x="0" y="24" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-size="22" fill="#FFFFFF" letter-spacing="1.5">BNI</text>
  <g transform="translate(58, 2)">
    <rect width="42" height="28" rx="6" fill="#F15A24"/>
    <text x="21" y="20" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-size="16" fill="#FFFFFF" letter-spacing="-0.5">46</text>
  </g>
</svg>''';

const String _svgVisaWhite = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 32" width="100" height="32">
  <path fill="#FFFFFF" d="M38.6 30.4l6.3-29.8h10.1l-6.3 29.8H38.6zm35.2-28.9c-2-0.8-5.2-1.6-9.1-1.6-10.1 0-17.2 5.3-17.3 13-.1 5.7 5.1 8.9 9 10.8 4 1.9 5.3 3.2 5.3 4.9 0 2.6-3.2 3.8-6.1 3.8-4.1 0-6.3-0.6-9.6-2.1l-1.3-0.6-1.4 9.1c2.4 1.1 7 2.1 11.6 2.2 11 0 18.1-5.4 18.2-13.8.1-4.6-2.7-8.1-8.8-11-3.6-1.9-5.9-3.1-5.9-5.1 0-1.7 1.9-3.5 6.1-3.5 3.4 0 5.9 0.7 7.8 1.5l0.9 0.4 1.7-8.1zm24.2 19.1c0.8-2.3 4.1-11.3 4.1-11.3-.1 0.1 0.8-2.3 1.4-3.9l0.7 3.5c1.2 5.8 2.9 14.7 2.9 14.7l-9.1-3zm13.6-20h-7.8c-2.4 0-4.2 0.7-5.3 3.3L83.5 30.4h10.6s1.7-4.8 2.1-5.9h13c0.3 1.4 1.2 5.9 1.2 5.9h9.4L111.6 0.6zM30.6 0.6L20.8 21.0l-1-5.4C18 10.3 12.3 3.5 5.9 0.2l8.9 31.2h10.7l15.9-29.8H30.6z"/>
  <path fill="#F7B600" d="M14.1 0.6H0.2L0 2c10.8 2.8 18 9.5 21 17.5l-3-15.4c-0.5-2.2-2.1-3.5-3.9-3.5z"/>
</svg>''';

const String _svgVisaBlue = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 32" width="100" height="32">
  <path fill="#1A1F71" d="M38.6 30.4l6.3-29.8h10.1l-6.3 29.8H38.6zm35.2-28.9c-2-0.8-5.2-1.6-9.1-1.6-10.1 0-17.2 5.3-17.3 13-.1 5.7 5.1 8.9 9 10.8 4 1.9 5.3 3.2 5.3 4.9 0 2.6-3.2 3.8-6.1 3.8-4.1 0-6.3-0.6-9.6-2.1l-1.3-0.6-1.4 9.1c2.4 1.1 7 2.1 11.6 2.2 11 0 18.1-5.4 18.2-13.8.1-4.6-2.7-8.1-8.8-11-3.6-1.9-5.9-3.1-5.9-5.1 0-1.7 1.9-3.5 6.1-3.5 3.4 0 5.9 0.7 7.8 1.5l0.9 0.4 1.7-8.1zm24.2 19.1c0.8-2.3 4.1-11.3 4.1-11.3-.1 0.1 0.8-2.3 1.4-3.9l0.7 3.5c1.2 5.8 2.9 14.7 2.9 14.7l-9.1-3zm13.6-20h-7.8c-2.4 0-4.2 0.7-5.3 3.3L83.5 30.4h10.6s1.7-4.8 2.1-5.9h13c0.3 1.4 1.2 5.9 1.2 5.9h9.4L111.6 0.6zM30.6 0.6L20.8 21.0l-1-5.4C18 10.3 12.3 3.5 5.9 0.2l8.9 31.2h10.7l15.9-29.8H30.6z"/>
  <path fill="#F7B600" d="M14.1 0.6H0.2L0 2c10.8 2.8 18 9.5 21 17.5l-3-15.4c-0.5-2.2-2.1-3.5-3.9-3.5z"/>
</svg>''';

const String _svgGpn = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 68 40" width="68" height="40">
  <rect width="68" height="40" rx="9" fill="#DC2626"/>
  <path d="M12 28 C7 23 11 12 22 9 C18 14 19 20 24 23 C19 24 15 26 12 28 Z" fill="#FFFFFF"/>
  <path d="M22 10 C26 6 34 7 38 13 C33 12 28 14 27 18 C26 14 24 11 22 10 Z" fill="#FEE2E2" opacity="0.9"/>
  <text x="39" y="27" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-size="16" fill="#FFFFFF" letter-spacing="0.5">GPN</text>
</svg>''';

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

enum PaymentTab { card, va }

class _CustomPaymentScreenState extends State<CustomPaymentScreen> {
  final UserRemoteDataSource _userDataSource = sl<UserRemoteDataSource>();
  final AuthRepository _authRepository = sl<AuthRepository>();

  PaymentTab _selectedTab = PaymentTab.card;
  bool _isLoading = false;
  String? _errorMessage;

  // Real-time Midtrans settlement poller
  Timer? _midtransPollTimer;

  int _selectedDebitIndex = 0;
  int _selectedVaBankIndex = 0;
  bool _isVaGenerated = false;
  String? _liveVaNumber;
  String? _liveBillKey;
  String? _liveBillerCode;
  bool _isLoadingVa = false;

  // Form Controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: 'Daffarael Anaqi Ali');
  final TextEditingController _cardTypeController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController(text: '07/29');
  final TextEditingController _cvvController = TextEditingController(text: '215');



  // ── 2 PILIHAN UTAMA: VISA DEBIT & GPN DEBIT ────────────────────────────────
  final List<Map<String, dynamic>> _debitOptions = [
    {
      'id': 'visa_debit',
      'network': 'VISA',
      'title': 'Visa Debit',
      'subtitle': 'Kartu Debit Internasional (Wajib CVV)',
      'badge': 'VISA',
      'number': '4111 2233 4455 6677',
      'expiry': '07/29',
      'cvv': '215',
      'requiresCvv': true,
      'cardLogoAsset': 'assets/images/logo_visa_white.png',
      'comboboxLogoAsset': 'assets/images/logo_visa_official.png',
    },
    {
      'id': 'gpn_debit',
      'network': 'GPN',
      'title': 'GPN Debit',
      'subtitle': 'Kartu Debit Domestik Nasional (Tanpa CVV)',
      'badge': 'GPN',
      'number': '6011 8822 3344 1122',
      'expiry': '05/28',
      'cvv': '',
      'requiresCvv': false,
      'cardLogoAsset': 'assets/images/logo_gpn_darkmode.png',
      'comboboxLogoAsset': 'assets/images/logo_gpn_official.png',
    },
  ];

  // ── 10 BANK VIRTUAL ACCOUNT (SESUAI MIDTRANS PAYMENT SIMULATOR) ───────────
  final List<Map<String, dynamic>> _vaBanks = [
    {
      'id': 'bca',
      'name': 'BCA Virtual Account',
      'shortName': 'BCA VA',
      'code': 'bca',
      'prefix': '29857',
      'defaultVa': '29857973062042016730685',
      'color': const Color(0xFF005EAA),
      'guide': [
        'Buka aplikasi BCA Mobile / myBCA / KlikBCA.',
        'Pilih menu m-Transfer > BCA Virtual Account.',
        'Masukkan nomor Virtual Account BCA di atas.',
        'Pastikan nama merchant adalah METRO INSTITUTE dan nominal tagihan sesuai.',
        'Masukkan PIN m-BCA Anda untuk menyelesaikan pembayaran.',
      ],
    },
    {
      'id': 'bri',
      'name': 'BRI Virtual Account (BRIVA)',
      'shortName': 'BRI VA',
      'code': 'bri',
      'prefix': '29857',
      'defaultVa': '298576297789388543',
      'color': const Color(0xFF00529C),
      'guide': [
        'Buka aplikasi BRImo atau ATM BRI.',
        'Pilih menu Pembayaran > BRIVA.',
        'Masukkan nomor BRIVA di atas.',
        'Konfirmasi tagihan pembayaran ke METRO INSTITUTE.',
        'Masukkan PIN BRImo Anda untuk otorisasi.',
      ],
    },
    {
      'id': 'bni',
      'name': 'BNI Virtual Account',
      'shortName': 'BNI VA',
      'code': 'bni',
      'prefix': '988',
      'defaultVa': '9882985791219553',
      'color': const Color(0xFFF15A24),
      'guide': [
        'Buka aplikasi BNI Mobile Banking atau ATM BNI.',
        'Pilih menu Transfer > Virtual Account Billing.',
        'Input nomor Virtual Account BNI di atas.',
        'Periksa detail tagihan METRO INSTITUTE.',
        'Masukkan password transaksi / PIN BNI Anda.',
      ],
    },
    {
      'id': 'permata',
      'name': 'Permata Virtual Account',
      'shortName': 'Permata VA',
      'code': 'permata',
      'prefix': '298',
      'defaultVa': '2980075106060711',
      'color': const Color(0xFF4A154B),
      'guide': [
        'Buka aplikasi PermataMobile X atau ATM Permata.',
        'Pilih menu Bayar Tagihan > Virtual Account.',
        'Masukkan nomor Permata VA di atas.',
        'Konfirmasi rincian tagihan METRO INSTITUTE.',
        'Masukkan PIN transaksi Anda.',
      ],
    },
    {
      'id': 'cimb',
      'name': 'CIMB Niaga Virtual Account',
      'shortName': 'CIMB VA',
      'code': 'cimb',
      'prefix': '985',
      'defaultVa': '9857288865717735',
      'color': const Color(0xFF7D0000),
      'guide': [
        'Buka aplikasi OCTO Mobile by CIMB Niaga.',
        'Pilih menu Transfer > Rekening Ponsel / Virtual Account.',
        'Masukkan nomor Virtual Account CIMB di atas.',
        'Periksa nominal dan nama merchant METRO INSTITUTE.',
        'Konfirmasi dengan PIN OCTO Mobile.',
      ],
    },
    {
      'id': 'mandiri',
      'name': 'Mandiri Bill Payment',
      'shortName': 'Mandiri Bill',
      'code': 'mandiri',
      'prefix': '70012',
      'billerCode': '70012',
      'defaultVa': '664170613866',
      'color': const Color(0xFF003082),
      'guide': [
        'Buka aplikasi Livin\' by Mandiri.',
        'Pilih menu Bayar > Buat Pembayaran Baru > Multi Payment.',
        'Pilih Penyedia Jasa: Midtrans (Kode 70012).',
        'Masukkan No. Pelanggan / Bill Key di atas.',
        'Konfirmasi tagihan METRO INSTITUTE dan masukkan PIN Livin\'.',
      ],
    },
    {
      'id': 'danamon',
      'name': 'Danamon Virtual Account',
      'shortName': 'Danamon VA',
      'code': 'danamon',
      'prefix': '890',
      'defaultVa': '8902985712398471',
      'color': const Color(0xFFF37021),
      'guide': [
        'Buka aplikasi D-Bank PRO atau ATM Danamon.',
        'Pilih menu Pembayaran > Virtual Account.',
        'Masukkan nomor Virtual Account Danamon di atas.',
        'Pastikan data pembayaran sesuai, lalu konfirmasi dengan mPIN.',
      ],
    },
    {
      'id': 'bsi',
      'name': 'Bank Syariah Indonesia Virtual Account',
      'shortName': 'BSI VA',
      'code': 'bsi',
      'prefix': '298',
      'defaultVa': '29857141907221614',
      'color': const Color(0xFF00A39D),
      'guide': [
        'Buka aplikasi BSI Mobile.',
        'Pilih menu Bayar > Institusi / Virtual Account.',
        'Masukkan nomor Virtual Account BSI di atas.',
        'Konfirmasi tagihan METRO INSTITUTE dan masukkan PIN BSI Mobile.',
      ],
    },
    {
      'id': 'seabank',
      'name': 'SeaBank Virtual Account',
      'shortName': 'SeaBank VA',
      'code': 'seabank',
      'prefix': '782',
      'defaultVa': '7829857102938475',
      'color': const Color(0xFFFF5722),
      'guide': [
        'Buka aplikasi SeaBank.',
        'Pilih menu Bayar / Tagihan > Virtual Account.',
        'Masukkan nomor SeaBank VA di atas.',
        'Konfirmasi rincian pembayaran, lalu masukkan PIN SeaBank.',
      ],
    },
    {
      'id': 'saqu',
      'name': 'Bank Saqu Virtual Account',
      'shortName': 'Saqu VA',
      'code': 'saqu',
      'prefix': '918',
      'defaultVa': '9182985764839201',
      'color': const Color(0xFF10B981),
      'guide': [
        'Buka aplikasi Bank Saqu.',
        'Pilih menu Transfer / Pembayaran Virtual Account.',
        'Masukkan nomor Saqu VA di atas.',
        'Periksa detail tagihan METRO INSTITUTE dan masukkan PIN Saqu.',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initial debit card setup (Visa Debit default)
    final initialOption = _debitOptions[0];
    _cardNumberController.text = initialOption['number'] as String;
    _cardTypeController.text = initialOption['title'] as String;
    _expiryController.text = initialOption['expiry'] as String;
    _cvvController.text = initialOption['cvv'] as String;

    _loadUserName();
    if (widget.vaNumber != null && widget.vaNumber!.isNotEmpty) {
      _isVaGenerated = true;
      _startMidtransSettlementPolling();
    }

    _cardNumberController.addListener(() {
      final digits = _cardNumberController.text.replaceAll(' ', '');
      if (digits.startsWith('4') && _selectedDebitIndex != 0) {
        setState(() {
          _selectedDebitIndex = 0;
          _cardTypeController.text = _debitOptions[0]['title'] as String;
        });
      } else if (digits.startsWith('6') && _selectedDebitIndex != 1) {
        setState(() {
          _selectedDebitIndex = 1;
          _cardTypeController.text = _debitOptions[1]['title'] as String;
        });
      } else {
        setState(() {});
      }
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
    _cardNumberController.dispose();
    _nameController.dispose();
    _cardTypeController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();

    super.dispose();
  }

  void _selectDebitOption(int index) {
    if (index < 0 || index >= _debitOptions.length) return;
    setState(() {
      _selectedDebitIndex = index;
      final option = _debitOptions[index];
      _cardNumberController.text = option['number'] as String;
      _cardTypeController.text = option['title'] as String;
      _expiryController.text = option['expiry'] as String;
      _cvvController.text = option['cvv'] as String;
    });
  }

  void _selectVaBank(int index) {
    if (index < 0 || index >= _vaBanks.length) return;
    setState(() {
      _selectedVaBankIndex = index;
      _liveVaNumber = null;
      _liveBillKey = null;
      _liveBillerCode = null;
    });
  }

  Future<void> _fetchLiveVaNumber(String bankCode) async {
    final activeOrderId = widget.orderId.isNotEmpty
        ? widget.orderId
        : 'METRO-${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _isLoadingVa = true);
    try {
      final res = await _userDataSource.chargeVirtualAccount(
        orderId: activeOrderId,
        bank: bankCode,
      );
      if (mounted && res.isNotEmpty) {
        setState(() {
          _liveVaNumber = res['vaNumber']?.toString();
          _liveBillKey = res['billKey']?.toString();
          _liveBillerCode = res['billerCode']?.toString();
          _isLoadingVa = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingVa = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatRupiah(int amount) {
    if (amount == 0) return 'Gratis';
    final str = amount.toString();
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(regExp, (m) => '${m[1]}.')}';
  }

  void _showDebitTypePickerBottomSheet() {
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
                'Pilih Jenis Kartu Debit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Tersedia Visa (Internasional) dan GPN (Domestik Indonesia)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              ...List.generate(_debitOptions.length, (i) {
                final option = _debitOptions[i];
                final isSelected = _selectedDebitIndex == i;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _selectDebitOption(i);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.2 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          child: Image.asset(
                            option['comboboxLogoAsset'] as String,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                option['subtitle'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            option['badge'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
    } else {
      if (!_isVaGenerated) {
        _generateVirtualAccount(activeOrderId);
      } else {
        _handleCheckVaPaymentStatus(activeOrderId);
      }
    }
  }

  Future<void> _generateVirtualAccount(String activeOrderId) async {
    setState(() => _isLoading = true);
    final bank = _vaBanks[_selectedVaBankIndex];
    await _fetchLiveVaNumber(bank['code'] as String);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isVaGenerated = true;
    });
    _startMidtransSettlementPolling();
  }

  Future<void> _handleCheckVaPaymentStatus(String activeOrderId) async {
    setState(() => _isLoading = true);
    await _checkMidtransStatus();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Menunggu konfirmasi pembayaran dari bank...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── 1. 3D SECURE BANK VERIFICATION MODAL ─────────────────────────────────────
  void _show3dSecureDialog(String activeOrderId) {
    final rawNumber = _cardNumberController.text.replaceAll(' ', '');
    final last4 = rawNumber.length >= 4 ? rawNumber.substring(rawNumber.length - 4) : '3456';
    final option = _debitOptions[_selectedDebitIndex];
    final cardTitle = option['title'] as String;

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
          bankName: cardTitle,
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
    final activeOption = _debitOptions[_selectedDebitIndex];

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
                      // Single Charcoal Card with Indonesian Batik Kawung Motif
                      _buildSingleBatikDebitCard(activeOption),
                      const SizedBox(height: 18),

                      // Form Fields (Card Number, Name, Jenis Kartu, Expiry/CVV)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCardFormFields(activeOption),
                      ),
                    ] else ...[
                      // Virtual Account Content (10 Bank Sesuai Midtrans Simulator)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildVirtualAccountContent(
                          widget.orderId.isNotEmpty ? widget.orderId : 'METRO-${DateTime.now().millisecondsSinceEpoch}',
                        ),
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
                          _selectedTab == PaymentTab.card ? 'Payment' : (_isVaGenerated ? 'Cek Status Pembayaran' : 'Lanjut'),
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

  // ── 1. PAYMENT METHOD SELECTOR PILLS (KARTU DEBIT & VIRTUAL ACCOUNT) ───────
  Widget _buildPaymentSelectorPills() {
    return Row(
      children: [
        // Tab 1: Kartu Debit
        Expanded(
          child: _selectorPill(
            isSelected: _selectedTab == PaymentTab.card,
            onTap: () => setState(() => _selectedTab = PaymentTab.card),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 19,
                  color: _selectedTab == PaymentTab.card ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kartu Debit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _selectedTab == PaymentTab.card ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Tab 2: Virtual Account
        Expanded(
          child: _selectorPill(
            isSelected: _selectedTab == PaymentTab.va,
            onTap: () => setState(() => _selectedTab = PaymentTab.va),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  size: 19,
                  color: _selectedTab == PaymentTab.va ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  'Virtual Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _selectedTab == PaymentTab.va ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    letterSpacing: -0.2,
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

  // ── 1 SINGLE CARD: CHARCOAL BATIK DEBIT CARD (VISA / GPN) ───────────────────
  Widget _buildSingleBatikDebitCard(Map<String, dynamic> activeOption) {
    final isVisa = activeOption['requiresCvv'] == true;

    final displayNum = _cardNumberController.text.trim().isNotEmpty
        ? _cardNumberController.text.trim()
        : activeOption['number'] as String;

    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Daffarael Anaqi Ali';

    final displayExpiry = _expiryController.text.trim().isNotEmpty
        ? _expiryController.text.trim()
        : activeOption['expiry'] as String;

    final displayCvv = _cvvController.text.trim().isNotEmpty
        ? _cvvController.text.trim()
        : activeOption['cvv'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 194,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E323A), // Charcoal Dark
            Color(0xFF1E2127), // Slate Black
            Color(0xFF121417), // Deep Onyx
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Authentic Indonesian Batik Kawung Motif Texture
            Positioned.fill(
              child: CustomPaint(
                painter: _BatikKawungPatternPainter(),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── TOP ROW: EMV CHIP + NFC (KIRI) & ONLY OFFICIAL LOGO (KANAN) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Realistic Gold EMV Chip & Contactless
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRealisticGoldChip(),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.contactless_rounded,
                            color: Colors.white.withValues(alpha: 0.65),
                            size: 22,
                          ),
                        ],
                      ),

                      // Fixed container for the logo so height and position never shift
                      SizedBox(
                        height: 32,
                        width: 65,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: isVisa
                              ? Image.asset(
                                  'assets/images/logo_visa_white.png',
                                  height: 24,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  'assets/images/logo_gpn_darkmode.png',
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ],
                  ),

                  // ── EMBOSSED MONOSPACE CARD NUMBER ──
                  Text(
                    displayNum,
                    style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: Colors.white,
                      shadows: const [
                        Shadow(offset: Offset(0, 1.3), blurRadius: 3, color: Colors.black54),
                        Shadow(offset: Offset(0, -0.5), blurRadius: 1, color: Colors.white24),
                      ],
                    ),
                  ),

                  // ── BOTTOM ROW: CARD HOLDER & EXPIRES & (CVV IF VISA) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ── LEFT: Card Holder Name (Beri ruang luas, nama jangan disingkat) ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Card Holder',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                displayName.toUpperCase(),
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                  shadows: const [
                                    Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ── RIGHT CLUSTER: EXPIRES & CVV (Geser ke kanan, posisi stabil tanpa gerakan) ──
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Expiration Date (Geser ke kanan, posisi stabil di Visa maupun GPN)
                          SizedBox(
                            width: 52,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Expires',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayExpiry,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // CVV Slot (Posisi tetap 34px; jika Visa ada CVV, jika GPN slot transparan)
                          // Menjamin tidak ada pergeseran / gerakan apapun saat berganti Visa <-> GPN!
                          SizedBox(
                            width: 34,
                            child: Opacity(
                              opacity: isVisa ? 1.0 : 0.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CVV',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.72),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayCvv.isNotEmpty ? displayCvv : '215',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── REALISTIC GOLD EMV SMART CHIP ──────────────────────────────────────────
  Widget _buildRealisticGoldChip() {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFDF7A),
            Color(0xFFD4AF37),
            Color(0xFFAA8012),
            Color(0xFFF3E5AB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8B6914), width: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 3,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 22,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF7A5C0E), width: 0.8),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 13.5,
            child: Container(height: 0.8, color: const Color(0xFF7A5C0E)),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 18.5,
            child: Container(width: 0.8, color: const Color(0xFF7A5C0E)),
          ),
        ],
      ),
    );
  }

  // ── 3. FORM FIELDS ───────────────────────────────────────────────────────────
  Widget _buildCardFormFields(Map<String, dynamic> activeOption) {
    final bool isVisa = activeOption['requiresCvv'] == true;

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

        // ── NAME (Full width agar nama tidak kepotong sama sekali) ──
        _fieldLabel('Name'),
        const SizedBox(height: 5),
        _pillTextField(
          controller: _nameController,
          hint: 'Nama Pemegang Kartu',
        ),
        const SizedBox(height: 12),

        // ── JENIS KARTU (Full width combobox, ID Card dihapus, hanya Jenis Kartu) ──
        _fieldLabel('Jenis Kartu'),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: _showDebitTypePickerBottomSheet,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 24,
                  alignment: Alignment.center,
                  child: Image.asset(
                    activeOption['comboboxLogoAsset'] as String,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activeOption['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  ),
                  child: Text(
                    activeOption['badge'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF334155),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (isVisa) ...[
          // Visa: Expiration Date + CVV
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
        ] else ...[
          // GPN Debit: Only Expiration Date (No CVV required)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Expiration Date'),
              const SizedBox(height: 5),
              _pillTextField(
                controller: _expiryController,
                hint: '05/28',
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateInputFormatter(),
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF018556)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Kartu Debit GPN diamankan via 3D Secure OTP perbankan (tanpa kode CVV).',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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

  // ── LOGO BADGE HELPER UNTUK 10 BANK VIRTUAL ACCOUNT ─────────────────────────
  Widget _buildVaBankLogoBadge(Map<String, dynamic> bank, {double size = 26}) {
    final id = bank['id'] as String;
    switch (id) {
      case 'bca':
        return Image.asset('assets/images/logo_bca_color.png', height: 16, fit: BoxFit.contain);
      case 'bri':
        return Image.asset('assets/images/logo_bri_color.png', height: 16, fit: BoxFit.contain);
      case 'bni':
        return Image.asset('assets/images/logo_bni_color.png', height: 16, fit: BoxFit.contain);
      case 'permata':
        return Image.asset('assets/images/logo_permata_color.png', height: 16, fit: BoxFit.contain);
      case 'cimb':
        return Image.asset('assets/images/logo_cimb_color.png', height: 15, fit: BoxFit.contain);
      case 'mandiri':
        return Image.asset('assets/images/logo_mandiri_color.png', height: 16, fit: BoxFit.contain);
      case 'danamon':
        return Image.asset('assets/images/logo_danamon_color.png', height: 16, fit: BoxFit.contain);
      case 'bsi':
        return Image.asset('assets/images/logo_bsi_color.png', height: 16, fit: BoxFit.contain);
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: (bank['color'] as Color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: (bank['color'] as Color).withValues(alpha: 0.3)),
          ),
          child: Text(
            bank['shortName'].toString().split(' ')[0],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: bank['color'] as Color,
            ),
          ),
        );
    }
  }

  // ── BOTTOM SHEET PILIH BANK VIRTUAL ACCOUNT (10 BANK) ──────────────────────
  void _showVaBankPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                'Pilih Bank Virtual Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tersedia 10 Bank transfer dengan verifikasi otomatis 24 jam',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _vaBanks.length,
                  itemBuilder: (ctx, i) {
                    final bank = _vaBanks[i];
                    final isSelected = _selectedVaBankIndex == i;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _selectVaBank(i);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2.2 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              height: 32,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildVaBankLogoBadge(bank),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bank['name'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Verifikasi otomatis 24 jam',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                bank['shortName'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── VIRTUAL ACCOUNT CONTENT: STEP 1 (PILIH) & STEP 2 (DETAIL VA SETELAH LANJUT) ──
  Widget _buildVirtualAccountContent(String activeOrderId) {
    if (!_isVaGenerated) {
      return _buildVaSelectionView(activeOrderId);
    } else {
      return _buildVaDetailView(activeOrderId);
    }
  }

  // ── STEP 1: PEMILIHAN BANK VIRTUAL ACCOUNT (SEBELUM KLIK LANJUT) ───────────
  Widget _buildVaSelectionView(String activeOrderId) {
    final activeBank = _vaBanks[_selectedVaBankIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Pilih Bank Virtual Account'),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: _showVaBankPickerBottomSheet,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.3),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildVaBankLogoBadge(activeBank),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeBank['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── RINGKASAN PEMBAYARAN ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Metode Pembayaran',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    activeBank['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Biaya Layanan',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    'Gratis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
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
                    _formatRupiah(widget.amount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF018556),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Hint Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nomor Virtual Account resmi akan dibuat setelah Anda menekan tombol Lanjut di bawah.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 2: DETAIL VIRTUAL ACCOUNT (SETELAH KLIK LANJUT) ───────────────────
  Widget _buildVaDetailView(String activeOrderId) {
    final activeBank = _vaBanks[_selectedVaBankIndex];
    final isMandiri = activeBank['id'] == 'mandiri';

    final displayVaNumber = _liveVaNumber ??
        (widget.vaNumber?.isNotEmpty == true ? widget.vaNumber! : activeBank['defaultVa'] as String);
    final displayBillerCode = _liveBillerCode ?? activeBank['billerCode']?.toString() ?? '70012';
    final displayBillKey = _liveBillKey ?? _liveVaNumber ?? activeBank['defaultVa'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Menunggu Pembayaran
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menunggu Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      'Silakan transfer ke nomor Virtual Account di bawah.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── KARTU DETAIL VIRTUAL ACCOUNT ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Kartu
              Row(
                children: [
                  _buildVaBankLogoBadge(activeBank),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeBank['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      'OTOMATIS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF047857),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // Nomor Virtual Account / Mandiri Bill
              if (isMandiri) ...[
                Text(
                  'Kode Perusahaan',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayBillerCode,
                      style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    _copyButton(() => _copyToClipboard(displayBillerCode, 'Kode Perusahaan')),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  'No. Pelanggan / Bill Key',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayBillKey,
                      style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    _copyButton(() => _copyToClipboard(displayBillKey, 'No. Pelanggan Mandiri')),
                  ],
                ),
              ] else ...[
                Text(
                  'Nomor Virtual Account',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _isLoadingVa
                          ? const Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                              ),
                            )
                          : Text(
                              displayVaNumber,
                              style: GoogleFonts.spaceMono(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    _copyButton(() => _copyToClipboard(displayVaNumber, 'Nomor Virtual Account')),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Total Pembayaran (TANPA TOMBOL SALIN)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatRupiah(widget.amount),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF018556),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Batas Waktu
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'Batas Waktu: 24 Jam setelah pemesanan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── PETUNJUK CARA TRANSFER ACCORDION ─────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'Petunjuk Cara Pembayaran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: List.generate(
                      (activeBank['guide'] as List<String>).length,
                      (idx) {
                        final stepText = (activeBank['guide'] as List<String>)[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  stepText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── TOMBOL GANTI METODE / BANK ───────────────────────────────────────
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _isVaGenerated = false),
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
            label: Text(
              'Ganti Bank / Metode Pembayaran',
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

  Widget _copyButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF334155)),
            const SizedBox(width: 4),
            Text(
              'Salin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
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
  final String bankName;
  final VoidCallback onVerified;

  const _OtpVerificationSheet({
    required this.orderId,
    required this.amountText,
    required this.cardTitle,
    required this.last4Digits,
    required this.bankName,
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

// ── AUTHENTIC INDONESIAN BATIK KAWUNG PATTERN PAINTER ─────────────────────────
class _BatikKawungPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final petalPaint = Paint()
      ..color = const Color(0xFFE5E7EB).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double step = 42.0;
    const double petalRadius = 15.0;

    for (double x = 0; x <= size.width + step; x += step) {
      for (double y = 0; y <= size.height + step; y += step) {
        // Center ring & jewel dot
        canvas.drawCircle(Offset(x, y), 3.2, ringPaint);
        canvas.drawCircle(Offset(x, y), 1.4, dotPaint);

        // 4 elliptical petals of Kawung
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x - petalRadius / 2, y), width: petalRadius * 1.35, height: petalRadius * 0.72),
          petalPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + petalRadius / 2, y), width: petalRadius * 1.35, height: petalRadius * 0.72),
          petalPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y - petalRadius / 2), width: petalRadius * 0.72, height: petalRadius * 1.35),
          petalPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y + petalRadius / 2), width: petalRadius * 0.72, height: petalRadius * 1.35),
          petalPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
