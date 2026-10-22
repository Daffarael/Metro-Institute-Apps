import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class UserRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getXpLogs({int page = 1, int limit = 20});
  Future<List<dynamic>> getTransactions();
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<Map<String, dynamic>> initiateTransaction({
    required String productType,
    String? courseId,
    String? bootcampId,
    String? webinarId,
    String? paymentMethod,
  });
  Future<Map<String, dynamic>> verifyTransaction(String orderId);
  Future<Map<String, dynamic>> simulateTransaction(String orderId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio dio;

  UserRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await dio.get('/users/me');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat profil pengguna';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat profil: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await dio.patch('/users/me', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memperbarui profil';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan update profil: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getXpLogs({int page = 1, int limit = 20}) async {
    try {
      final response = await dio.get(
        '/users/me/xp-logs',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat riwayat XP';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat riwayat XP: $e');
    }
  }

  @override
  Future<List<dynamic>> getTransactions() async {
    try {
      final response = await dio.get('/transactions');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat riwayat transaksi';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat transaksi: $e');
    }
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await dio.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengubah password';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan ubah password: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> initiateTransaction({
    required String productType,
    String? courseId,
    String? bootcampId,
    String? webinarId,
    String? paymentMethod,
  }) async {
    try {
      final Map<String, dynamic> body = {'productType': productType};
      if (courseId != null) body['courseId'] = courseId;
      if (bootcampId != null) body['bootcampId'] = bootcampId;
      if (webinarId != null) body['webinarId'] = webinarId;
      if (paymentMethod != null && paymentMethod != 'ALL') body['paymentMethod'] = paymentMethod;

      final response = await dio.post(
        '/transactions/initiate',
        data: body,
      );
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal membuat transaksi';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan checkout: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyTransaction(String orderId) async {
    try {
      final response = await dio.post('/transactions/$orderId/verify');
      return (response.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memverifikasi status pembayaran';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan verifikasi: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> simulateTransaction(String orderId) async {
    try {
      final response = await dio.post('/transactions/$orderId/simulate');
      return (response.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal simulasi pembayaran';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan simulasi: $e');
    }
  }
}
