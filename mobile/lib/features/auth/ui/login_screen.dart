import 'package:flutter/material.dart';

import '../../home/ui/home_screen.dart';
import '../../shared/api_client.dart';
import '../../shared/theme.dart';
import '../../shared/ui/glass.dart';
import '../controller/auth_controller.dart';
import '../data/auth_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.client, required this.theme});

  final ApiClient client;
  final ThemeController theme;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _controller = AuthController(AuthApi(widget.client));
  final _email = TextEditingController(text: 'demo@esda.app');
  final _password = TextEditingController();
  bool _register = false;

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _register
        ? await _controller.register(_email.text, _password.text)
        : await _controller.login(_email.text, _password.text);
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              HomeScreen(client: widget.client, theme: widget.theme),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AuroraTokens.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => GlassCard(
                glow: t.brand,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _register ? 'Create your esda account' : 'Sign in to esda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: t.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 8),
                    if (_controller.error != null)
                      Text(
                        _controller.error!,
                        style: TextStyle(color: t.again),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _controller.busy ? null : _submit,
                        child: Text(
                          _controller.busy
                              ? (_register ? 'Creating…' : 'Signing in…')
                              : (_register ? 'Create account' : 'Sign in'),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _controller.busy
                          ? null
                          : () => setState(() => _register = !_register),
                      child: Text(
                        _register
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
