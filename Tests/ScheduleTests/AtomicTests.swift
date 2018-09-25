import XCTest
@testable import Schedule

final class AtomicTests: XCTestCase {

    func testRead() {
        let atom = Atomic<Int>(1)
        atom.read {
            XCTAssertEqual($0, 1)
        }
    }

    func testWrite() {
        let atom = Atomic<Int>(1)
        atom.write {
            $0 = 2
        }
        atom.read {
            XCTAssertEqual($0, 2)
        }
    }

    static var allTests = [
        ("testRead", testRead),
        ("testWrite", testWrite)
    ]
}
