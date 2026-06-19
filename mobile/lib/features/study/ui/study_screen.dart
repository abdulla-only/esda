import 'package:flutter/material.dart';

import '../../auth/controller/auth_controller.dart';
import '../../auth/ui/login_screen.dart';
import '../../shared/api_client.dart';
import '../controller/study_controller.dart';
import '../data/study_api.dart';

const _grades = [
  (rating: 1, label: 'Again', color: Color(0xFFE64646)),
  (rating: 2, label: 'Hard', color: Color(0xFFE6A046)),
  (rating: 3, label: 'Good', color: Color(0xFF3AAF5C)),
  (rating: 4, label: 'Easy', color: Color(0xFF3390EC)),
];

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.client, required this.auth});

  final ApiClient client;
  final AuthController auth;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final StudyController _controller = StudyController(StudyApi(widget.client));

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

  Future<void> _logout() async {
    await widget.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(client: widget.client)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('esda'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: ListenableBuilder(listenable: _controller, builder: (context, _) => _body()),
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
            FilledButton(onPressed: _controller.load, child: const Text('Retry')),
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
            const Text('🎉 All caught up!', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _controller.load, child: const Text('Refresh')),
          ],
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
          if (_controller.revealed)
            Row(
              children: [
                for (final g in _grades)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: g.color),
                        onPressed: _controller.grading ? null : () => _controller.grade(g.rating),
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
