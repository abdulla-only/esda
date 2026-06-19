import 'package:flutter/material.dart';

import 'features/auth/controller/auth_controller.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/shared/api_client.dart';
import 'features/study/ui/study_screen.dart';

void main() {
  runApp(const EsdaApp());
}

class EsdaApp extends StatelessWidget {
  const EsdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = ApiClient();
    return MaterialApp(
      title: 'esda',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3390EC)),
        useMaterial3: true,
      ),
      home: _Root(client: client),
    );
  }
}

/// Picks the first screen based on whether a JWT is already stored.
class _Root extends StatelessWidget {
  const _Root({required this.client});

  final ApiClient client;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: client.storage.isAuthed,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.data!) {
          return LoginScreen(client: client);
        }
        return StudyScreen(
          client: client,
          auth: AuthController(AuthApi(client)),
        );
      },
    );
  }
}
