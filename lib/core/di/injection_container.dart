import 'package:get_it/get_it.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/basecamp_remote_datasource.dart';
import '../../data/datasources/remote/bootcamp_remote_datasource.dart';
import '../../data/datasources/remote/certificate_remote_datasource.dart';
import '../../data/datasources/remote/challenge_remote_datasource.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/datasources/remote/leaderboard_remote_datasource.dart';
import '../../data/datasources/remote/notification_remote_datasource.dart';
import '../../data/datasources/remote/skill_test_remote_datasource.dart';
import '../../data/datasources/remote/user_remote_datasource.dart';
import '../../data/datasources/remote/webinar_remote_datasource.dart';
import '../../data/datasources/remote/wishlist_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  if (sl.isRegistered<AuthRemoteDataSource>()) {
    await sl.reset();
  }

  // ── Data Sources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<BasecampRemoteDataSource>(() => BasecampRemoteDataSourceImpl());
  sl.registerLazySingleton<CourseRemoteDataSource>(() => CourseRemoteDataSourceImpl());
  sl.registerLazySingleton<BootcampRemoteDataSource>(() => BootcampRemoteDataSourceImpl());
  sl.registerLazySingleton<WebinarRemoteDataSource>(() => WebinarRemoteDataSourceImpl());
  sl.registerLazySingleton<ChallengeRemoteDataSource>(() => ChallengeRemoteDataSourceImpl());
  sl.registerLazySingleton<CertificateRemoteDataSource>(() => CertificateRemoteDataSourceImpl());
  sl.registerLazySingleton<NotificationRemoteDataSource>(() => NotificationRemoteDataSourceImpl());
  sl.registerLazySingleton<UserRemoteDataSource>(() => UserRemoteDataSourceImpl());
  sl.registerLazySingleton<SkillTestRemoteDataSource>(() => SkillTestRemoteDataSourceImpl());
  sl.registerLazySingleton<LeaderboardRemoteDataSource>(() => LeaderboardRemoteDataSourceImpl());
  sl.registerLazySingleton<WishlistRemoteDataSource>(() => WishlistRemoteDataSourceImpl());

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl()));
}
