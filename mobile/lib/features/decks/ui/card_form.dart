import 'package:flutter/material.dart';

import '../data/card.dart';

/// Result of the add/edit card dialog. Empty optional fields are sent as ''.
class CardFormResult {
  CardFormResult({
    required this.front,
    required this.back,
    required this.partOfSpeech,
    required this.example,
    required this.description,
  });
  final String front;
  final String back;
  final String partOfSpeech;
  final String example;
  final String description;
}

/// Shows an add-or-edit card dialog, prefilled when [card] is given.
Future<CardFormResult?> showCardForm(BuildContext context, {DeckCard? card}) {
  return showDialog<CardFormResult>(
    context: context,
    builder: (context) => _CardFormDialog(card: card),
  );
}

class _CardFormDialog extends StatefulWidget {
  const _CardFormDialog({this.card});

  final DeckCard? card;

  @override
  State<_CardFormDialog> createState() => _CardFormDialogState();
}

class _CardFormDialogState extends State<_CardFormDialog> {
  late final _front = TextEditingController(text: widget.card?.front ?? '');
  late final _back = TextEditingController(text: widget.card?.back ?? '');
  late final _example = TextEditingController(text: widget.card?.example ?? '');
  late final _description =
      TextEditingController(text: widget.card?.description ?? '');
  late String _pos = widget.card?.partOfSpeech ?? 'other';

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _example.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final front = _front.text.trim();
    final back = _back.text.trim();
    if (front.isEmpty || back.isEmpty) return;
    Navigator.pop(
      context,
      CardFormResult(
        front: front,
        back: back,
        partOfSpeech: _pos,
        example: _example.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.card == null ? 'Add card' : 'Edit card'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _front,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Front'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _back,
              decoration: const InputDecoration(labelText: 'Back'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _pos,
              decoration: const InputDecoration(labelText: 'Part of speech'),
              items: [
                for (final p in partsOfSpeech)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _pos = v ?? 'other'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _example,
              decoration: const InputDecoration(labelText: 'Example (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
