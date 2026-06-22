# esda mobile (Flutter)

Skeleton Flutter client for the esda API. It shares the same backend endpoints
as the web app: email/JWT login, the study queue, and FSRS grading.

## Structure

```
lib/
├── main.dart                  # app entry; routes to Login or Study by token presence
├── config.dart                # API base URL (override with --dart-define=API_URL=...)
├── models/study_card.dart
├── services/
│   ├── api_service.dart       # HTTP client + JWT attach/refresh
│   └── token_storage.dart     # JWT in flutter_secure_storage (Keychain/Keystore)
└── screens/
    ├── login_screen.dart
    └── study_screen.dart      # front → reveal → Again/Hard/Good/Easy
```

## Run

```bash
flutter pub get
# Android emulator (default API_URL is http://10.0.2.2:8001 = host localhost):
flutter run
# iOS simulator or a custom host:
flutter run --dart-define=API_URL=http://localhost:8001
```

Sign in with a backend user (e.g. one created via `make superuser`). Full
feature parity with web (deck browser, Telegram auth) is intentionally not
implemented yet — this is a working skeleton.

> **Note:** Android blocks cleartext HTTP in release builds. The `http://`
> default works in debug; for release use HTTPS or a network security config.
