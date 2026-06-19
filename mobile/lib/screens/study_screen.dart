import 'package:flutter/material.dart';

import '../models/study_card.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

const _grades = [
  (rating: 1, label: 'Again', color: Color(0xFFE64646)),
  (rating: 2, label: 'Hard', color: Color(0xFFE6A046)),
  (rating: 3, label: 'Good', color: Color(0xFF3AAF5C)),
  (rating: 4, label: 'Easy', color: Color(0xFF3390EC)),
];

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<StudyCard> _queue = [];
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  bool _grading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cards = await widget.api.studyQueue(limit: 30);
      setState(() {
        _queue = cards;
        _index = 0;
        _revealed = false;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _grade(int rating) async {
    if (_grading || _index >= _queue.length) return;
    setState(() => _grading = true);
    try {
      await widget.api.grade(_queue[_index].id, rating);
      if (_index + 1 < _queue.length) {
        setState(() {
          _index++;
          _revealed = false;
        });
      } else {
        await _load();
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _grading = false);
    }
  }

  Future<void> _logout() async {
    await widget.api.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('esda'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_index >= _queue.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉 All caught up!', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Refresh')),
          ],
        ),
      );
    }

    final card = _queue[_index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${_index + 1} / ${_queue.length}${card.isNew ? ' · new' : ''}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _revealed = true),
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
                        if (_revealed) ...[
                          const Divider(height: 32),
                          Text(
                            card.back,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xFF3390EC),
                            ),
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
          if (_revealed)
            Row(
              children: [
                for (final g in _grades)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: g.color),
                        onPressed: _grading ? null : () => _grade(g.rating),
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
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Reveal'),
              ),
            ),
        ],
      ),
    );
  }
}
