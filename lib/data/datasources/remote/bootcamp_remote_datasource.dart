import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class BootcampRemoteDataSource {
  Future<List<dynamic>> getBootcamps({String? search, String? field, String? status});
  Future<List<dynamic>> getEnrolledBootcamps();
  Future<Map<String, dynamic>> getBootcampDetail(String id);
  Future<Map<String, dynamic>> getBootcampSession(String bootcampId, String sessionId);
  Future<Map<String, dynamic>> completeBootcampSession(String bootcampId, String sessionId);
}

class BootcampRemoteDataSourceImpl implements BootcampRemoteDataSource {
  final Dio dio;

  BootcampRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<List<dynamic>> getBootcamps({String? search, String? field, String? status}) async {
    try {
      final qParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) qParams['search'] = search;
      if (field != null && field.isNotEmpty && field != 'ALL') qParams['field'] = field;
      if (status != null && status.isNotEmpty) qParams['status'] = status;

      final response = await dio.get('/bootcamps', queryParameters: qParams);
      return (response.data['data'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat katalog bootcamp';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat bootcamp: $e');
    }
  }

  @override
  Future<List<dynamic>> getEnrolledBootcamps() async {
    try {
      final response = await dio.get('/bootcamps/enrolled');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat bootcamp saya';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat bootcamp saya: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getBootcampDetail(String id) async {
    try {
      final response = await dio.get('/bootcamps/$id');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat detail bootcamp';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat detail bootcamp: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getBootcampSession(String bootcampId, String sessionId) async {
    try {
      final response = await dio.get('/bootcamps/$bootcampId/learn/$sessionId');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat sesi bootcamp';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat sesi bootcamp: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> completeBootcampSession(String bootcampId, String sessionId) async {
    try {
      final response = await dio.post('/bootcamps/$bootcampId/sessions/$sessionId/complete');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menyelesaikan sesi bootcamp';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal mencatat progres bootcamp: $e');
    }
  }
}
