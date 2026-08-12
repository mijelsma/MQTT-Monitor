import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_monitor/core/state/app_state.dart';
import 'package:mqtt_monitor/core/state/keys/layout_keys.dart';
import 'package:mqtt_monitor/core/state/keys/settings_keys.dart';
import 'package:mqtt_monitor/features/monitor/detail_sidebar_controller.dart';
import 'package:mqtt_monitor/models/sidebar_panel_default.dart';

import '../../support/test_dependencies.dart';

void main() {
  late TestDependencies dependencies;
  late AppStateManager state;

  setUp(() async {
    dependencies = await TestDependencies.create();
    state = dependencies.state;
  });

  test('startup defaults override last layout except for lastStatus', () async {
    await state.write(LayoutKeys.sidebarDetailCollapsed, true);
    await state.write(LayoutKeys.sidebarHistoryCollapsed, false);
    await state.write(LayoutKeys.sidebarPublishCollapsed, true);
    await state.write(LayoutKeys.sidebarShortcutsCollapsed, false);
    await state.write(
      SettingsKeys.defaultSidebarDetail,
      SidebarPanelDefault.expanded,
    );
    await state.write(
      SettingsKeys.defaultSidebarHistory,
      SidebarPanelDefault.collapsed,
    );
    await state.write(
      SettingsKeys.defaultSidebarPublish,
      SidebarPanelDefault.lastStatus,
    );
    await state.write(
      SettingsKeys.defaultSidebarShortcuts,
      SidebarPanelDefault.lastStatus,
    );

    final controller = DetailSidebarController(state);
    addTearDown(controller.dispose);

    expect(
      [for (var index = 0; index < 4; index++) controller.isCollapsed(index)],
      [false, true, true, false],
    );
  });

  test('collapsed state persists when layout persistence is enabled', () async {
    await state.write(SettingsKeys.persistLayout, true);
    final controller = DetailSidebarController(state);
    addTearDown(controller.dispose);

    controller.toggle(0);
    await Future<void>.delayed(Duration.zero);

    expect(state.read(LayoutKeys.sidebarDetailCollapsed), isTrue);
    expect(
      dependencies.preferences.get(LayoutKeys.sidebarDetailCollapsed.key),
      isTrue,
    );
  });

  test(
    'collapsed state remains runtime-only when persistence is disabled',
    () async {
      await state.write(SettingsKeys.persistLayout, false);
      final controller = DetailSidebarController(state);
      addTearDown(controller.dispose);

      controller.toggle(0);
      await Future<void>.delayed(Duration.zero);

      expect(state.read(LayoutKeys.sidebarDetailCollapsed), isTrue);
      expect(
        dependencies.preferences.get(LayoutKeys.sidebarDetailCollapsed.key),
        isNull,
      );
    },
  );
}
