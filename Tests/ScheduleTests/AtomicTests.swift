import XCTest
@testable import Schedule

final class AtomicTests: XCTestCase {

    func testSnapshot() {
        let i = Atomic<Int>(1)
        XCTAssertEqual(i.snapshot(), 1)
    }

    func testRead() {
        let i = Atomic<Int>(1)
        i.read {
            XCTAssertEqual($0, 1)
        }
    }

    func testWrite() {
        let i = Atomic<Int>(1)
        i.write {
            $0 += 1
        }
        XCTAssertEqual(i.snapshot(), 2)
    }

    static var allTests = [
        ("testSnapshot", testSnapshot),
        ("testRead", testRead),
        ("testWrite", testWrite)
    ]
}
