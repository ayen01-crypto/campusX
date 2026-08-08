import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _storage = secureStorage ?? const FlutterSecureStorage(),
        _baseUrl = baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:4000/v1',
        ),
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  Dio get dio => _dio;
  String get baseUrl => _baseUrl;
  String get socketUrl => _baseUrl.replaceFirst(RegExp(r'/v1/?$'), '');

  Future<String?> readAuthToken() => _storage.read(key: 'auth_token');

  Future<void> saveAuthToken(String token) =>
      _storage.write(key: 'auth_token', value: token);

  Future<void> clearAuthToken() => _storage.delete(key: 'auth_token');
}
