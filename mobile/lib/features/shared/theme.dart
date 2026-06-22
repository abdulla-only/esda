import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// esda brand palette: indigo seed + coral accent.
const _seed = Color(0xFF4F46E5);
const _coral = Color(0xFFFF7A66);

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
  ).copyWith(tertiary: _coral); // coral as the accent where natural
  return ThemeData(colorScheme: scheme, useMaterial3: true);
}

final ThemeData esdaLightTheme = _buildTheme(Brightness.light);
final ThemeData esdaDarkTheme = _buildTheme(Brightness.dark);

/// Holds the chosen [ThemeMode], persisted in secure storage (key `esda.theme`).
class ThemeController extends ChangeNotifier {
  ThemeController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'esda.theme';

  final FlutterSecureStorage _storage;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Load the persisted preference; call once at startup.
  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    _mode = _parse(raw);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _storage.write(key: _key, value: mode.name);
  }

  ThemeMode _parse(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
