import XCTest
@testable import Schedule

final class BagTests: XCTestCase {

    typealias Fn = () -> Int

    func testBagKey() {
        var g = BagKeyGenerator()
        let k1 = g.next()
        let k2 = g.next()
        XCTAssertNotNil(k1)
        XCTAssertNotNil(k2)
        XCTAssertNotEqual(k1, k2)
    }

    func testAppend() {
        var cabinet = Bag<Fn>()
        cabinet.append { 1 }
        cabinet.append { 2 }

        XCTAssertEqual(cabinet.count, 2)
    }

    func testGet() {
        var cabinet = Bag<Fn>()
        let k1 = cabinet.append { 1 }
        let k2 = cabinet.append { 2 }

        guard
            let fn1 = cabinet.get(k1),
            let fn2 = cabinet.get(k2)
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(fn1(), 1)
        XCTAssertEqual(fn2(), 2)
    }

    func testDelete() {
        var cabinet = Bag<Fn>()

        let k1 = cabinet.append { 1 }
        let k2 = cabinet.append { 2 }

        XCTAssertEqual(cabinet.count, 2)

        let fn1 = cabinet.delete(k1)
        XCTAssertNotNil(fn1)

        let fn2 = cabinet.delete(k2)
        XCTAssertNotNil(fn2)

        XCTAssertEqual(cabinet.count, 0)
    }

    func testClear() {
        var cabinet = Bag<Fn>()

        cabinet.append { 1 }
        cabinet.append { 2 }

        XCTAssertEqual(cabinet.count, 2)

        cabinet.clear()
        XCTAssertEqual(cabinet.count, 0)
    }

    func testSequence() {
        var cabinet = Bag<Fn>()
        cabinet.append { 0 }
        cabinet.append { 1 }
        cabinet.append { 2 }

        var i = 0
        for fn in cabinet {
            XCTAssertEqual(fn(), i)
            i += 1
        }
    }

    static var allTests = [
        ("testBagKey", testBagKey),
        ("testAppend", testAppend),
        ("testGet", testGet),
        ("testDelete", testDelete),
        ("testClear", testClear),
        ("testSequence", testSequence)
    ]
}
