import '../../shared/api_client.dart';
import 'study_card.dart';

class StudyApi {
  StudyApi(this._client);

  final ApiClient _client;

  Future<List<StudyCard>> queue({int? deck, int limit = 20}) async {
    final data = await _client.getData(
      '/api/v1/study/queue',
      query: {'limit': limit, 'deck': ?deck},
    ) as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => StudyCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Grade a card (1=Again .. 4=Easy).
  Future<void> grade(int cardId, int rating) =>
      _client.postData('/api/v1/study/grade', {'card': cardId, 'rating': rating});
}
