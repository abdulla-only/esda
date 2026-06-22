import 'dart:ui';

import 'package:flutter/material.dart';

import '../../auth/controller/auth_controller.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/ui/login_screen.dart';
import '../../decks/ui/decks_screen.dart';
import '../../shared/api_client.dart';
import '../../shared/theme.dart';
import '../../shared/ui/feedback.dart';
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
    final ok = await confirmDialog(
      context,
      title: 'Sign out?',
      message: "You'll need to sign in again.",
      confirmText: 'Sign out',
      danger: true,
    );
    if (!ok) return;
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
    final t = AuroraTokens.of(context);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Study' : 'Decks'),
        // Subtle frosted strip so content scrolls under the bar over the aurora.
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: const SizedBox.expand(),
          ),
        ),
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
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.glassFill,
              border: Border(top: BorderSide(color: t.glassBorder)),
            ),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.school), label: 'Study'),
                NavigationDestination(icon: Icon(Icons.style), label: 'Decks'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
