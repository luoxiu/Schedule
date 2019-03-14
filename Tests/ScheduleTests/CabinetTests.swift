import XCTest
@testable import Schedule

final class CabinetTests: XCTestCase {

    typealias Fn = () -> Int

    func testCabinetKey() {
        let key = CabinetKey(underlying: 0)
        XCTAssertEqual(key.increased(), CabinetKey(underlying: 1))
    }

    func testAppend() {
        var cabinet = Cabinet<Fn>()
        let k1 = cabinet.append { 1 }
        let k2 = cabinet.append { 2 }

        XCTAssertEqual(k1.increased(), k2)
        XCTAssertEqual(cabinet.count, 2)
    }

    func testGet() {
        var cabinet = Cabinet<Fn>()
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

        XCTAssertNil(cabinet.get(k2.increased()))
    }

    func testDelete() {
        var cabinet = Cabinet<Fn>()

        let k1 = cabinet.append { 1 }
        let k2 = cabinet.append { 2 }

        XCTAssertEqual(cabinet.count, 2)

        let fn1 = cabinet.delete(k1)
        XCTAssertNotNil(fn1)

        let fn2 = cabinet.delete(k2)
        XCTAssertNotNil(fn2)

        XCTAssertEqual(cabinet.count, 0)

        XCTAssertNil(cabinet.delete(k2.increased()))
    }

    func testClear() {
        var cabinet = Cabinet<Fn>()

        cabinet.append { 1 }
        cabinet.append { 2 }

        XCTAssertEqual(cabinet.count, 2)

        cabinet.clear()
        XCTAssertEqual(cabinet.count, 0)
    }

    func testSequence() {
        var cabinet = Cabinet<Fn>()
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
        ("testCabinetKey", testCabinetKey),
        ("testAppend", testAppend),
        ("testGet", testGet),
        ("testDelete", testDelete),
        ("testClear", testClear),
        ("testSequence", testSequence)
    ]
}
