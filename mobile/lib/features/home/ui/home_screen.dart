import 'package:flutter/material.dart';

import '../../auth/controller/auth_controller.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/ui/login_screen.dart';
import '../../decks/ui/decks_screen.dart';
import '../../shared/api_client.dart';
import '../../shared/theme.dart';
import '../../shared/ui/theme_toggle.dart';
import '../../study/ui/study_screen.dart';

/// Authenticated shell: Study / Decks tabs, theme toggle + sign-out in the AppBar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client, required this.theme});

  final ApiClient client;
  final ThemeController theme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthController _auth = AuthController(AuthApi(widget.client));
  int _tab = 0;

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(client: widget.client, theme: widget.theme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Both tabs kept alive via IndexedStack so state survives tab switches.
    final pages = [
      StudyScreen(client: widget.client, embedded: true),
      DecksScreen(client: widget.client),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Study' : 'Decks'),
        actions: [
          ThemeToggle(controller: widget.theme),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.style), label: 'Decks'),
        ],
      ),
    );
  }
}
