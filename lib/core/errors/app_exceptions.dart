/// AppException — base class for all domain-level errors.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException($statusCode): $message';
}

/// NetworkException — HTTP / connection errors
class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});
}

/// UnauthorizedException — 401, token expired / invalid
class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Sesi telah habis. Silakan login kembali.'});
}

/// NotFoundException — 404
class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Data tidak ditemukan.'});
}

/// ServerException — 500
class ServerException extends AppException {
  const ServerException({super.message = 'Terjadi kesalahan pada server. Coba lagi nanti.'});
}

/// ValidationException — 422, bad request
class ValidationException extends AppException {
  const ValidationException({required super.message});
}

/// CacheException — local storage read/write failure
class CacheException extends AppException {
  const CacheException({super.message = 'Gagal membaca data lokal.'});
}
