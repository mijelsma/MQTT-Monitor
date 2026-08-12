import 'package:flutter/widgets.dart';

import 'app_update_service.dart';

/// Starts quiet update discovery after the first application frame.
///
/// Resource disposal belongs to the application lifetime owner.
class AppUpdateLifecycle extends StatefulWidget {
  const AppUpdateLifecycle({super.key, required this.service, required this.child});

  final AppUpdateService service;
  final Widget child;

  @override
  State<AppUpdateLifecycle> createState() => _AppUpdateLifecycleState();
}

class _AppUpdateLifecycleState extends State<AppUpdateLifecycle> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.service.checkForUpdatesOnStartup();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
