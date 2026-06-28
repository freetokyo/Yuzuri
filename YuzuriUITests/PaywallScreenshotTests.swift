import XCTest
final class PaywallScreenshotTests: XCTestCase {
    override func setUp() { continueAfterFailure = true }
    func testPaywallScreenshot() {
        let app = XCUIApplication()
        app.launchArguments += ["-FORCE_UNLOCK", "1", "-YuzuriLocale", "ja"]
        app.launch()
        sleep(3)
        // 書き出しタブへ
        for label in ["書き出し", "Export"] {
            if app.tabBars.buttons[label].waitForExistence(timeout: 3) {
                app.tabBars.buttons[label].tap(); sleep(2); break
            }
        }
        // Paywall ボタンをタップ
        for label in ["PDF書き出し（プレミアム機能）", "PDF export (Premium)"] {
            if app.buttons[label].waitForExistence(timeout: 3) {
                app.buttons[label].tap(); sleep(2); break
            }
        }
        let shot = app.screenshot()
        let dir = "/tmp"
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/paywall_ja.png"))
        let att = XCTAttachment(screenshot: shot)
        att.lifetime = .keepAlways; add(att)
    }
}
