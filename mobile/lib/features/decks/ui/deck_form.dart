import 'package:flutter/material.dart';

import '../data/language.dart';

/// Result of the create/rename deck dialog.
class DeckFormResult {
  DeckFormResult({required this.name, required this.language});
  final String name;
  final int language;
}

/// Shows a create-or-rename deck dialog. When [lockedLanguage] is set the
/// language picker is hidden (rename keeps the existing language).
Future<DeckFormResult?> showDeckForm(
  BuildContext context, {
  required List<Language> languages,
  String? initialName,
  int? lockedLanguage,
}) {
  return showDialog<DeckFormResult>(
    context: context,
    builder: (context) => _DeckFormDialog(
      languages: languages,
      initialName: initialName,
      lockedLanguage: lockedLanguage,
    ),
  );
}

class _DeckFormDialog extends StatefulWidget {
  const _DeckFormDialog({
    required this.languages,
    this.initialName,
    this.lockedLanguage,
  });

  final List<Language> languages;
  final String? initialName;
  final int? lockedLanguage;

  @override
  State<_DeckFormDialog> createState() => _DeckFormDialogState();
}

class _DeckFormDialogState extends State<_DeckFormDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName ?? '');
  late int? _language =
      widget.lockedLanguage ?? widget.languages.firstOrNull?.id;

  bool get _isRename => widget.lockedLanguage != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty || _language == null) return;
    Navigator.pop(
      context,
      DeckFormResult(name: name, language: _language!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isRename ? 'Rename deck' : 'New deck'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (_) => _submit(),
          ),
          if (!_isRename) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: [
                for (final l in widget.languages)
                  DropdownMenuItem(value: l.id, child: Text(l.name)),
              ],
              onChanged: (v) => setState(() => _language = v),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isRename ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
