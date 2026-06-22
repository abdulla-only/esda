import 'package:flutter/material.dart';

import '../../shared/api_client.dart';
import '../../shared/theme.dart';
import '../../shared/ui/glass.dart';
import '../controller/study_controller.dart';
import '../data/study_api.dart';

typedef _Grade = ({int rating, String label, Color Function(AuroraTokens) hue});

const _grades = <_Grade>[
  (rating: 1, label: 'Again', hue: _again),
  (rating: 2, label: 'Hard', hue: _hard),
  (rating: 3, label: 'Good', hue: _good),
  (rating: 4, label: 'Easy', hue: _easy),
];

Color _again(AuroraTokens t) => t.again;
Color _hard(AuroraTokens t) => t.hard;
Color _good(AuroraTokens t) => t.good;
Color _easy(AuroraTokens t) => t.easy;

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
    final t = AuroraTokens.of(context);
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
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          glow: t.brand,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _controller.load(deck: widget.deckId),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${_controller.index + 1} / ${_controller.queue.length}'
            '${card.isNew ? ' · new' : ''}',
            style: TextStyle(color: t.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GlassCard(
              glow: t.brand,
              onTap: _controller.reveal,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.front,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: t.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_controller.revealed) ...[
                        Divider(height: 32, color: t.glassBorder),
                        Text(
                          card.back,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: t.brandText,
                            shadows: [
                              Shadow(
                                color: t.brand.withValues(alpha: 0.6),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (card.example.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            '“${card.example}”',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: t.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'tap to reveal',
                            style: TextStyle(color: t.muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_controller.revealed)
            Row(
              children: [
                for (var i = 0; i < _grades.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _GradePill(
                        number: i + 1,
                        label: _grades[i].label,
                        hue: _grades[i].hue(t),
                        onPressed: _controller.grading
                            ? null
                            : () => _controller.grade(_grades[i].rating),
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

/// A grade choice as a frosted pill tinted by its hue, with a colored glow and a
/// small number chip echoing the desktop keyboard shortcuts.
class _GradePill extends StatelessWidget {
  const _GradePill({
    required this.number,
    required this.label,
    required this.hue,
    required this.onPressed,
  });

  final int number;
  final String label;
  final Color hue;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(16);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: hue.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: hue.withValues(alpha: 0.16),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: hue.withValues(alpha: 0.7)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hue.withValues(alpha: 0.22),
                    ),
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: hue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckBanner extends StatelessWidget {
  const _DeckBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = AuroraTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.style, size: 18, color: t.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Studying $name',
                style: TextStyle(fontWeight: FontWeight.w600, color: t.text),
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
