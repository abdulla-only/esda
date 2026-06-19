import 'package:flutter/foundation.dart';

import '../data/auth_api.dart';

/// Login/logout state + orchestration. UI listens; it holds no logic itself.
class AuthController extends ChangeNotifier {
  AuthController(this._api);

  final AuthApi _api;

  bool busy = false;
  String? error;

  Future<bool> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final ok = await _api.login(email.trim(), password);
      if (!ok) error = 'Invalid email or password.';
      return ok;
    } catch (_) {
      error = 'Could not reach the server.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _api.register(email.trim(), password);
      return true;
    } on RegisterException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Could not reach the server.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() => _api.logout();
}
