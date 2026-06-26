import XCTest

/// レビュー / ストア用スクリーンショット採取ハーネス。
///
/// 有料状態が必要な画面に到達するため、起動引数 `-FORCE_UNLOCK` を渡すと
/// EntitlementStore を解放状態にできる（アプリ側で読む実装を追加すること）。
///
/// iPad（iPadOS 26+）の TabView は XCUITest の `tabBars` に現れない既知制約があるため、
/// continueAfterFailure を true にし、取得できた分だけ使う。
final class ReviewScreenshotUITests: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    func testCaptureScreens() {
        let app = XCUIApplication()
        app.launchArguments += ["-FORCE_UNLOCK", "1"]
        app.launch()
        snapshot("01_home", app)
        if app.tabBars.buttons["設定"].waitForExistence(timeout: 5) {
            app.tabBars.buttons["設定"].tap()
            snapshot("02_settings", app)
        }
    }

    private func snapshot(_ name: String, _ app: XCUIApplication) {
        let shot = app.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }
}
