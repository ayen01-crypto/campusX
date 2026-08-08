import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'campus_api.dart';

final campusAccountApiProvider = Provider<CampusAccountApi>(
  (ref) => CampusAccountApi(ref.watch(apiClientProvider)),
);

class CampusAccountApi {
  CampusAccountApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> profile(String userId) => _get('/users/$userId');

  Future<Map<String, dynamic>> activity() => _get('/engagement/me');

  Future<List<Map<String, dynamic>>> notifications({bool unreadOnly = false}) async {
    final response = await _get('/notifications', query: {
      if (unreadOnly) 'unreadOnly': 'true',
    });
    final data = response['_list'] as List<dynamic>? ?? const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _post('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _post('/notifications/read-all');
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await client.dio.get<dynamic>(path, queryParameters: query);
      return _normalize(response.data);
    } on DioException catch (error) {
      throw CampusApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> _post(String path) async {
    try {
      final response = await client.dio.post<dynamic>(path, data: const {});
      return _normalize(response.data);
    } on DioException catch (error) {
      throw CampusApiException.fromDio(error);
    }
  }

  Map<String, dynamic> _normalize(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) return {'_list': value};
    return {'value': value};
  }
}
