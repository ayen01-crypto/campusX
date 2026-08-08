import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'campus_api.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.universityId,
    this.universityName,
    this.verified = false,
  });

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? universityId;
  final String? universityName;
  final bool verified;

  factory AuthUser.fromApi(Map<String, dynamic> map) {
    final university = map['university'] is Map
        ? Map<String, dynamic>.from(map['university'] as Map)
        : const <String, dynamic>{};
    return AuthUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'CampusX Member',
      avatarUrl: map['avatarUrl'] as String?,
      universityId: map['universityId'] as String?,
      universityName: university['name'] as String?,
      verified: map['verified'] as bool? ?? false,
    );
  }

  AuthUser copyWith({String? universityId, String? universityName, String? name}) => AuthUser(
        id: id,
        email: email,
        name: name ?? this.name,
        avatarUrl: avatarUrl,
        universityId: universityId ?? this.universityId,
        universityName: universityName ?? this.universityName,
        verified: verified,
      );
}

class AuthState {
  const AuthState({
    this.user,
    this.loading = false,
    this.restoring = true,
    this.error,
  });

  final AuthUser? user;
  final bool loading;
  final bool restoring;
  final String? error;

  bool get authenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool? loading,
    bool? restoring,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      loading: loading ?? this.loading,
      restoring: restoring ?? this.restoring,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  bool _restoreStarted = false;

  @override
  AuthState build() {
    if (!_restoreStarted) {
      _restoreStarted = true;
      unawaited(Future<void>.microtask(_restore));
    }
    return const AuthState();
  }

  Future<void> _restore() async {
    final client = ref.read(apiClientProvider);
    final token = await client.readAuthToken();
    if (token == null || token.isEmpty) {
      if (ref.mounted) state = state.copyWith(restoring: false);
      return;
    }

    try {
      final user = AuthUser.fromApi(await ref.read(campusApiProvider).me());
      if (ref.mounted) state = AuthState(user: user, restoring: false);
    } catch (_) {
      await client.clearAuthToken();
      if (ref.mounted) state = const AuthState(restoring: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true, restoring: false);
    try {
      final response = await ref.read(campusApiProvider).login(email, password);
      await _acceptSession(response);
      return true;
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(loading: true, clearError: true, restoring: false);
    try {
      final response = await ref.read(campusApiProvider).register(name, email, password);
      await _acceptSession(response);
      return true;
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
      return false;
    }
  }

  Future<void> updateUniversity(String id, String name) async {
    final current = state.user;
    if (current == null) return;
    final response = await ref.read(campusApiProvider).updateProfile({'universityId': id});
    state = state.copyWith(user: AuthUser.fromApi(response).copyWith(universityName: name));
  }

  Future<void> signOut() async {
    await ref.read(apiClientProvider).clearAuthToken();
    state = const AuthState(restoring: false);
  }

  Future<void> _acceptSession(Map<String, dynamic> response) async {
    final token = response['accessToken'] as String?;
    final rawUser = response['user'];
    if (token == null || rawUser is! Map) {
      throw const CampusApiException('The server returned an invalid login response.');
    }
    await ref.read(apiClientProvider).saveAuthToken(token);
    state = AuthState(
      user: AuthUser.fromApi(Map<String, dynamic>.from(rawUser)),
      loading: false,
      restoring: false,
    );
  }
}
