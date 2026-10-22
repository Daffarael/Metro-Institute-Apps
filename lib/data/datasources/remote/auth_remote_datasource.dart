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
  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    String? name,
    String? googleId,
    String? photoUrl,
    String? idToken,
  });
  Future<UserModel> updateProfile({String? name, String? phone});
  Future<void> verifyEmail({required String email, required String code});
  Future<void> resendVerify({required String email});
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
  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    String? name,
    String? googleId,
    String? photoUrl,
    String? idToken,
  }) async {
    try {
      final response = await dio.post(
        '/auth/google/mobile',
        data: {
          'email': email.trim(),
          if (name != null) 'name': name.trim(),
          if (googleId != null) 'googleId': googleId.trim(),
          if (photoUrl != null) 'photoUrl': photoUrl.trim(),
          if (idToken != null) 'idToken': idToken.trim(),
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
      final msg = e.response?.data?['message'] ?? 'Login Google gagal. Silakan coba lagi.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan saat login dengan Google: $e');
    }
  }

  @override
  Future<UserModel> updateProfile({String? name, String? phone}) async {
    try {
      final response = await dio.patch(
        '/users/me',
        data: {
          if (name != null) 'name': name.trim(),
          if (phone != null) 'phone': phone.trim(),
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memperbarui profil pengguna';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memperbarui profil: $e');
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
  Future<void> verifyEmail({required String email, required String code}) async {
    try {
      await dio.post(
        '/auth/verify-email',
        data: {
          'email': email.trim(),
          'code': code.trim(),
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Kode OTP salah atau sudah kedaluwarsa';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan verifikasi email: $e');
    }
  }

  @override
  Future<void> resendVerify({required String email}) async {
    try {
      await dio.post(
        '/auth/resend-verify',
        data: {
          'email': email.trim(),
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengirim ulang OTP';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan kirim ulang OTP: $e');
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
