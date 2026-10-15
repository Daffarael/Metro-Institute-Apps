import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

/// init — registers all dependencies (repositories, use cases, blocs, services).
/// Called once in main.dart before runApp().
Future<void> init() async {
  // ── Services ──────────────────────────────────────────────────────────────
  // sl.registerLazySingleton<AuthService>(() => AuthServiceImpl());
  // sl.registerLazySingleton<TokenService>(() => TokenService(sl()));

  // ── Data Sources ──────────────────────────────────────────────────────────
  // sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  // sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));

  // ── Repositories ──────────────────────────────────────────────────────────
  // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));

  // ── Use Cases ─────────────────────────────────────────────────────────────
  // sl.registerLazySingleton(() => LoginUseCase(sl()));

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  // sl.registerFactory(() => AuthBloc(loginUseCase: sl(), logoutUseCase: sl()));
}
