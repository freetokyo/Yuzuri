import XCTest
@testable import YuzuriKit

final class ArchiveManagerTests: XCTestCase {

    func testExportImportRoundTrip() throws {
        let cats = [
            CategoryArchive(
                categoryKey: "profile",
                structuredValues: ["profile.fullName": "山田太郎", "profile.birthDate": "1960-01-15"],
                freeText: "メモです",
                userMarkedDone: true,
                updatedAt: Date(timeIntervalSince1970: 0)
            )
        ]
        let payload = ArchivePayload(version: 1, exportedAt: Date(timeIntervalSince1970: 0), categories: cats)
        let data = try ArchiveManager.export(payload: payload, passphrase: "test-passphrase-123")
        XCTAssertFalse(data.isEmpty)

        let restored = try ArchiveManager.import(data: data, passphrase: "test-passphrase-123")
        XCTAssertEqual(restored.version, 1)
        XCTAssertEqual(restored.categories.count, 1)
        XCTAssertEqual(restored.categories[0].structuredValues["profile.fullName"], "山田太郎")
        XCTAssertEqual(restored.categories[0].freeText, "メモです")
        XCTAssertTrue(restored.categories[0].userMarkedDone)
    }

    func testWrongPassphraseFails() throws {
        let payload = ArchivePayload(categories: [
            CategoryArchive(categoryKey: "test", structuredValues: [:],
                            freeText: "", userMarkedDone: false, updatedAt: .now)
        ])
        let data = try ArchiveManager.export(payload: payload, passphrase: "correct")
        XCTAssertThrowsError(try ArchiveManager.import(data: data, passphrase: "wrong")) { error in
            // AES-GCM の認証タグ失敗 = 復号エラーが期待される
            XCTAssertNotNil(error)
        }
    }

    func testInvalidFormatFails() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        XCTAssertThrowsError(try ArchiveManager.import(data: garbage, passphrase: "any")) { error in
            XCTAssertTrue(error is ArchiveError)
        }
    }
}
