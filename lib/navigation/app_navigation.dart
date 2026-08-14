import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/controllers/settings_navigation_controller.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_section.dart';

typedef DashboardPageBuilder = Widget Function(String brokerId, String brokerName);

/// Centralizes the application's two top-level route workflows.
class AppNavigation {
  AppNavigation(this._settings, {WidgetBuilder? settingsPageBuilder, DashboardPageBuilder? dashboardPageBuilder}) : _settingsPageBuilder = settingsPageBuilder ?? ((_) => const SettingsScreen()), _dashboardPageBuilder = dashboardPageBuilder ?? ((brokerId, brokerName) => GraphDashboardScreen(brokerId: brokerId, brokerName: brokerName));

  final SettingsNavigationController _settings;
  final WidgetBuilder _settingsPageBuilder;
  final DashboardPageBuilder _dashboardPageBuilder;

  Future<T?> openSettings<T>(BuildContext context, {SettingsSection section = SettingsSection.brokers}) {
    _settings.select(section);
    return Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: _settingsPageBuilder));
  }

  Future<T?> openDashboard<T>(BuildContext context, {required String brokerId, required String brokerName}) {
    return Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => _dashboardPageBuilder(brokerId, brokerName)));
  }
}
