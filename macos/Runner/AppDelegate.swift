import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var statusMenuController: FlowTomatoStatusMenuController?

  func installStatusMenu(window: NSWindow, flutterViewController: FlutterViewController) {
    if statusMenuController != nil {
      return
    }
    let channel = FlutterMethodChannel(
      name: "flow_tomato/menu_bar",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    let controller = FlowTomatoStatusMenuController(
      channel: channel,
      window: mainFlutterWindow
    )
    channel.setMethodCallHandler { [weak controller] call, result in
      switch call.method {
      case "updatePomodoro":
        if let payload = call.arguments as? [String: Any] {
          controller?.updatePomodoro(payload)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    statusMenuController = controller
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      mainFlutterWindow?.makeKeyAndOrderFront(nil)
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

final class FlowTomatoStatusMenuController: NSObject {
  private let channel: FlutterMethodChannel
  private weak var window: NSWindow?
  private let statusItem: NSStatusItem
  private let menu = NSMenu()
  private let statusMenuItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
  private let detailMenuItem = NSMenuItem(title: "Focus session", action: nil, keyEquivalent: "")
  private let progressMenuItem = NSMenuItem(title: "Progress 0%", action: nil, keyEquivalent: "")
  private let pauseMenuItem = NSMenuItem(title: "Pause", action: #selector(pauseTimer), keyEquivalent: "")
  private let resumeMenuItem = NSMenuItem(title: "Resume", action: #selector(resumeTimer), keyEquivalent: "")
  private let resetMenuItem = NSMenuItem(title: "Reset", action: #selector(resetTimer), keyEquivalent: "")
  private let showWindowMenuItem = NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "")
  private let quitMenuItem = NSMenuItem(title: "Quit FlowTomato...", action: #selector(confirmQuit), keyEquivalent: "")

  init(channel: FlutterMethodChannel, window: NSWindow?) {
    self.channel = channel
    self.window = window
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()
    configureMenu()
  }

  func updatePomodoro(_ payload: [String: Any]) {
    let menuBarTitle = payload["menuBarTitle"] as? String ?? "FlowTomato"
    let statusLabel = payload["statusLabel"] as? String ?? "Ready"
    let timeLabel = payload["timeLabel"] as? String ?? "25:00"
    let detailLabel = payload["detailLabel"] as? String ?? "Focus session"
    let progress = payload["progress"] as? Double ?? 0

    statusItem.button?.title = menuBarTitle
    statusMenuItem.title = "\(statusLabel) · \(timeLabel)"
    detailMenuItem.title = detailLabel
    progressMenuItem.title = "Progress \(Int((progress * 100).rounded()))%"
    pauseMenuItem.isEnabled = payload["canPause"] as? Bool ?? false
    resumeMenuItem.isEnabled = payload["canResume"] as? Bool ?? false
    resetMenuItem.isEnabled = payload["canReset"] as? Bool ?? false
  }

  private func configureMenu() {
    statusItem.button?.title = "FlowTomato"
    statusItem.button?.toolTip = "FlowTomato"

    statusMenuItem.isEnabled = false
    detailMenuItem.isEnabled = false
    progressMenuItem.isEnabled = false

    pauseMenuItem.target = self
    resumeMenuItem.target = self
    resetMenuItem.target = self
    showWindowMenuItem.target = self
    quitMenuItem.target = self

    menu.addItem(statusMenuItem)
    menu.addItem(detailMenuItem)
    menu.addItem(progressMenuItem)
    menu.addItem(NSMenuItem.separator())
    menu.addItem(pauseMenuItem)
    menu.addItem(resumeMenuItem)
    menu.addItem(resetMenuItem)
    menu.addItem(NSMenuItem.separator())
    menu.addItem(showWindowMenuItem)
    menu.addItem(quitMenuItem)
    statusItem.menu = menu
  }

  @objc private func pauseTimer() {
    channel.invokeMethod("pause", arguments: nil)
  }

  @objc private func resumeTimer() {
    channel.invokeMethod("resume", arguments: nil)
  }

  @objc private func resetTimer() {
    channel.invokeMethod("reset", arguments: nil)
  }

  @objc private func showWindow() {
    guard let window else {
      return
    }
    if window.isMiniaturized {
      window.deminiaturize(nil)
    }
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc private func confirmQuit() {
    let alert = NSAlert()
    alert.messageText = "Quit FlowTomato?"
    alert.informativeText = "The current Pomodoro timer will stop when the app quits."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Quit")
    alert.addButton(withTitle: "Cancel")
    if alert.runModal() == .alertFirstButtonReturn {
      NSApp.terminate(nil)
    }
  }
}
