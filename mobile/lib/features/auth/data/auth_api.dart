import 'dart:convert';

import '../../shared/api_client.dart';

/// Raised when registration is rejected; carries the server's message.
class RegisterException implements Exception {
  RegisterException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Email/password login -> stores the JWT pair. Returns true on success.
  Future<bool> login(String email, String password) async {
    final res = await _client.postPublic('/api/v1/auth/token', {
      'email': email,
      'password': password,
    });
    if (res.statusCode == 200) {
      await _saveTokens(res.body);
      return true;
    }
    return false;
  }

  /// Register a new account -> stores the JWT pair. Throws RegisterException
  /// with the server message on validation failure.
  Future<void> register(String email, String password) async {
    final res = await _client.postPublic('/api/v1/auth/register', {
      'email': email,
      'password': password,
    });
    if (res.statusCode == 201) {
      await _saveTokens(res.body);
      return;
    }
    throw RegisterException(_errorMessage(res.body));
  }

  Future<void> logout() => _client.storage.clear();

  Future<void> _saveTokens(String body) async {
    final data = (jsonDecode(body) as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    await _client.storage.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
  }

  String _errorMessage(String body) {
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error']
          as Map<String, dynamic>?;
      if (error == null) return 'Registration failed.';
      final details = error['details'];
      if (details is Map && details.isNotEmpty) {
        final first = details.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
      }
      return error['message'] as String? ?? 'Registration failed.';
    } catch (_) {
      return 'Registration failed.';
    }
  }
}
