import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.delegate = self

    RegisterGeneratedPlugins(registry: flutterViewController)
    if let appDelegate = NSApp.delegate as? AppDelegate {
      appDelegate.installStatusMenu(
        window: self,
        flutterViewController: flutterViewController
      )
    }

    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.orderOut(nil)
    return false
  }
}
