import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class SkillTestRemoteDataSource {
  Future<List<dynamic>> getQuestions();
  Future<Map<String, dynamic>> submitAnswers(Map<String, String> answers);
  Future<Map<String, dynamic>> getResult();
}

class SkillTestRemoteDataSourceImpl implements SkillTestRemoteDataSource {
  final Dio dio;

  SkillTestRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<List<dynamic>> getQuestions() async {
    try {
      final response = await dio.get('/skill-test/questions');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat soal tes minat';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat soal: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> submitAnswers(Map<String, String> answers) async {
    try {
      final response = await dio.post(
        '/skill-test/submit',
        data: {'answers': answers},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengirim jawaban tes';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan submit tes: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getResult() async {
    try {
      final response = await dio.get('/skill-test/result');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat hasil tes minat';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat hasil tes: $e');
    }
  }
}
