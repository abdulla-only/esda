/// App configuration.
///
/// Override the API base URL at build/run time, e.g.:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8000
///
/// Defaults to 10.0.2.2 which is the Android emulator's alias for the host
/// machine's localhost (use http://localhost:8000 for iOS simulator).
class Config {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
