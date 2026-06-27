import XCTest

/// ストア用スクリーンショット採取（3画面：ホーム・カテゴリ入力・書き出し）。
final class ReviewScreenshotUITests: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    func testCaptureScreens() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-FORCE_UNLOCK", "1",
                                "-YuzuriLocale", "ja",
                                "-AppleLanguages", "(ja)",
                                "-AppleLocale", "ja_JP"]
        app.launch()

        // onboarding がある場合は閉じる
        let startBtn = app.buttons["確認して始める"]
        if startBtn.waitForExistence(timeout: 4) { startBtn.tap(); sleep(1) }

        // 01: ホーム（カテゴリ一覧・記入率）
        sleep(2)
        save(app.screenshot(), name: "01_home")

        // 02: カテゴリ詳細（基本情報 or 先頭カテゴリをタップ）
        let cells = app.scrollViews.buttons.allElementsBoundByIndex +
                    app.tables.cells.allElementsBoundByIndex +
                    app.collectionViews.cells.allElementsBoundByIndex
        // アクセシビリティIDで先頭カテゴリを探す
        var tappedCategory = false
        for cell in app.scrollViews.buttons.allElementsBoundByIndex {
            if cell.exists && cell.isHittable {
                cell.tap(); sleep(2)
                tappedCategory = true
                break
            }
        }
        if tappedCategory {
            save(app.screenshot(), name: "02_category")
            app.navigationBars.buttons.firstMatch.tap(); sleep(1)
        }

        // 03: 書き出しタブ
        let exportTab = app.tabBars.buttons["書き出し"]
        if exportTab.waitForExistence(timeout: 3) {
            exportTab.tap(); sleep(2)
            save(app.screenshot(), name: "03_export")
        }
    }

    private func save(_ screenshot: XCUIScreenshot, name: String) {
        let att = XCTAttachment(screenshot: screenshot)
        att.name = name; att.lifetime = .keepAlways
        add(att)
        // ファイルにも書き出す
        let dir = "/Users/yanglichen/アプリケーション/Yuzuri/screenshots/6.9"
        let url = URL(fileURLWithPath: "\(dir)/\(name).png")
        try? screenshot.pngRepresentation.write(to: url)
    }
}
