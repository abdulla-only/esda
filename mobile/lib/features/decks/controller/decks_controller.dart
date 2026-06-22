import 'package:flutter/foundation.dart';

import '../data/deck.dart';
import '../data/deck_api.dart';
import '../data/language.dart';

/// Owns the user's decks + available languages, with create/rename/delete.
class DecksController extends ChangeNotifier {
  DecksController(this._api);

  final DeckApi _api;

  List<Deck> decks = [];
  List<Language> languages = [];
  bool loading = true;
  bool busy = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_api.list(), _api.languages()]);
      decks = results[0] as List<Deck>;
      languages = results[1] as List<Language>;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Mutations rethrow on failure; the screen shows a snackbar. (`error` is only
  // for the full-screen initial-load failure.)
  Future<void> create({required int language, required String name}) =>
      _mutate(() async {
        await _api.create(language: language, name: name);
        decks = await _api.list();
      });

  Future<void> rename(int id, String name) => _mutate(() async {
        await _api.rename(id, name);
        decks = await _api.list();
      });

  Future<void> delete(int id) => _mutate(() async {
        await _api.delete(id);
        decks = await _api.list();
      });

  Future<void> _mutate(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
