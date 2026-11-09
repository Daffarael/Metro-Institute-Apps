import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class BasecampRemoteDataSource {
  Future<Map<String, dynamic>> getBasecampData();
  Future<Map<String, dynamic>> getTimelineData();
}

class BasecampRemoteDataSourceImpl implements BasecampRemoteDataSource {
  final Dio dio;

  BasecampRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<Map<String, dynamic>> getBasecampData() async {
    try {
      final response = await dio.get('/users/basecamp');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat data Basecamp';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat dashboard: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTimelineData() async {
    try {
      final response = await dio.get('/users/timeline');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat data Timeline';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat timeline: $e');
    }
  }
}
