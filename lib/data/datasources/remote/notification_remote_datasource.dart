import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class NotificationRemoteDataSource {
  Future<Map<String, dynamic>> getNotifications({int page = 1, bool unreadOnly = false});
  Future<void> markAllRead();
  Future<void> markRead(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<Map<String, dynamic>> getNotifications({int page = 1, bool unreadOnly = false}) async {
    try {
      final response = await dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': 20,
          if (unreadOnly) 'unread': 'true',
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat notifikasi';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat notifikasi: $e');
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menandai notifikasi';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await dio.patch('/notifications/$id/read');
    } catch (_) {}
  }
}
