import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/features/monitor/controllers/detail_sidebar_controller.dart';
import 'package:mqtt_monitor/core/ui/models/sidebar_panel_default_model.dart';

import '../../../support/test_dependencies.dart';

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

  test('payload view mode survives selections but resets with a new app session', () {
    final controller = DetailSidebarController(dependencies.workspaceLayout, dependencies.uiPreferences);
    addTearDown(controller.dispose);

    controller.setPayloadViewMode(PayloadViewMode.bytes);
    expect(controller.payloadViewMode, PayloadViewMode.bytes);

    final nextSession = DetailSidebarController(dependencies.workspaceLayout, dependencies.uiPreferences);
    addTearDown(nextSession.dispose);
    expect(nextSession.payloadViewMode, PayloadViewMode.text);
  });

  test('startup defaults override last layout except for lastStatus', () async {
    await dependencies.workspaceLayout.setCollapsed(0, true);
    await dependencies.workspaceLayout.setCollapsed(1, false);
    await dependencies.workspaceLayout.setCollapsed(2, true);
    await dependencies.workspaceLayout.setCollapsed(3, false);
    await dependencies.uiPreferences.setDefaultSidebarDetail(SidebarPanelDefaultModel.expanded);
    await dependencies.uiPreferences.setDefaultSidebarHistory(SidebarPanelDefaultModel.collapsed);
    await dependencies.uiPreferences.setDefaultSidebarPublish(SidebarPanelDefaultModel.lastStatus);
    await dependencies.uiPreferences.setDefaultSidebarShortcuts(SidebarPanelDefaultModel.lastStatus);

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
