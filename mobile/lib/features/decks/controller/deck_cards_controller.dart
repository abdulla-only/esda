import 'package:flutter/foundation.dart';

import '../data/card.dart';
import '../data/card_api.dart';

/// Owns the cards of a single deck, with add/edit/delete.
class DeckCardsController extends ChangeNotifier {
  DeckCardsController(this._api, this.deckId);

  final CardApi _api;
  final int deckId;

  List<DeckCard> cards = [];
  bool loading = true;
  bool busy = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      cards = await _api.list(deckId);
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String front,
    required String back,
    String? partOfSpeech,
    String? example,
    String? description,
  }) =>
      _mutate(() async {
        await _api.create(
          deck: deckId,
          front: front,
          back: back,
          partOfSpeech: partOfSpeech,
          example: example,
          description: description,
        );
        cards = await _api.list(deckId);
      });

  Future<bool> update(
    int id, {
    String? front,
    String? back,
    String? partOfSpeech,
    String? example,
    String? description,
  }) =>
      _mutate(() async {
        await _api.update(
          id,
          front: front,
          back: back,
          partOfSpeech: partOfSpeech,
          example: example,
          description: description,
        );
        cards = await _api.list(deckId);
      });

  Future<bool> delete(int id) => _mutate(() async {
        await _api.delete(id);
        cards = await _api.list(deckId);
      });

  Future<bool> _mutate(Future<void> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = '$e';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
