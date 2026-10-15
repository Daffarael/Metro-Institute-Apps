import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<UserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      return {
        'accessToken': accessToken,
        'user': user,
      };
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Login gagal. Periksa email & password Anda.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Pendaftaran gagal. Silakan coba lagi.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan saat registrasi: $e');
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await dio.get('/users/me');
      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengambil data profil';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal memuat profil: $e');
    }
  }
}
