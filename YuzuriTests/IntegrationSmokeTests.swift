import XCTest
import YuzuriKit
@testable import Yuzuri

/// テンプレートロード統合スモーク（アプリバンドルから実際にロードできるか）。
final class IntegrationSmokeTests: XCTestCase {

    func testTemplateLoadFromAppBundle() throws {
        let cats = try TemplateLoader.resolved(for: "ja", bundle: .main)
        XCTAssertEqual(cats.count, 20, "ja: カテゴリ 20 件")
        XCTAssertGreaterThan(cats.flatMap { $0.fields }.count, 0)
    }

    func testProgressCalculatorSmoke() throws {
        let cats = try TemplateLoader.resolved(for: "ja", bundle: .main)
        let calc = ProgressCalculator()
        let rate = calc.overallRate(categories: cats, entries: [:])
        XCTAssertEqual(rate, 0.0)
    }

    func testNoteEntrySnapshotRoundTrip() {
        let entry = NoteEntry(categoryKey: "profile")
        entry.structuredValues["profile.fullName"] = "山田太郎"
        let snap = entry.snapshot()
        XCTAssertEqual(snap.structuredValues["profile.fullName"], "山田太郎")
    }
}
