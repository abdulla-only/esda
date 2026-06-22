import 'package:flutter/material.dart';

import '../../shared/api_client.dart';
import '../../shared/theme.dart';
import '../../shared/ui/feedback.dart';
import '../../shared/ui/glass.dart';
import '../../study/ui/study_screen.dart';
import '../controller/deck_cards_controller.dart';
import '../data/card.dart';
import '../data/card_api.dart';
import '../data/deck.dart';
import 'card_form.dart';

/// Lists a deck's cards with add/edit/delete and a "Study this deck" action.
class DeckCardsScreen extends StatefulWidget {
  const DeckCardsScreen({super.key, required this.client, required this.deck});

  final ApiClient client;
  final Deck deck;

  @override
  State<DeckCardsScreen> createState() => _DeckCardsScreenState();
}

class _DeckCardsScreenState extends State<DeckCardsScreen> {
  late final DeckCardsController _controller =
      DeckCardsController(CardApi(widget.client), widget.deck.id);

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

  Future<void> _add() async {
    final result = await showCardForm(context);
    if (result == null) return;
    try {
      await _controller.create(
        front: result.front,
        back: result.back,
        partOfSpeech: result.partOfSpeech,
        example: result.example,
        description: result.description,
      );
      if (mounted) showMessage(context, 'Card added');
    } catch (_) {
      if (mounted) showMessage(context, "Couldn't add the card.", error: true);
    }
  }

  Future<void> _edit(DeckCard card) async {
    final result = await showCardForm(context, card: card);
    if (result == null) return;
    try {
      await _controller.update(
        card.id,
        front: result.front,
        back: result.back,
        partOfSpeech: result.partOfSpeech,
        example: result.example,
        description: result.description,
      );
      if (mounted) showMessage(context, 'Card saved');
    } catch (_) {
      if (mounted) showMessage(context, "Couldn't save the card.", error: true);
    }
  }

  Future<void> _delete(DeckCard card) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete card?',
      message: 'Delete "${card.front}"? This cannot be undone.',
      confirmText: 'Delete',
      danger: true,
    );
    if (!ok) return;
    try {
      await _controller.delete(card.id);
      if (mounted) showMessage(context, 'Card deleted');
    } catch (_) {
      if (mounted) showMessage(context, "Couldn't delete the card.", error: true);
    }
  }

  void _study() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          client: widget.client,
          deckId: widget.deck.id,
          deckName: widget.deck.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          IconButton(
            onPressed: _study,
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Study this deck',
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => FloatingActionButton.extended(
          onPressed: _controller.busy ? null : _add,
          icon: const Icon(Icons.add),
          label: const Text('Add card'),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _body(),
      ),
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
    if (_controller.cards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No cards yet. Add one to start studying.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final t = AuroraTokens.of(context);
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _controller.cards.length,
        itemBuilder: (context, i) {
          final card = _controller.cards[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              onTap: () => _edit(card),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: card.front),
                              TextSpan(
                                text: '  →  ',
                                style: TextStyle(color: t.muted),
                              ),
                              TextSpan(
                                text: card.back,
                                style: TextStyle(color: t.brandText),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.partOfSpeech,
                          style: TextStyle(color: t.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? _edit(card) : _delete(card),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
