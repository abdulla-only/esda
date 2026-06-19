import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'ApiException($statusCode)';
}

/// Shared HTTP transport: attaches the JWT, refreshes once on a 401, and
/// unwraps the API envelope ({success,data}). Feature data layers build on this.
class ApiClient {
  ApiClient({TokenStorage? storage}) : storage = storage ?? TokenStorage();

  final TokenStorage storage;
  final http.Client _http = http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('${Config.apiUrl}$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
      );

  Future<Map<String, String>> _authHeaders() async {
    final token = await storage.access;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _data(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    final body = jsonDecode(res.body);
    return body is Map<String, dynamic> ? body['data'] : body;
  }

  /// Unauthenticated POST (login, token refresh). Returns the raw response.
  Future<http.Response> postPublic(String path, Map<String, dynamic> body) =>
      _http.post(
        _uri(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

  Future<bool> refresh() async {
    final token = await storage.refresh;
    if (token == null) return false;
    final res = await postPublic('/api/v1/auth/token/refresh', {'refresh': token});
    if (res.statusCode == 200) {
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      await storage.saveAccess(data['access'] as String);
      return true;
    }
    await storage.clear();
    return false;
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) run,
  ) async {
    var res = await run(await _authHeaders());
    if (res.statusCode == 401 && await refresh()) {
      res = await run(await _authHeaders());
    }
    return res;
  }

  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async =>
      _data(await _send((h) => _http.get(_uri(path, query), headers: h)));

  Future<dynamic> postData(String path, Map<String, dynamic> body) async =>
      _data(await _send(
        (h) => _http.post(_uri(path), headers: h, body: jsonEncode(body)),
      ));
}
