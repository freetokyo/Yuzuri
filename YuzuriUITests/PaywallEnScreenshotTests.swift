import XCTest
final class PaywallEnScreenshotTests: XCTestCase {
    override func setUp() { continueAfterFailure = true }
    func testPaywallEnScreenshot() {
        let app = XCUIApplication()
        app.launchArguments += ["-FORCE_UNLOCK", "1", "-YuzuriLocale", "en",
                                "-AppleLanguages", "(en-US)", "-AppleLocale", "en_US"]
        app.launch()
        sleep(3)
        for label in ["Export", "書き出し"] {
            if app.tabBars.buttons[label].waitForExistence(timeout: 3) {
                app.tabBars.buttons[label].tap(); sleep(2); break
            }
        }
        for label in ["PDF export (Premium)", "PDF書き出し（プレミアム機能）"] {
            if app.buttons[label].waitForExistence(timeout: 3) {
                app.buttons[label].tap(); sleep(2); break
            }
        }
        let shot = app.screenshot()
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/paywall_en.png"))
        let att = XCTAttachment(screenshot: shot); att.lifetime = .keepAlways; add(att)
    }
}
