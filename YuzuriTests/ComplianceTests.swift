import XCTest
@testable import Yuzuri

/// コンプライアンス文言テスト（禁止語 grep の機械検証）。
final class ComplianceTests: XCTestCase {

    func testDisclaimerNotEmpty() {
        XCTAssertFalse(Compliance.disclaimerShort.isEmpty)
        XCTAssertFalse(Compliance.disclaimerFull.isEmpty)
    }

    /// 免責に必須要素（推奨・勧誘の否定、自己責任、非保証）が含まれる。
    func testDisclaimerContainsRequiredElements() {
        let full = Compliance.disclaimerFull
        XCTAssertTrue(full.contains("推奨") && full.contains("勧誘"), "推奨・勧誘の否定が必要")
        XCTAssertTrue(full.contains("保証"), "成果非保証の明示が必要")
        XCTAssertTrue(full.contains("自己責任") || full.contains("ご自身の責任"), "自己責任の明示が必要")
    }

    /// 常置文に禁止語が含まれない。
    func testNoBannedWording() {
        let texts = [Compliance.disclaimerShort, Compliance.scopeNote]
        for t in texts {
            for b in Compliance.bannedInvestmentTerms {
                XCTAssertFalse(t.contains(b), "禁止語『\(b)』が含まれている: \(t)")
            }
        }
    }
}
