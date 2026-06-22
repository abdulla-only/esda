import 'package:flutter/material.dart';

import '../../shared/api_client.dart';
import '../controller/study_controller.dart';
import '../data/study_api.dart';

const _grades = [
  (rating: 1, label: 'Again', color: Color(0xFFE64646)),
  (rating: 2, label: 'Hard', color: Color(0xFFE6A046)),
  (rating: 3, label: 'Good', color: Color(0xFF3AAF5C)),
  (rating: 4, label: 'Easy', color: Color(0xFF4F46E5)),
];

/// Reusable study session. When [deckId] is set, only that deck is studied and a
/// banner is shown. When [embedded] is true it renders body-only (no Scaffold),
/// so the home shell can host it inside its own AppBar/BottomNav.
class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.client,
    this.deckId,
    this.deckName,
    this.embedded = false,
  });

  final ApiClient client;
  final int? deckId;
  final String? deckName;
  final bool embedded;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final StudyController _controller =
      StudyController(StudyApi(widget.client));

  @override
  void initState() {
    super.initState();
    _controller.load(deck: widget.deckId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (widget.deckId != null) _DeckBanner(name: widget.deckName ?? 'deck'),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _body(),
          ),
        ),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Study')),
      body: content,
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
              onPressed: () => _controller.load(deck: widget.deckId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final card = _controller.current;
    if (card == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('All caught up!', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _controller.load(deck: widget.deckId),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${_controller.index + 1} / ${_controller.queue.length}'
            '${card.isNew ? ' · new' : ''}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: _controller.reveal,
              child: Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.front,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_controller.revealed) ...[
                          const Divider(height: 32),
                          Text(
                            card.back,
                            style: TextStyle(fontSize: 24, color: accent),
                            textAlign: TextAlign.center,
                          ),
                          if (card.example.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              '“${card.example}”',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ] else
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'tap to reveal',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_controller.revealed)
            Row(
              children: [
                for (final g in _grades)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: g.color),
                        onPressed: _controller.grading
                            ? null
                            : () => _controller.grade(g.rating),
                        child: Text(g.label),
                      ),
                    ),
                  ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _controller.reveal,
                child: const Text('Reveal'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeckBanner extends StatelessWidget {
  const _DeckBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.style, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Studying $name',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('All decks'),
            ),
          ],
        ),
      ),
    );
  }
}
