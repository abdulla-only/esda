# esda mobile (Flutter)

Flutter client for the esda API, at parity with the web app: email/JWT login +
registration, per-user **decks & cards CRUD**, study (all or per-deck) with FSRS
grading, and a light/dark/system theme using the esda brand.

## Structure (feature-first)

```
lib/
├── main.dart                       # entry: loads theme, routes by token presence
├── config.dart                     # API base URL (--dart-define=API_URL=...)
└── features/
    ├── shared/
    │   ├── api_client.dart         # JWT attach + refresh + envelope unwrap (GET/POST/PATCH/DELETE)
    │   ├── token_storage.dart      # JWT in flutter_secure_storage
    │   ├── theme.dart              # esda ThemeData (light/dark) + ThemeController (persisted)
    │   └── ui/theme_toggle.dart    # System / Light / Dark menu
    ├── home/ui/home_screen.dart    # bottom nav (Study, Decks) + theme toggle + sign out
    ├── auth/{data,controller,ui}   # email login + register
    ├── decks/{data,controller,ui}  # decks + cards CRUD, "Study this deck"
    └── study/{data,controller,ui}  # study queue + grade (all or filtered by deck)
```

UI is presentation-only; logic lives in `ChangeNotifier` controllers
(`ListenableBuilder`). Only deps: `http`, `flutter_secure_storage`.

## Run

```bash
flutter pub get
# Android emulator (default API_URL is http://10.0.2.2:8001 = host localhost):
flutter run
# iOS simulator or a custom host:
flutter run --dart-define=API_URL=http://localhost:8001
```

Register in-app (or sign in), open **Decks** to create a deck + cards, then
**Study** (all decks or a single deck). Content is per-user — there is no shared
catalog, so a new account starts empty.

> **Note:** Android blocks cleartext HTTP in release builds. The `http://`
> default works in debug; for release use HTTPS or a network security config.
