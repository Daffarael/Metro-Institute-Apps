import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class CourseRemoteDataSource {
  Future<List<dynamic>> getCourses({String? field, String? level});
  Future<List<dynamic>> getEnrolledCourses();
  Future<Map<String, dynamic>> getCourseDetail(String id);
  Future<Map<String, dynamic>> getCourseSession(String courseId, String sessionId);
  Future<Map<String, dynamic>> completeCourseSession(String courseId, String sessionId);
  Future<List<dynamic>> getSessionNotes(String courseId, String sessionId);
  Future<Map<String, dynamic>> createSessionNote(String courseId, String sessionId, String content, {int? timestampSec});
  Future<List<dynamic>> getSessionQna(String courseId, String sessionId);
  Future<Map<String, dynamic>> createSessionQna(String courseId, String sessionId, String content);
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
      final response = await dio.get('/courses/$courseId/learn/$sessionId');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat materi sesi';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal membuka materi sesi: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> completeCourseSession(String courseId, String sessionId) async {
    try {
      final response = await dio.post('/courses/$courseId/sessions/$sessionId/complete');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menyelesaikan sesi kursus';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal mencatat progres: $e');
    }
  }

  @override
  Future<List<dynamic>> getSessionNotes(String courseId, String sessionId) async {
    try {
      final response = await dio.get('/courses/$courseId/sessions/$sessionId/notes');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> createSessionNote(String courseId, String sessionId, String content, {int? timestampSec}) async {
    try {
      final body = <String, dynamic>{'content': content};
      if (timestampSec != null) body['timestampSec'] = timestampSec;
      final response = await dio.post(
        '/courses/$courseId/sessions/$sessionId/notes',
        data: body,
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menyimpan catatan';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal membuat catatan: $e');
    }
  }

  @override
  Future<List<dynamic>> getSessionQna(String courseId, String sessionId) async {
    try {
      final response = await dio.get('/courses/$courseId/sessions/$sessionId/qna');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> createSessionQna(String courseId, String sessionId, String content) async {
    try {
      final response = await dio.post(
        '/courses/$courseId/sessions/$sessionId/qna',
        data: {'content': content},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengirim pertanyaan';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal membuat diskusi: $e');
    }
  }
}
