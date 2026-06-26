import XCTest
@testable import YuzuriKit

final class ProgressCalculatorTests: XCTestCase {

    let calc = ProgressCalculator()

    private func makeCategories() -> [CategoryDef] {
        [
            CategoryDef(
                categoryKey: "profile",
                labelKey: "cat.profile",
                defaultLabel: "Profile",
                order: 1,
                fields: [
                    FieldDef(fieldKey: "profile.name", labelKey: "k", defaultLabel: "Name", type: "text", defaultSensitive: false),
                    FieldDef(fieldKey: "profile.secret", labelKey: "k", defaultLabel: "Secret", type: "sensitive", defaultSensitive: true),
                ]
            )
        ]
    }

    func testProgressExcludesSensitive() {
        let cats = makeCategories()
        let entries: [String: EntrySnapshot] = [:]
        // sensitive field は母数に含まれない → 母数=1
        let rate = calc.overallRate(categories: cats, entries: entries)
        XCTAssertEqual(rate, 0.0)
    }

    func testProgressUpdatesOnEdit() {
        let cats = makeCategories()
        let entries: [String: EntrySnapshot] = [
            "profile": EntrySnapshot(categoryKey: "profile",
                                     structuredValues: ["profile.name": "Alice"])
        ]
        let rate = calc.overallRate(categories: cats, entries: entries)
        XCTAssertEqual(rate, 1.0)
    }

    func testCategoryBadgeStates() {
        let cats = makeCategories()
        let cat = cats[0]

        XCTAssertEqual(calc.categoryStatus(category: cat, entry: nil), .empty)

        let partial = EntrySnapshot(categoryKey: "profile",
                                    structuredValues: ["profile.name": "Bob"])
        XCTAssertEqual(calc.categoryStatus(category: cat, entry: partial), .done) // 1 non-sensitive field filled = 100%

        let empty = EntrySnapshot(categoryKey: "profile", structuredValues: [:])
        XCTAssertEqual(calc.categoryStatus(category: cat, entry: empty), .empty)
    }

    func testUserMarkedDoneOverrides() {
        let cats = makeCategories()
        let entry = EntrySnapshot(categoryKey: "profile", structuredValues: [:], userMarkedDone: true)
        XCTAssertEqual(calc.categoryStatus(category: cats[0], entry: entry), .done)
    }
}
