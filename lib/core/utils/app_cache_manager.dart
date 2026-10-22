import '../../presentation/features/basecamp/screens/basecamp_screen.dart';
import '../../presentation/features/learn/screens/learn_screen.dart';
import '../../presentation/features/challenge/screens/challenge_screen.dart';
import '../../presentation/features/certificate/screens/certificate_screen.dart';
import '../../presentation/features/profile/screens/profile_screen.dart';
import '../../presentation/features/profile/screens/transactions_screen.dart';
import '../../presentation/features/notification/screens/notification_screen.dart';

/// AppCacheManager — central utility to purge in-memory UI caches.
/// Ensures that when a mentee logs in/out, switches accounts, or syncs from
/// web, stale cached data from another session or device is eliminated.
class AppCacheManager {
  AppCacheManager._();

  static void clearAll() {
    BasecampScreen.clearCache();
    LearnScreen.clearCache();
    ChallengeScreen.clearCache();
    CertificateScreen.clearCache();
    ProfileScreen.clearCache();
    TransactionsScreen.clearCache();
    NotificationScreen.clearCache();
  }
}
