import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/repositories/ui_preferences_repository.dart';
import 'controllers/window_chrome_controller.dart';

/// Synchronizes native chrome and owns the platform brightness callback.
class WindowChromeLifecycle extends StatefulWidget {
  const WindowChromeLifecycle({super.key, required this.preferences, required this.controller, required this.child});

  final UiPreferencesRepository preferences;
  final WindowChromeController controller;
  final Widget child;

  @override
  State<WindowChromeLifecycle> createState() => _WindowChromeLifecycleState();
}

class _WindowChromeLifecycleState extends State<WindowChromeLifecycle> {
  Brightness? _lastAppearance;

  Brightness get _effectiveBrightness {
    final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return switch (widget.preferences.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
  }

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_syncAppearance);
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = _syncAppearance;
    _syncAppearance();
  }

  @override
  void didUpdateWidget(WindowChromeLifecycle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.preferences, widget.preferences)) {
      oldWidget.preferences.removeListener(_syncAppearance);
      widget.preferences.addListener(_syncAppearance);
      _lastAppearance = null;
      _syncAppearance();
    }
  }

  void _syncAppearance() {
    final brightness = _effectiveBrightness;
    if (brightness == _lastAppearance) return;
    _lastAppearance = brightness;
    unawaited(widget.controller.setAppearance(brightness));
  }

  @override
  void dispose() {
    widget.preferences.removeListener(_syncAppearance);
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
