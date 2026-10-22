import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class CertificateRemoteDataSource {
  Future<List<dynamic>> getCertificates();
  Future<Map<String, dynamic>> getCertificateDetail(String credentialId);
}

class CertificateRemoteDataSourceImpl implements CertificateRemoteDataSource {
  final Dio dio;

  CertificateRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<List<dynamic>> getCertificates() async {
    try {
      final response = await dio.get('/certificates');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat daftar sertifikat';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat sertifikat: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCertificateDetail(String credentialId) async {
    try {
      final response = await dio.get('/certificates/verify/$credentialId');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Sertifikat tidak ditemukan';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal membuka sertifikat: $e');
    }
  }
}
