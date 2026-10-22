import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class ChallengeRemoteDataSource {
  Future<List<dynamic>> getChallenges({String? field, String? level});
  Future<Map<String, dynamic>> getChallengeDetail(String id);
  Future<Map<String, dynamic>> submitChallenge(
    String id, {
    required int score,
    required int timeSpentSeconds,
    List<dynamic>? answers,
  });
  Future<List<dynamic>> getLeaderboard();
}

class ChallengeRemoteDataSourceImpl implements ChallengeRemoteDataSource {
  final Dio dio;

  ChallengeRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<List<dynamic>> getChallenges({String? field, String? level}) async {
    try {
      final params = <String, dynamic>{};
      if (field != null && field != 'ALL') params['field'] = field;
      if (level != null && level != 'ALL') params['level'] = level;

      final response = await dio.get('/challenges', queryParameters: params);
      final raw = response.data['data'];
      if (raw is List) return raw;
      if (raw is Map && raw['items'] is List) return raw['items'] as List<dynamic>;
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat tantangan';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat tantangan: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getChallengeDetail(String id) async {
    try {
      final response = await dio.get('/challenges/$id');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat detail tantangan';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal membuka tantangan: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> submitChallenge(
    String id, {
    required int score,
    required int timeSpentSeconds,
    List<dynamic>? answers,
  }) async {
    try {
      final response = await dio.post(
        '/challenges/$id/submit',
        data: {
          'score': score,
          'timeSpentSeconds': timeSpentSeconds,
          'answers': ?answers,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal mengumpulkan tantangan';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan saat submit tantangan: $e');
    }
  }

  @override
  Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await dio.get('/leaderboard');
      final data = response.data['data'];
      if (data is List) return data;
      if (data is Map && data['rankings'] is List) return data['rankings'] as List<dynamic>;
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat leaderboard';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat papan peringkat: $e');
    }
  }
}
