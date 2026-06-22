import 'package:flutter/material.dart';

import '../theme.dart';

/// AppBar action that switches between System / Light / Dark theme modes.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => PopupMenuButton<ThemeMode>(
        icon: Icon(_iconFor(controller.mode)),
        tooltip: 'Theme',
        initialValue: controller.mode,
        onSelected: controller.setMode,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: ThemeMode.system,
            child: ListTile(
              leading: Icon(Icons.brightness_auto),
              title: Text('System'),
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.light,
            child: ListTile(
              leading: Icon(Icons.light_mode),
              title: Text('Light'),
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.dark,
            child: ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
        ThemeMode.system => Icons.brightness_auto,
      };
}
