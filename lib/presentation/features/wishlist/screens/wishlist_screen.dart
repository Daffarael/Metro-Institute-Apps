import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/wishlist_remote_datasource.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _ds = sl<WishlistRemoteDataSource>();
  bool _isLoading = true;
  List<dynamic> _items = [];

  static const Map<String, String> _fieldLabels = {
    'UI_UX':    'UI/UX Design',
    'FRONTEND': 'Frontend Dev',
    'BACKEND':  'Backend Dev',
    'MOBILE':   'Mobile Dev',
  };

  static const Map<String, Color> _fieldColors = {
    'UI_UX':    Color(0xFF8B5CF6),
    'FRONTEND': Color(0xFF0F172A),
    'BACKEND':  Color(0xFF334155),
    'MOBILE':   Color(0xFFF59E0B),
  };

  static const Map<String, String> _fieldEmojis = {
    'UI_UX':    '🎨',
    'FRONTEND': '💻',
    'BACKEND':  '⚙️',
    'MOBILE':   '📱',
  };

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    try {
      final items = await _ds.getWishlist();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _remove(dynamic item) async {
    final isBootcamp = item['productType'] == 'BOOTCAMP';
    final course = item['course'] as Map<String, dynamic>?;
    final bootcamp = item['bootcamp'] as Map<String, dynamic>?;
    final String? id = isBootcamp ? (bootcamp?['id'] as String?) : (course?['id'] as String?);

    if (id == null) return;

    // Optimistic remove
    setState(() => _items.removeWhere((i) => i['id'] == item['id']));

    try {
      await _ds.removeFromWishlist(
        courseId: isBootcamp ? null : id,
        bootcampId: isBootcamp ? id : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dihapus dari wishlist', style: GoogleFonts.inter()),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (_) {
      // Revert on failure
      await _loadWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Wishlist ❤️',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadWishlist,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, i) => _WishlistCard(
                      item: _items[i],
                      fieldLabels: _fieldLabels,
                      fieldColors: _fieldColors,
                      fieldEmojis: _fieldEmojis,
                      onRemove: () => _remove(_items[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, idx) => Container(
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('❤️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Wishlist masih kosong',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Simpan bootcamp atau mini course yang kamu inginkan untuk akses cepat nanti.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wishlist Card ─────────────────────────────────────────────────────────────
class _WishlistCard extends StatelessWidget {
  final dynamic item;
  final Map<String, String> fieldLabels;
  final Map<String, Color> fieldColors;
  final Map<String, String> fieldEmojis;
  final VoidCallback onRemove;

  const _WishlistCard({
    required this.item,
    required this.fieldLabels,
    required this.fieldColors,
    required this.fieldEmojis,
    required this.onRemove,
  });

  String _formatRupiah(dynamic price) {
    final n = (price as num?)?.toInt() ?? 0;
    if (n == 0) return 'Gratis';
    final str = n.toString();
    final buf = StringBuffer('Rp ');
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(str[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final isBootcamp = item['productType'] == 'BOOTCAMP';
    final product = (isBootcamp ? item['bootcamp'] : item['course']) as Map<String, dynamic>?;
    if (product == null) return const SizedBox.shrink();

    final field = product['field'] as String? ?? '';
    final fieldColor = fieldColors[field] ?? AppColors.primary;
    final title = product['title'] as String? ?? '';
    final price = product['price'];
    final rating = (product['rating'] as num?)?.toDouble() ?? 0.0;
    final thumbnailUrl = product['thumbnailUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: fieldColor.withValues(alpha: 0.12),
                  alignment: Alignment.center,
                  child: thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: (ctx, err, stack) => Text(
                            fieldEmojis[field] ?? '📚',
                            style: const TextStyle(fontSize: 32),
                          ),
                        )
                      : Text(fieldEmojis[field] ?? '📚', style: const TextStyle(fontSize: 32)),
                ),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isBootcamp ? 'Bootcamp' : 'Mini Course',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldLabels[field]?.split(' ').first ?? field,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fieldColor),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _formatRupiah(price),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
