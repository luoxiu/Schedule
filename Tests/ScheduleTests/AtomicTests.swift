import XCTest
@testable import Schedule

final class AtomicTests: XCTestCase {

    func testRead() {
        let i = Atomic<Int>(1)
        let val = i.read { $0 }
        XCTAssertEqual(val, 1)
    }
    
    func testReadVoid() {
        let i = Atomic<Int>(1)
        var val = 0
        i.read { val = $0 }
        XCTAssertEqual(val, 1)
    }

    func testWrite() {
        let i = Atomic<Int>(1)
        let val = i.write { v -> Int in
            v += 1
            return v
        }
        XCTAssertEqual(i.read { $0 }, val)
    }
    
    func testWriteVoid() {
        let i = Atomic<Int>(1)
        var val = 0
        i.write {
            $0 += 1
            val = $0
        }
        XCTAssertEqual(i.read { $0 }, val)
    }

    static var allTests = [
        ("testRead", testRead),
        ("testReadVoid", testReadVoid),
        ("testWrite", testWrite),
        ("testWriteVoid", testWriteVoid),
    ]
}
