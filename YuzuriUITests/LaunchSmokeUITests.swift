import XCTest

/// 起動スモーク: 落ちずにホームが出ることだけ確認。
final class LaunchSmokeUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
