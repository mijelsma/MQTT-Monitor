import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_update_service.dart';

/// Owns the process-lifetime updater and starts discovery after the first frame.
class AppUpdateLifecycle extends StatefulWidget {
  const AppUpdateLifecycle({
    super.key,
    required this.create,
    required this.child,
  });

  final AppUpdateService Function() create;
  final Widget child;

  @override
  State<AppUpdateLifecycle> createState() => _AppUpdateLifecycleState();
}

class _AppUpdateLifecycleState extends State<AppUpdateLifecycle> {
  late final AppUpdateService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.create();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.checkForUpdatesOnStartup();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppUpdateService>.value(
      value: _service,
      child: widget.child,
    );
  }
}
