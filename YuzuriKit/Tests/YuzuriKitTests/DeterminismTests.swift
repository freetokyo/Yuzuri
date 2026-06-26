import XCTest
@testable import YuzuriKit

// SeededRNG の基本動作テスト（エンジンは YuzuriKit に不要になったが RNG は残す）
final class DeterminismTests: XCTestCase {

    func testSameSeedSameSequence() {
        var rng1 = SeededRNG(seed: 42)
        var rng2 = SeededRNG(seed: 42)
        XCTAssertEqual(rng1.next(), rng2.next())
        XCTAssertEqual(rng1.next(), rng2.next())
    }

    func testDifferentSeedDiffers() {
        var rng1 = SeededRNG(seed: 1)
        var rng2 = SeededRNG(seed: 2)
        XCTAssertNotEqual(rng1.next(), rng2.next())
    }
}
