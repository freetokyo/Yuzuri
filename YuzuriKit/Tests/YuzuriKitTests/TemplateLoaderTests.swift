import XCTest
@testable import YuzuriKit

final class TemplateLoaderTests: XCTestCase {

    let bundle = Bundle.module

    func testEnResolvedCounts() throws {
        let cats = try TemplateLoader.resolved(for: "en", bundle: bundle)
        XCTAssertEqual(cats.count, 20, "en: カテゴリ数 20")
        let total = cats.flatMap { $0.fields }.count
        XCTAssertEqual(total, 68, "en: 総フィールド数 68")
    }

    func testJaResolvedCounts() throws {
        let cats = try TemplateLoader.resolved(for: "ja", bundle: bundle)
        XCTAssertEqual(cats.count, 20, "ja: カテゴリ数 20")
        let total = cats.flatMap { $0.fields }.count
        XCTAssertEqual(total, 72, "ja: 総フィールド数 72")
    }

    func testJaProfileHasRegisteredDomicileAfterPlaceOfBirth() throws {
        let cats = try TemplateLoader.resolved(for: "ja", bundle: bundle)
        let profile = try XCTUnwrap(cats.first { $0.categoryKey == "profile" })
        let keys = profile.fields.map { $0.fieldKey }
        guard let pbIdx = keys.firstIndex(of: "profile.placeOfBirth"),
              let rdIdx = keys.firstIndex(of: "profile.registeredDomicile") else {
            XCTFail("本籍 or placeOfBirth が見つからない")
            return
        }
        XCTAssertEqual(rdIdx, pbIdx + 1, "本籍は placeOfBirth の直後")
    }

    func testJaFuneralAdditions() throws {
        let cats = try TemplateLoader.resolved(for: "ja", bundle: bundle)
        let funeral = try XCTUnwrap(cats.first { $0.categoryKey == "funeral" })
        let keys = funeral.fields.map { $0.fieldKey }
        XCTAssertTrue(keys.contains("funeral.buddhistSect"), "宗派が存在")
        XCTAssertTrue(keys.contains("funeral.kouden"), "香典が存在")
        XCTAssertTrue(keys.contains("funeral.graveSuccession"), "お墓の承継が存在")

        // 宗派は religion の直後
        if let relIdx = keys.firstIndex(of: "funeral.religion"),
           let sectIdx = keys.firstIndex(of: "funeral.buddhistSect") {
            XCTAssertEqual(sectIdx, relIdx + 1)
        } else {
            XCTFail("funeral.religion が見つからない")
        }
    }

    func testUnsupportedLocaleFallsBackToEn() throws {
        let fr = try TemplateLoader.resolved(for: "fr", bundle: bundle)
        let en = try TemplateLoader.resolved(for: "en", bundle: bundle)
        XCTAssertEqual(fr.count, en.count)
        XCTAssertEqual(fr.flatMap { $0.fields }.count, en.flatMap { $0.fields }.count)
    }

    func testLocaleResolverUnsupportedOverrideUsesDeviceLang() {
        // 未対応 override は無視してデバイス言語へフォールバック（supported に含まれる値を返す）
        let result = LocaleResolver.resolve(override: "fr")
        XCTAssertTrue(LocaleResolver.supported.contains(result), "supported ロケールが返される: \(result)")
    }

    func testLocaleResolverJa() {
        let result = LocaleResolver.resolve(override: "ja")
        XCTAssertEqual(result, "ja")
    }
}
