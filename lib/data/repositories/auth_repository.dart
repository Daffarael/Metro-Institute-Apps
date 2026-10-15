import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<void> register(String name, String email, String phone, String password);
  Future<UserModel?> getSavedUser();
  Future<bool> isLoggedIn();
  Future<UserModel> refreshProfile();
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;

  static const String _keySavedUser = 'saved_user_profile';

  AuthRepositoryImpl({
    required this.remoteDataSource,
    FlutterSecureStorage? storage,
  }) : secureStorage = storage ?? const FlutterSecureStorage();

  @override
  Future<UserModel> login(String email, String password) async {
    final result = await remoteDataSource.login(email: email, password: password);
    final token = result['accessToken'] as String;
    final user = result['user'] as UserModel;

    // Save token securely
    await secureStorage.write(key: AppConstants.keyAccessToken, value: token);
    await secureStorage.write(key: AppConstants.keyUserId, value: user.id);

    // Save user profile locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedUser, jsonEncode(user.toJson()));

    return user;
  }

  @override
  Future<void> register(String name, String email, String phone, String password) async {
    await remoteDataSource.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  @override
  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySavedUser);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await secureStorage.read(key: AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserModel> refreshProfile() async {
    final user = await remoteDataSource.getMe();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedUser, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: AppConstants.keyAccessToken);
    await secureStorage.delete(key: AppConstants.keyRefreshToken);
    await secureStorage.delete(key: AppConstants.keyUserId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedUser);
  }
}
