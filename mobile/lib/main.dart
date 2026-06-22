import 'package:flutter/material.dart';

import 'features/auth/ui/login_screen.dart';
import 'features/home/ui/home_screen.dart';
import 'features/shared/api_client.dart';
import 'features/shared/theme.dart';
import 'features/shared/ui/aurora_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeController();
  await theme.load(); // restore the persisted theme before first frame
  runApp(EsdaApp(theme: theme));
}

class EsdaApp extends StatelessWidget {
  const EsdaApp({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    final client = ApiClient();
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) => MaterialApp(
        title: 'esda',
        theme: esdaLightTheme,
        darkTheme: esdaDarkTheme,
        themeMode: theme.mode,
        builder: (context, child) => AuroraBackground(child: child!),
        home: _Root(client: client, theme: theme),
      ),
    );
  }
}

/// Picks the first screen based on whether a JWT is already stored.
class _Root extends StatelessWidget {
  const _Root({required this.client, required this.theme});

  final ApiClient client;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: client.storage.isAuthed,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!) {
          return LoginScreen(client: client, theme: theme);
        }
        return HomeScreen(client: client, theme: theme);
      },
    );
  }
}
