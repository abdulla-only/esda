import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// "Aurora Glass" design tokens shared across the app, split by brightness so
/// every surface (background glows, glass fills, grade hues) reads one source.
class AuroraTokens {
  const AuroraTokens({
    required this.bg,
    required this.text,
    required this.muted,
    required this.brand,
    required this.brand2,
    required this.brandText,
    required this.auroraA,
    required this.auroraB,
    required this.auroraC,
    required this.glassFill,
    required this.glassBorder,
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  final Color bg;
  final Color text;
  final Color muted;
  final Color brand;
  final Color brand2;
  final Color brandText;
  final Color auroraA; // top-left glow
  final Color auroraB; // top-right glow
  final Color auroraC; // bottom glow
  final Color glassFill;
  final Color glassBorder;
  final Color again;
  final Color hard;
  final Color good;
  final Color easy;

  /// Reads the tokens for the active brightness off the ambient theme.
  static AuroraTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const dark = AuroraTokens(
    bg: Color(0xFF06070F),
    text: Color(0xFFF3F4FD),
    muted: Color(0xFFA4A6C8),
    brand: Color(0xFF8B7BFF),
    brand2: Color(0xFF6C5CFF),
    brandText: Color(0xFFC4B5FD),
    auroraA: Color(0x577C6CFF), // violet ~0.34
    auroraB: Color(0x3D2DD4F0), // cyan ~0.24
    auroraC: Color(0x2EEC4899), // magenta ~0.18
    glassFill: Color(0x0FFFFFFF), // white @ 0.06
    glassBorder: Color(0x1FFFFFFF), // white @ 0.12
    again: Color(0xFFFF5D72),
    hard: Color(0xFFFF9F43),
    good: Color(0xFF2FE0A1),
    easy: Color(0xFF3AA0FF),
  );

  static const light = AuroraTokens(
    bg: Color(0xFFECECFA),
    text: Color(0xFF14152A),
    muted: Color(0xFF5A5C78),
    brand: Color(0xFF6C5CFF),
    brand2: Color(0xFF4F46E5),
    brandText: Color(0xFF4F46E5),
    auroraA: Color(0x387C6CFF), // violet pastel
    auroraB: Color(0x2E38BDF8), // sky pastel
    auroraC: Color(0x29F472B6), // pink pastel
    glassFill: Color(0x99FFFFFF), // white @ 0.6
    glassBorder: Color(0x22141432),
    again: Color(0xFFFF5D72),
    hard: Color(0xFFFF9F43),
    good: Color(0xFF1FC98B),
    easy: Color(0xFF3AA0FF),
  );
}

ThemeData _buildTheme(Brightness brightness) {
  final t = brightness == Brightness.dark ? AuroraTokens.dark : AuroraTokens.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: t.brand,
    brightness: brightness,
  ).copyWith(
    surface: t.bg,
    onSurface: t.text,
    primary: t.brand,
    onPrimary: brightness == Brightness.dark ? const Color(0xFF120F2E) : Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent, // let the aurora show through
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: t.brand.withValues(alpha: 0.22),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontSize: 12, color: t.muted, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? t.brand : t.muted,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF12132A)
          : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF1A1B36)
          : const Color(0xFF14152A),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.glassFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.brand, width: 1.4),
      ),
    ),
  );
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
