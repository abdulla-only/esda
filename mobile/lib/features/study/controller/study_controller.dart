import 'package:flutter/foundation.dart';

import '../data/study_api.dart';
import '../data/study_card.dart';

/// Study session state + orchestration (load queue, reveal, grade, advance).
class StudyController extends ChangeNotifier {
  StudyController(this._api);

  final StudyApi _api;

  List<StudyCard> queue = [];
  int index = 0;
  bool revealed = false;
  bool loading = true;
  bool grading = false;
  String? error;

  StudyCard? get current => index < queue.length ? queue[index] : null;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      queue = await _api.queue(limit: 30);
      index = 0;
      revealed = false;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void reveal() {
    revealed = true;
    notifyListeners();
  }

  Future<void> grade(int rating) async {
    final card = current;
    if (card == null || grading) return;
    grading = true;
    notifyListeners();
    try {
      await _api.grade(card.id, rating);
      if (index + 1 < queue.length) {
        index++;
        revealed = false;
      } else {
        await load();
      }
    } catch (e) {
      error = '$e';
    } finally {
      grading = false;
      notifyListeners();
    }
  }
}
