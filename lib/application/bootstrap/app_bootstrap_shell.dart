import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import 'app_bootstrap.dart';
import 'app_lifetime.dart';

/// Presents initialization progress, retryable failure, and the running app.
class AppBootstrapShell extends StatefulWidget {
  const AppBootstrapShell({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<AppBootstrapShell> createState() => _AppBootstrapShellState();
}

class _AppBootstrapShellState extends State<AppBootstrapShell> {
  late Future<AppLifetime> _initialization;
  AppLifetime? _lifetime;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _initialization = widget.bootstrap.initialize();
    unawaited(
      _initialization.then((lifetime) {
        if (!mounted) {
          return lifetime.dispose();
        }
        _lifetime = lifetime;
      }, onError: (_) {}),
    );
  }

  void _retry() {
    setState(_start);
  }

  @override
  void dispose() {
    final lifetime = _lifetime;
    if (lifetime != null) unawaited(lifetime.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppLifetime>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasData) return App(lifetime: snapshot.requireData);
        if (snapshot.hasError) {
          final error = snapshot.error;
          final stage = error is AppInitializationFailure ? error.stage : 'startup';
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 42),
                        const SizedBox(height: 16),
                        const Text('MQTT Monitor could not start', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Initialization failed during $stage. You can retry without restarting the app.', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        FilledButton(onPressed: _retry, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}
