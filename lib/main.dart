import 'package:flutter/material.dart';

import 'application/bootstrap/app_bootstrap.dart';
import 'application/bootstrap/app_bootstrap_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppBootstrapShell(bootstrap: ProductionAppBootstrap()));
}
