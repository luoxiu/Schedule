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
        var bag = Bag<Fn>()
        bag.append { 1 }
        bag.append { 2 }

        XCTAssertEqual(bag.count, 2)
    }

    func testValueForKey() {
        var bag = Bag<Fn>()
        let k1 = bag.append { 1 }
        let k2 = bag.append { 2 }
        
        let fn1 = bag.value(for: k1)
        XCTAssertNotNil(fn1)
        
        let fn2 = bag.value(for: k2)
        XCTAssertNotNil(fn2)
        
        guard let _fn1 = fn1, let _fn2 = fn2 else { return }
        
        XCTAssertEqual(_fn1(), 1)
        XCTAssertEqual(_fn2(), 2)
    }

    func testRemoveValueForKey() {
        var bag = Bag<Fn>()

        let k1 = bag.append { 1 }
        let k2 = bag.append { 2 }

        let fn1 = bag.removeValue(for: k1)
        XCTAssertNotNil(fn1)

        let fn2 = bag.removeValue(for: k2)
        XCTAssertNotNil(fn2)
        
        guard let _fn1 = fn1, let _fn2 = fn2 else { return }
        
        XCTAssertEqual(_fn1(), 1)
        XCTAssertEqual(_fn2(), 2)
    }
    
    func testCount() {
        var bag = Bag<Fn>()
        
        let k1 = bag.append { 1 }
        let k2 = bag.append { 2 }
        
        XCTAssertEqual(bag.count, 2)
        
        bag.removeValue(for: k1)
        bag.removeValue(for: k2)
        
        XCTAssertEqual(bag.count, 0)
    }

    func testRemoveAll() {
        var bag = Bag<Fn>()

        bag.append { 1 }
        bag.append { 2 }

        bag.removeAll()
        XCTAssertEqual(bag.count, 0)
    }

    func testSequence() {
        var bag = Bag<Fn>()
        bag.append { 0 }
        bag.append { 1 }
        bag.append { 2 }

        var i = 0
        for fn in bag {
            XCTAssertEqual(fn(), i)
            i += 1
        }
    }

    static var allTests = [
        ("testBagKey", testBagKey),
        ("testAppend", testAppend),
        ("testValueForKey", testValueForKey),
        ("testRemoveValueForKey", testRemoveValueForKey),
        ("testCount", testCount),
        ("testRemoveAll", testRemoveAll),
        ("testSequence", testSequence)
    ]
}
