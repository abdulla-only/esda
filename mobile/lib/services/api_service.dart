import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/study_card.dart';
import 'token_storage.dart';

/// Thin client for the esda API. Calls the same endpoints as the web app and
/// attaches the stored JWT, refreshing once on a 401.
class ApiService {
  ApiService({TokenStorage? storage}) : _storage = storage ?? TokenStorage();

  final TokenStorage _storage;
  final http.Client _client = http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('${Config.apiUrl}$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
      );

  Future<Map<String, String>> _headers() async {
    final token = await _storage.access;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Email/password login -> stores the JWT pair. Returns true on success.
  Future<bool> login(String email, String password) async {
    final res = await _client.post(
      _uri('/api/v1/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      await _storage.save(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      return true;
    }
    return false;
  }

  Future<void> logout() => _storage.clear();

  Future<bool> _refresh() async {
    final refresh = await _storage.refresh;
    if (refresh == null) return false;
    final res = await _client.post(
      _uri('/api/v1/auth/token/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (res.statusCode == 200) {
      final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      await _storage.saveAccess(data['access'] as String);
      return true;
    }
    await _storage.clear();
    return false;
  }

  /// Issues a request, retrying once after a token refresh on 401.
  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) run,
  ) async {
    var res = await run(await _headers());
    if (res.statusCode == 401 && await _refresh()) {
      res = await run(await _headers());
    }
    return res;
  }

  Future<List<StudyCard>> studyQueue({int? deck, int limit = 20}) async {
    final res = await _send(
      (h) => _client.get(
        _uri('/api/v1/study/queue', {'limit': limit, 'deck': ?deck}),
        headers: h,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load study queue (${res.statusCode})');
    }
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => StudyCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Grade a card (1=Again .. 4=Easy).
  Future<void> grade(int cardId, int rating) async {
    final res = await _send(
      (h) => _client.post(
        _uri('/api/v1/study/grade'),
        headers: h,
        body: jsonEncode({'card': cardId, 'rating': rating}),
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to grade card (${res.statusCode})');
    }
  }
}
