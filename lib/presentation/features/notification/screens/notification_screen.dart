import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/remote/notification_remote_datasource.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  static void clearCache() => _NotificationScreenState.clearCache();

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notifDs = sl<NotificationRemoteDataSource>();

  static List<dynamic>? _cachedNotifications;
  static void clearCache() => _cachedNotifications = null;
  late bool _isLoading = _cachedNotifications == null;
  List<dynamic> _notifications = _cachedNotifications ?? [];
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_cachedNotifications == null) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await _notifDs.getNotifications(unreadOnly: _unreadOnly);
      final list = (res['data'] as List?) ?? [];
      _cachedNotifications = list;
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _notifDs.markAllRead();
      _loadNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca.')),
      );
    } catch (_) {}
  }

  Future<void> _markRead(String id, int idx) async {
    try {
      await _notifDs.markRead(id);
      if (!mounted) return;
      setState(() {
        if (idx < _notifications.length) {
          _notifications[idx]['isRead'] = true;
        }
      });
    } catch (_) {}
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'LIVE_SESSION':
      case 'WEBINAR':
        return Icons.videocam_rounded;
      case 'XP_EARNED':
      case 'STREAK':
        return Icons.bolt_rounded;
      case 'ASSIGNMENT':
        return Icons.assignment_rounded;
      case 'ENROLLMENT':
      case 'CERTIFICATE':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'LIVE_SESSION':
      case 'WEBINAR':
        return const Color(0xFFEF4444);
      case 'XP_EARNED':
      case 'STREAK':
        return const Color(0xFFF59E0B);
      case 'ASSIGNMENT':
        return AppColors.primary;
      case 'ENROLLMENT':
      case 'CERTIFICATE':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pusat Notifikasi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'Baca Semua',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                FilterChip(
                  selected: !_unreadOnly,
                  label: const Text('Semua'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: !_unreadOnly ? FontWeight.w700 : FontWeight.w500,
                    color: !_unreadOnly ? AppColors.primary : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: !_unreadOnly ? AppColors.primary : AppColors.border),
                  ),
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _unreadOnly = false);
                    _loadNotifications();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _unreadOnly,
                  label: const Text('Belum Dibaca'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: _unreadOnly ? FontWeight.w700 : FontWeight.w500,
                    color: _unreadOnly ? AppColors.primary : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: _unreadOnly ? AppColors.primary : AppColors.border),
                  ),
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _unreadOnly = true);
                    _loadNotifications();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadNotifications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _notifications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 14),
                                const Text('Tidak Ada Notifikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pemberitahuan terkait kelas, tugas, dan live session Anda akan muncul di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _notifications.length,
                          itemBuilder: (ctx, idx) {
                            final n = _notifications[idx] as Map<String, dynamic>;
                            final id = n['id']?.toString() ?? '';
                            final type = n['type']?.toString();
                            final title = n['title'] ?? 'Pemberitahuan';
                            final body = n['body'] ?? '';
                            final isRead = n['isRead'] == true;
                            final timeStr = _formatTime(n['createdAt']);
                            final icon = _iconForType(type);
                            final iconColor = _colorForType(type);

                            return GestureDetector(
                              onTap: () {
                                if (!isRead) _markRead(id, idx);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead ? AppColors.surface : AppColors.primaryLight.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: iconColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(child: Icon(icon, color: iconColor, size: 20)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            body,
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                          ),
                                        ],
                                      ),
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
