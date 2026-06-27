import XCTest

final class EnScreenshotUITests: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    func testCaptureEnScreens() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-FORCE_UNLOCK", "1", "-YuzuriLocale", "en",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let startBtn = app.buttons["確認して始める"]
        if startBtn.waitForExistence(timeout: 4) { startBtn.tap(); sleep(1) }

        sleep(2)
        save(app.screenshot(), name: "en_01_home")

        for cell in app.scrollViews.buttons.allElementsBoundByIndex {
            if cell.exists && cell.isHittable { cell.tap(); sleep(2); break }
        }
        save(app.screenshot(), name: "en_02_category")
        app.navigationBars.buttons.firstMatch.tap(); sleep(1)

        if app.tabBars.buttons["書き出し"].waitForExistence(timeout: 3) {
            app.tabBars.buttons["書き出し"].tap(); sleep(2)
            save(app.screenshot(), name: "en_03_export")
        }
    }

    private func save(_ s: XCUIScreenshot, name: String) {
        let att = XCTAttachment(screenshot: s)
        att.name = name; att.lifetime = .keepAlways; add(att)
        let dir = "/Users/yanglichen/アプリケーション/Yuzuri/screenshots/en"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
    }
}
