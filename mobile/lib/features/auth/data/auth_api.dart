import 'dart:convert';

import '../../shared/api_client.dart';

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
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      await _client.storage.save(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      return true;
    }
    return false;
  }

  Future<void> logout() => _client.storage.clear();
}
