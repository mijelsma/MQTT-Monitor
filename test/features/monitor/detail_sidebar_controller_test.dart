import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/features/monitor/detail_sidebar_controller.dart';
import 'package:mqtt_monitor/models/sidebar_panel_default.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;

  setUp(() async {
    dependencies = await TestDependencies.create();
  });

  test('fresh sidebar defaults start with publish collapsed', () {
    final controller = DetailSidebarController(dependencies.workspaceLayout, dependencies.uiPreferences);
    addTearDown(controller.dispose);

    expect([for (var index = 0; index < 4; index++) controller.isCollapsed(index)], [false, true, true, true]);
  });

  test('startup defaults override last layout except for lastStatus', () async {
    await dependencies.workspaceLayout.setCollapsed(0, true);
    await dependencies.workspaceLayout.setCollapsed(1, false);
    await dependencies.workspaceLayout.setCollapsed(2, true);
    await dependencies.workspaceLayout.setCollapsed(3, false);
    await dependencies.uiPreferences.setDefaultSidebarDetail(SidebarPanelDefault.expanded);
    await dependencies.uiPreferences.setDefaultSidebarHistory(SidebarPanelDefault.collapsed);
    await dependencies.uiPreferences.setDefaultSidebarPublish(SidebarPanelDefault.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarShortcuts(SidebarPanelDefault.lastStatus);

    final controller = DetailSidebarController(dependencies.workspaceLayout, dependencies.uiPreferences);
    addTearDown(controller.dispose);

    expect([for (var index = 0; index < 4; index++) controller.isCollapsed(index)], [false, true, true, false]);
  });

  test('collapsed state persists when layout persistence is enabled', () async {
    await dependencies.uiPreferences.setPersistLayout(true);
    dependencies.workspaceLayout.setPersistenceEnabled(true);
    final controller = DetailSidebarController(dependencies.workspaceLayout, dependencies.uiPreferences);
    addTearDown(controller.dispose);

    controller.toggle(0);
    await Future<void>.delayed(Duration.zero);

    expect(dependencies.workspaceLayout.collapsed.first, isTrue);
    expect(dependencies.preferences.get('layout.sidebarDetailCollapsed'), isTrue);
  });

  test('collapsed state remains runtime-only when persistence is disabled', () async {
    await dependencies.uiPreferences.setPersistLayout(false);
    dependencies.workspaceLayout.setPersistenceEnabled(false);
    final controller = DetailSidebarController(dependencies.workspaceLayout, dependencies.uiPreferences);
    addTearDown(controller.dispose);

    controller.toggle(0);
    await Future<void>.delayed(Duration.zero);

    expect(dependencies.workspaceLayout.collapsed.first, isTrue);
    expect(dependencies.preferences.get('layout.sidebarDetailCollapsed'), isNull);
  });
}
