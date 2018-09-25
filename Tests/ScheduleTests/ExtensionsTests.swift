import XCTest
@testable import Schedule

final class ExtensionsTests: XCTestCase {

    func testClampedToInt() {
        let a: Double = 0.1
        XCTAssertEqual(a.clampedToInt(), 0)
    }

    func testClampedAdding() {
        let a: Int = 1
        let b: Int = .max
        XCTAssertEqual(a.clampedAdding(b), Int.max)
    }

    func testClampedSubtracting() {
        let a: Int = .min
        let b: Int = 1
        XCTAssertEqual(a.clampedSubtracting(b), Int.min)
    }

    func testZeroClock() {
        let z = Date().zeroToday()
        let components = z.dateComponents
        guard let h = components.hour, let m = components.minute, let s = components.second else {
            XCTFail()
            return
        }
        XCTAssertEqual(h, 0)
        XCTAssertEqual(m, 0)
        XCTAssertEqual(s, 0)
    }

    static var allTests = [
        ("testClampedToInt", testClampedToInt),
        ("testClampedAdding", testClampedAdding),
        ("testClampedSubtracting", testClampedSubtracting),
        ("testZeroClock", testZeroClock)
    ]
}
