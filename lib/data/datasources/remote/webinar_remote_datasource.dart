import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class WebinarRemoteDataSource {
  Future<List<dynamic>> getWebinars({String? search, String? field, String? status});
  Future<List<dynamic>> getMyWebinars();
  Future<Map<String, dynamic>> registerWebinar(String id);
  Future<Map<String, dynamic>> attendWebinar(String id, {String? feedback});
}

class WebinarRemoteDataSourceImpl implements WebinarRemoteDataSource {
  final Dio dio;

  WebinarRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<List<dynamic>> getWebinars({String? search, String? field, String? status}) async {
    try {
      final qParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) qParams['search'] = search;
      if (field != null && field.isNotEmpty && field != 'ALL') qParams['field'] = field;
      if (status != null && status.isNotEmpty) qParams['status'] = status;

      final response = await dio.get('/webinars', queryParameters: qParams);
      return (response.data['data'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat jadwal webinar';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat webinar: $e');
    }
  }

  @override
  Future<List<dynamic>> getMyWebinars() async {
    try {
      final response = await dio.get('/webinars/my/registered');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat webinar terdaftar';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat webinar saya: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> registerWebinar(String id) async {
    try {
      final response = await dio.post('/webinars/$id/register');
      return (response.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mendaftar webinar';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan saat pendaftaran: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> attendWebinar(String id, {String? feedback}) async {
    try {
      final response = await dio.post(
        '/webinars/$id/attend',
        data: {'feedback': feedback ?? 'Hadir mengikuti sesi webinar'},
      );
      return (response.data as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengisi presensi webinar';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan presensi: $e');
    }
  }
}
