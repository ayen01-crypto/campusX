import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'api_client.dart';
import 'models.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final campusApiProvider = Provider<CampusApi>((ref) => CampusApi(ref.watch(apiClientProvider)));

class CampusApi {
  CampusApi(this.client);

  final ApiClient client;
  final _uuid = const Uuid();

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _post('/auth/login', {'email': email.trim(), 'password': password});
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    return _post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  Future<Map<String, dynamic>> me() => _get('/auth/me');

  Future<List<Map<String, dynamic>>> universities({String? search}) async {
    final response = await _get('/universities', query: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    final data = response['_list'] as List<dynamic>? ?? const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) {
    return _patch('/users/me', data);
  }

  Future<String> uploadFile(Uint8List bytes, String filename) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await client.dio.post<dynamic>('/uploads', data: form);
      final data = _normalize(response.data);
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const CampusApiException('CampusX did not receive a media URL after upload.');
      }
      return _absoluteMediaUrl(url);
    } on DioException catch (error) {
      throw CampusApiException.fromDio(error);
    }
  }

  Future<List<CampusListing>> listings(
    ListingKind kind, {
    String? universityId,
    String? search,
  }) async {
    final response = await _get('/listings', query: {
      'kind': kind.apiValue,
      'take': 50,
      if (universityId != null) 'universityId': universityId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });

    final data = response['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => _listingFromApi(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<CampusListing> listing(String id) async {
    return _listingFromApi(await _get('/listings/$id'));
  }

  Future<CampusListing> createListing(CampusListing listing) async {
    final response = await _post('/listings', {
      'kind': listing.kind.apiValue,
      'title': listing.title,
      'subtitle': listing.subtitle,
      'description': listing.description,
      'price': listing.price,
      'currency': 'UGX',
      'location': listing.location,
      'images': listing.imageUrls,
      'universityId': listing.universityId,
    });
    return _listingFromApi(response);
  }

  Future<bool> toggleSaved(String listingId) async {
    final response = await _post('/listings/$listingId/save', const {});
    return response['saved'] as bool? ?? false;
  }

  Future<List<CampusListing>> savedListings() async {
    final response = await _get('/listings/saved/me');
    final data = response['_list'] as List<dynamic>? ?? const [];
    return data
        .map((item) => _listingFromApi(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<String> startConversation({required String participantId, String? listingId}) async {
    final response = await _post('/conversations', {
      'participantId': participantId,
      if (listingId != null) 'listingId': listingId,
    });
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> conversations() async {
    final response = await _get('/conversations');
    final data = response['_list'] as List<dynamic>? ?? const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<ChatMessage>> messages(String conversationId, String currentUserId) async {
    final response = await _get('/conversations/$conversationId/messages');
    final data = response['data'] as List<dynamic>? ?? const [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return ChatMessage(
        id: map['clientId'] as String? ?? map['id'] as String,
        text: map['body'] as String? ?? '',
        sentAt: DateTime.tryParse(map['sentAt'] as String? ?? '') ?? DateTime.now(),
        isMine: map['senderId'] == currentUserId,
      );
    }).toList();
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
    required String currentUserId,
    String? clientId,
  }) async {
    final localId = clientId ?? _uuid.v4();
    final response = await _post('/conversations/$conversationId/messages', {
      'clientId': localId,
      'body': text.trim(),
    });
    return ChatMessage(
      id: response['clientId'] as String? ?? localId,
      text: response['body'] as String? ?? text.trim(),
      sentAt: DateTime.tryParse(response['sentAt'] as String? ?? '') ?? DateTime.now(),
      isMine: response['senderId'] == currentUserId,
    );
  }

  Future<Map<String, dynamic>> performListingAction(ListingKind kind, String listingId) {
    return switch (kind) {
      ListingKind.tutor || ListingKind.service || ListingKind.rental =>
        _post('/engagement/listings/$listingId/book', const {}),
      ListingKind.internship =>
        _post('/engagement/listings/$listingId/apply', const {}),
      ListingKind.event =>
        _post('/engagement/listings/$listingId/tickets', const {'quantity': 1}),
      ListingKind.deal =>
        _post('/engagement/listings/$listingId/claim', const {}),
      _ => Future.value(const <String, dynamic>{}),
    };
  }

  Future<Map<String, dynamic>> initiatePayment(
    String paymentId, {
    required String provider,
    String? phone,
  }) {
    return _post('/payments/$paymentId/initiate', {
      'provider': provider,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
  }

  Future<Map<String, dynamic>> confirmMockPayment(String paymentId) {
    return _post('/payments/$paymentId/mock-confirm', const {});
  }

  CampusListing _listingFromApi(Map<String, dynamic> map) {
    final rawKind = (map['kind'] as String? ?? 'MARKETPLACE').toLowerCase();
    final kind = ListingKind.values.firstWhere(
      (item) => item.name == rawKind,
      orElse: () => ListingKind.marketplace,
    );
    final owner = map['owner'] is Map
        ? Map<String, dynamic>.from(map['owner'] as Map)
        : const <String, dynamic>{};
    final university = map['university'] is Map
        ? Map<String, dynamic>.from(map['university'] as Map)
        : const <String, dynamic>{};
    final reviews = map['reviews'] as List<dynamic>? ?? const [];
    final average = reviews.isEmpty
        ? 0.0
        : reviews
                .map(
                  (review) =>
                      (Map<String, dynamic>.from(review as Map)['rating'] as num?)?.toDouble() ??
                      0,
                )
                .fold<double>(0, (sum, value) => sum + value) /
            reviews.length;
    final images = List<String>.from(map['images'] as List? ?? const [])
        .map(_absoluteMediaUrl)
        .toList();

    return CampusListing(
      id: map['id'] as String,
      kind: kind,
      title: map['title'] as String? ?? kind.title,
      subtitle: map['subtitle'] as String? ?? '',
      description: map['description'] as String? ?? '',
      emoji: kind.emoji,
      location: (map['location'] as String?) ?? (university['name'] as String?) ?? 'Campus',
      price: (map['price'] as num?)?.toInt(),
      rating: average,
      badge: owner['verified'] == true ? 'Verified' : null,
      owner: owner['name'] as String? ?? 'CampusX Member',
      ownerId: (owner['id'] as String?) ?? (map['ownerId'] as String?),
      universityId: map['universityId'] as String?,
      imageUrls: images,
      details: {
        if (university['name'] != null) 'University': '${university['name']}',
        if (map['currency'] != null) 'Currency': '${map['currency']}',
      },
    );
  }

  String _absoluteMediaUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    if (value.startsWith('/')) return '${client.baseUrl}$value';
    return '${client.baseUrl}/$value';
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await client.dio.get<dynamic>(path, queryParameters: query);
      return _normalize(response.data);
    } on DioException catch (error) {
      throw CampusApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await client.dio.post<dynamic>(path, data: body);
      return _normalize(response.data);
    } on DioException catch (error) {
      throw CampusApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await client.dio.patch<dynamic>(path, data: body);
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

class CampusApiException implements Exception {
  const CampusApiException(this.message, {this.statusCode});

  factory CampusApiException.fromDio(DioException error) {
    final data = error.response?.data;
    String? message;
    if (data is Map) {
      final raw = data['message'];
      if (raw is String) message = raw;
      if (raw is List) message = raw.join('\n');
    }
    return CampusApiException(
      message ?? error.message ?? 'CampusX could not reach the server.',
      statusCode: error.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
