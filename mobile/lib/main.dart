import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/study_screen.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';

void main() {
  runApp(const EsdaApp());
}

class EsdaApp extends StatelessWidget {
  const EsdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return MaterialApp(
      title: 'esda',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3390EC)),
        useMaterial3: true,
      ),
      home: _Root(api: api),
    );
  }
}

/// Picks the first screen based on whether a JWT is already stored.
class _Root extends StatelessWidget {
  const _Root({required this.api});

  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TokenStorage().isAuthed,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data! ? StudyScreen(api: api) : LoginScreen(api: api);
      },
    );
  }
}
