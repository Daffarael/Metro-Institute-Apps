import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class CourseRemoteDataSource {
  Future<List<dynamic>> getCourses({String? field, String? level});
  Future<List<dynamic>> getEnrolledCourses();
  Future<Map<String, dynamic>> getCourseDetail(String id);
  Future<Map<String, dynamic>> getCourseSession(String courseId, String sessionId);
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final Dio dio;

  CourseRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<List<dynamic>> getCourses({String? field, String? level}) async {
    try {
      final params = <String, dynamic>{};
      if (field != null && field != 'ALL') params['field'] = field;
      if (level != null && level != 'ALL') params['level'] = level;

      final response = await dio.get('/courses', queryParameters: params);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat daftar kursus';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat kursus: $e');
    }
  }

  @override
  Future<List<dynamic>> getEnrolledCourses() async {
    try {
      final response = await dio.get('/courses/enrolled');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat kelas terdaftar';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat kelas aktif: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCourseDetail(String id) async {
    try {
      final response = await dio.get('/courses/$id');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat detail kursus';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal membuka kursus: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCourseSession(String courseId, String sessionId) async {
    try {
      final response = await dio.get('/courses/$courseId/sessions/$sessionId');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat video materi';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal membuka sesi video: $e');
    }
  }
}
