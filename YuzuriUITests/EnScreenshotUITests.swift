import XCTest

final class EnScreenshotUITests: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    func testCaptureEnScreens() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-FORCE_UNLOCK", "1", "-YuzuriLocale", "en",
                                "-AppleLanguages", "(en-US)", "-AppleLocale", "en_US"]
        app.launch()

        // onboarding: try English first then Japanese fallback
        for title in ["Get started", "確認して始める"] {
            let btn = app.buttons[title]
            if btn.waitForExistence(timeout: 3) { btn.tap(); sleep(1); break }
        }

        sleep(3)
        save(app.screenshot(), name: "en_01_home")

        // tap first category cell
        for cell in app.scrollViews.buttons.allElementsBoundByIndex {
            if cell.exists && cell.isHittable { cell.tap(); sleep(2); break }
        }
        save(app.screenshot(), name: "en_02_category")

        // back
        if app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 2) {
            app.navigationBars.buttons.firstMatch.tap(); sleep(1)
        }

        // Export tab — try English then Japanese label
        for label in ["Export", "書き出し"] {
            let tab = app.tabBars.buttons[label]
            if tab.waitForExistence(timeout: 3) { tab.tap(); sleep(2); break }
        }
        save(app.screenshot(), name: "en_03_export")
    }

    private func save(_ s: XCUIScreenshot, name: String) {
        let att = XCTAttachment(screenshot: s)
        att.name = name; att.lifetime = .keepAlways; add(att)
        let dir = "/Users/yanglichen/アプリケーション/Yuzuri/screenshots/en"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
    }
}
