# Platform support

MQTT Monitor is a desktop product. The supported release matrix is macOS,
Windows, and Linux. Every release change must keep all three targets buildable.

| Platform | Supported release target | Distribution contract |
| --- | --- | --- |
| macOS | macOS 10.15 or newer | Developer ID signed, hardened, notarized, stapled DMG for Intel and Apple silicon |
| Windows | Windows 10 and Windows 11, x64 | Per-user Inno Setup installer with normal Start Menu and uninstall integration |
| Linux | Ubuntu 20.04 through 24.04 LTS, x64 | Relocatable zip; CI builds and tests on Ubuntu 22.04 |

Android, iOS, and web directories remain dormant Flutter scaffolding. They are
not supported release targets and are not built by release CI.

## Windows installation

Windows releases are installer-only. The public artifact is
`mqtt-monitor-VERSION-windows-setup.exe`; a portable Windows zip is not part of
the release contract. The installer uses a stable application identity, a
modern wizard, the MQTT Monitor icon, a license page, a Start Menu shortcut,
an optional desktop shortcut, launch-after-install, and a standard uninstall
entry.

Installation is per-user by default, so it does not require administrator
access. Automatic updates stage the same installer, preserve the existing
installation directory, run it silently, and relaunch the application.

The installer is not yet Authenticode signed. Signing the application files
and final installer, timestamping the signatures, and enforcing the expected
certificate thumbprint are mandatory gates before the public 1.0 release.

## Application data

Settings remain in Flutter's platform-native `shared_preferences` backend.
Broker passwords remain in protected operating-system credential storage, and
imported certificates remain in the app-owned application-support directory.
No second JSON settings format or development-to-development directory
migration is used.

| Data | macOS | Windows | Linux |
| --- | --- | --- | --- |
| Preferences | `NSUserDefaults` for `com.micheljelsma.mqttmonitor` | `%APPDATA%\Michel Jelsma\MQTT Monitor\shared_preferences.json` | `$XDG_DATA_HOME/com.micheljelsma.mqttmonitor/shared_preferences.json` |
| Broker passwords | Keychain | Operating-system secure credential storage | Secret Service/libsecret |
| Imported certificates | `Library/Application Support/MQTT-Monitor` | `%APPDATA%\MQTT-Monitor` | `$XDG_DATA_HOME/MQTT-Monitor` |

The Dart, macOS, and Windows title-bar implementations share the
`mqtt_monitor/window_chrome` channel and `setAppearance` method. Linux uses its
GTK title bar instead.
