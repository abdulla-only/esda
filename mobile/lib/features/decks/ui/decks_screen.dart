import 'package:flutter/material.dart';

import '../../shared/api_client.dart';
import '../controller/decks_controller.dart';
import '../data/deck.dart';
import '../data/deck_api.dart';
import 'deck_cards_screen.dart';
import 'deck_form.dart';

/// Lists the user's own decks; create/rename/delete; tap to open a deck's cards.
/// Rendered body-only so the home shell hosts it under its own AppBar.
class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  late final DecksController _controller =
      DecksController(DeckApi(widget.client));

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_controller.languages.isEmpty) return;
    final result = await showDeckForm(
      context,
      languages: _controller.languages,
    );
    if (result != null) {
      await _controller.create(language: result.language, name: result.name);
    }
  }

  Future<void> _rename(Deck deck) async {
    final result = await showDeckForm(
      context,
      languages: _controller.languages,
      initialName: deck.name,
      lockedLanguage: deck.language,
    );
    if (result != null) await _controller.rename(deck.id, result.name);
  }

  Future<void> _delete(Deck deck) async {
    final ok = await _confirm(
      'Delete deck?',
      'Delete "${deck.name}" and its ${deck.cardCount} card(s)? This cannot be undone.',
    );
    if (ok) await _controller.delete(deck.id);
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openCards(Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckCardsScreen(client: widget.client, deck: deck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _body(),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => FloatingActionButton.extended(
              onPressed:
                  _controller.busy || _controller.languages.isEmpty ? null : _create,
              icon: const Icon(Icons.add),
              label: const Text('New deck'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_controller.error!, textAlign: TextAlign.center),
            ),
            FilledButton(
              onPressed: _controller.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_controller.decks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No decks yet. Create one to start adding cards.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _controller.decks.length,
        itemBuilder: (context, i) {
          final deck = _controller.decks[i];
          return ListTile(
            title: Text(deck.name),
            subtitle: Text('${deck.cardCount} card(s)'),
            onTap: () => _openCards(deck),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => v == 'rename' ? _rename(deck) : _delete(deck),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          );
        },
      ),
    );
  }
}
