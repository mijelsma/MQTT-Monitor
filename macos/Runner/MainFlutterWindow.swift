import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "mqtt_monitor/window_chrome",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setAppearance" else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.arguments as? String {
      case "dark":
        self?.appearance = NSAppearance(named: .darkAqua)
      case "light":
        self?.appearance = NSAppearance(named: .aqua)
      default:
        self?.appearance = nil
      }
      result(nil)
    }

    super.awakeFromNib()
  }
}
