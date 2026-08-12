import 'package:flutter/material.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/bootstrap/app_bootstrap_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppBootstrapShell(bootstrap: ProductionAppBootstrap()));
}
