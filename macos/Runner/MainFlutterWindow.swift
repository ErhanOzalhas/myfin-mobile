import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    
    // iPhone 13 mini Boyutları (375 x 812)
    self.setFrame(NSRect(x: 0, y: 0, width: 375, height: 812), display: true)
    
    // Pencereyi ekranın ortasına taşır
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
