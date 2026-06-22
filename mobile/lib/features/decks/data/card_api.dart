import '../../shared/api_client.dart';
import 'card.dart';

class CardApi {
  CardApi(this._client);

  final ApiClient _client;

  Future<List<DeckCard>> list(int deckId) async {
    final data = await _client.getData(
      '/api/v1/cards',
      query: {'deck': deckId},
    ) as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => DeckCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeckCard> create({
    required int deck,
    required String front,
    required String back,
    String? partOfSpeech,
    String? example,
    String? description,
  }) async {
    final data = await _client.postData('/api/v1/cards', {
      'deck': deck,
      'front': front,
      'back': back,
      'part_of_speech': ?partOfSpeech,
      'example': ?example,
      'description': ?description,
    }) as Map<String, dynamic>;
    return DeckCard.fromJson(data);
  }

  Future<DeckCard> update(
    int id, {
    String? front,
    String? back,
    String? partOfSpeech,
    String? example,
    String? description,
  }) async {
    final data = await _client.patchData('/api/v1/cards/$id', {
      'front': ?front,
      'back': ?back,
      'part_of_speech': ?partOfSpeech,
      'example': ?example,
      'description': ?description,
    }) as Map<String, dynamic>;
    return DeckCard.fromJson(data);
  }

  Future<void> delete(int id) => _client.deleteData('/api/v1/cards/$id');
}
