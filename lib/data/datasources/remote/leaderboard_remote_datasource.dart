import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class LeaderboardRemoteDataSource {
  Future<Map<String, dynamic>> getLeaderboard({String period, String? field});
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final Dio dio;

  LeaderboardRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<Map<String, dynamic>> getLeaderboard({
    String period = 'all-time',
    String? field,
  }) async {
    try {
      final params = <String, dynamic>{'period': period};
      if (field != null && field.isNotEmpty) params['field'] = field;

      final response = await dio.get('/leaderboard', queryParameters: params);
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat leaderboard';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat leaderboard: $e');
    }
  }
}
