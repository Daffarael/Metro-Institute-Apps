import 'package:intl/intl.dart';

/// AppFormatters — utility functions for displaying formatted values in UI.
class AppFormatters {
  AppFormatters._();

  /// Format number as Indonesian Rupiah
  /// e.g. 150000 → "Rp 150.000"
  static String currency(num amount) {
    if (amount == 0) return 'GRATIS';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  /// Format XP with dot separator
  /// e.g. 1240 → "1.240 XP"
  static String xp(int xp) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return '${formatter.format(xp)} XP';
  }

  /// Format date as "15 Oktober 2026"
  static String dateIndo(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id').format(date);
  }

  /// Format date as "15 Okt 2026"
  static String dateShort(DateTime date) {
    return DateFormat('d MMM yyyy', 'id').format(date);
  }

  /// Duration in minutes → "1j 23m" or "45 menit"
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes menit';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}j' : '${h}j ${m}m';
  }

  /// Progress fraction → "75%"
  static String percentage(double value) {
    return '${(value * 100).toInt()}%';
  }

  /// Badge label from enum string
  static String badgeLabel(String badge) {
    return badge.replaceAll('METRO_', 'Metro ').replaceAll('_', ' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String text, {int maxLength = 40}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
