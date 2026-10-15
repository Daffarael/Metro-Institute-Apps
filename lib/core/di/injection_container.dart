import 'package:get_it/get_it.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/basecamp_remote_datasource.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';

final sl = GetIt.instance;

/// init — registers all dependencies (repositories, use cases, blocs, services).
/// Called once in main.dart before runApp().
Future<void> init() async {
  // ── Data Sources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<BasecampRemoteDataSource>(() => BasecampRemoteDataSourceImpl());
  sl.registerLazySingleton<CourseRemoteDataSource>(() => CourseRemoteDataSourceImpl());

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl()));
}
