import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

abstract class WishlistRemoteDataSource {
  Future<List<dynamic>> getWishlist();
  Future<void> addToWishlist({String? courseId, String? bootcampId});
  Future<void> removeFromWishlist({String? courseId, String? bootcampId});
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final Dio dio;

  WishlistRemoteDataSourceImpl({Dio? client}) : dio = client ?? ApiClient.dio;

  @override
  Future<List<dynamic>> getWishlist() async {
    try {
      final response = await dio.get('/wishlist');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal memuat wishlist';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan memuat wishlist: $e');
    }
  }

  @override
  Future<void> addToWishlist({String? courseId, String? bootcampId}) async {
    try {
      final payload = <String, dynamic>{
        'productType': courseId != null ? 'MINI_COURSE' : 'BOOTCAMP',
      };
      if (courseId != null) payload['courseId'] = courseId;
      if (bootcampId != null) payload['bootcampId'] = bootcampId;
      await dio.post('/wishlist', data: payload);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menambahkan ke wishlist';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<void> removeFromWishlist({String? courseId, String? bootcampId}) async {
    try {
      if (courseId != null) {
        await dio.delete('/wishlist/course/$courseId');
      } else if (bootcampId != null) {
        await dio.delete('/wishlist/bootcamp/$bootcampId');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menghapus dari wishlist';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
