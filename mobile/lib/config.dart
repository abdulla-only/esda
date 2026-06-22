/// App configuration.
///
/// Override the API base URL at build/run time, e.g.:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8001
///
/// Defaults to 10.0.2.2 which is the Android emulator's alias for the host
/// machine's localhost (use http://localhost:8001 for iOS simulator).
/// The host API is published on 8001 (8000 is left free for other projects).
class Config {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8001',
  );
}
