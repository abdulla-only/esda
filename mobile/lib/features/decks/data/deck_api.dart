import '../../shared/api_client.dart';
import 'deck.dart';
import 'language.dart';

class DeckApi {
  DeckApi(this._client);

  final ApiClient _client;

  /// The caller's own (flat) personal decks. owner=me mirrors the web client.
  Future<List<Deck>> list() async {
    final data = await _client.getData(
      '/api/v1/decks',
      query: {'owner': 'me'},
    ) as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => Deck.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Deck> create({required int language, required String name}) async {
    final data = await _client.postData('/api/v1/decks', {
      'language': language,
      'name': name,
    }) as Map<String, dynamic>;
    return Deck.fromJson(data);
  }

  Future<Deck> rename(int id, String name) async {
    final data =
        await _client.patchData('/api/v1/decks/$id', {'name': name}) as Map<String, dynamic>;
    return Deck.fromJson(data);
  }

  Future<void> delete(int id) => _client.deleteData('/api/v1/decks/$id');

  Future<List<Language>> languages() async {
    final data = await _client.getData('/api/v1/languages') as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => Language.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
