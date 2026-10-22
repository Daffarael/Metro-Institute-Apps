import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/user_remote_datasource.dart';
import '../../learn/widgets/thermal_receipt_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  static void clearCache() => _TransactionsScreenState.clearCache();

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final UserRemoteDataSource _userDataSource = sl<UserRemoteDataSource>();

  static List<dynamic>? _cachedTransactions;
  static void clearCache() => _cachedTransactions = null;
  late bool _isLoading = _cachedTransactions == null;
  String? _errorMessage;
  List<dynamic> _transactions = _cachedTransactions ?? [];
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Berhasil', 'Menunggu', 'Dibatalkan'];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (_cachedTransactions == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _userDataSource.getTransactions();
      _cachedTransactions = data;
      if (!mounted) return;
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_cachedTransactions == null) {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredTransactions {
    if (_selectedFilter == 'Semua') return _transactions;
    return _transactions.where((tx) {
      final status = (tx['status'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'Berhasil') {
        return status == 'SUCCESS' || status == 'PAID' || status == 'SETTLED';
      } else if (_selectedFilter == 'Menunggu') {
        return status == 'PENDING';
      } else if (_selectedFilter == 'Dibatalkan') {
        return status == 'FAILED' || status == 'CANCELLED' || status == 'EXPIRED';
      }
      return true;
    }).toList();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final numVal = num.tryParse(amount.toString()) ?? 0;
    final str = numVal.toStringAsFixed(0);
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(regExp, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute WIB';
    } catch (_) {
      return dateStr.toString();
    }
  }

  (Color bg, Color text, String label) _getStatusBadge(String? rawStatus) {
    final status = (rawStatus ?? '').toUpperCase();
    switch (status) {
      case 'SUCCESS':
      case 'PAID':
      case 'SETTLED':
        return (AppColors.successBg, AppColors.success, 'Berhasil');
      case 'PENDING':
        return (AppColors.warningBg, AppColors.warning, 'Menunggu Pembayaran');
      case 'FAILED':
      case 'CANCELLED':
      case 'EXPIRED':
        return (AppColors.errorBg, AppColors.error, 'Dibatalkan');
      default:
        return (AppColors.backgroundSubtle, AppColors.textSecondary, status);
    }
  }

  void _showTransactionDetail(Map<String, dynamic> tx) {
    final statusInfo = _getStatusBadge(tx['status']);
    final orderId = tx['orderId'] ?? tx['id'] ?? '-';
    final amount = _formatCurrency(tx['grossAmount'] ?? tx['amount']);
    final createdAt = _formatDate(tx['createdAt']);
    final paymentType = tx['paymentType'] ?? tx['paymentMethod'] ?? 'Midtrans';
    final items = tx['items'] ?? tx['metadata']?['items'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusInfo.$1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusInfo.$3,
                    style: TextStyle(
                      color: statusInfo.$2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _detailRow('ID Pesanan', orderId.toString()),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _detailRow('Tanggal', createdAt),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _detailRow('Metode Pembayaran', paymentType.toString().toUpperCase()),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _detailRow('Total Tagihan', amount, isHighlight: true),
                ],
              ),
            ),
            if (items is List && items.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Item Pembelian',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ...items.map((item) {
                final name = item['name'] ?? item['title'] ?? 'Program Pelatihan';
                final price = _formatCurrency(item['price']);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name.toString(),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            if (statusInfo.$3 == 'Berhasil') ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final itemTitle = (items is List && items.isNotEmpty)
                      ? (items.first['name'] ?? items.first['title'] ?? tx['title'] ?? 'Program Pelatihan')
                      : (tx['title'] ?? 'Program Pelatihan');
                  final numVal = (tx['grossAmount'] ?? tx['amount'] as num?)?.toInt() ?? 0;
                  ThermalReceiptDialog.show(
                    context,
                    orderId: orderId.toString(),
                    title: itemTitle.toString(),
                    amount: numVal,
                    productType: tx['productType']?.toString() ?? 'MINI_COURSE',
                    onStartLearning: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.learn);
                    },
                    onViewTransactions: () {
                      Navigator.pop(context);
                    },
                  );
                },
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Cetak / Lihat Struk Digital', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1117),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isHighlight ? 15 : 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      backgroundColor: AppColors.background,
                      selectedColor: AppColors.primary,
                      showCheckmark: false,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Transaction List or States
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchTransactions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredTransactions.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _fetchTransactions,
                            color: AppColors.primary,
                            child: ListView(
                              padding: const EdgeInsets.all(32),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                const Icon(Icons.receipt_outlined, size: 64, color: AppColors.textTertiary),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum Ada Transaksi',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Transaksi kursus, bootcamp, atau webinar Anda akan tampil di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchTransactions,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTransactions.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final tx = _filteredTransactions[index] as Map<String, dynamic>;
                                final orderId = tx['orderId'] ?? tx['id'] ?? 'INV';
                                final amount = _formatCurrency(tx['grossAmount'] ?? tx['amount']);
                                final date = _formatDate(tx['createdAt']);
                                final statusInfo = _getStatusBadge(tx['status']);
                                final title = tx['course']?['title'] ??
                                    tx['bootcamp']?['title'] ??
                                    tx['webinar']?['title'] ??
                                    tx['metadata']?['title'] ??
                                    'Pelatihan Metro Institute';

                                return InkWell(
                                  onTap: () => _showTransactionDetail(tx),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0A000000),
                                          blurRadius: 18,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.receipt_outlined, size: 12, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    orderId.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF475569),
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusInfo.$1,
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Text(
                                                statusInfo.$3,
                                                style: TextStyle(
                                                  color: statusInfo.$2,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          title.toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textTertiary),
                                            const SizedBox(width: 4),
                                            Text(
                                              date,
                                              style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 22, color: Color(0xFFE2E8F0)),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Pembayaran',
                                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              amount,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
