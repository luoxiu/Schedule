import XCTest
@testable import Schedule

final class BucketTests: XCTestCase {

    typealias Fn = () -> Int

    func testBucketKey() {
        let key = BucketKey(0)
        XCTAssertEqual(key.next(), BucketKey(1))
    }

    func testAppend() {
        var bucket = Bucket<Fn>()
        bucket.append { 1 }
        bucket.append { 2 }
        bucket.append { 3 }
        XCTAssertEqual(bucket.count, 3)
    }

    func testGet() {
        var bucket = Bucket<Fn>()
        let k1 = bucket.append { 1 }
        let k2 = bucket.append { 2 }
        XCTAssertNotNil(bucket.element(for: k1))
        XCTAssertNotNil(bucket.element(for: k2))
        guard let fn1 = bucket.element(for: k1), let fn2 = bucket.element(for: k2) else {
            XCTFail()
            return
        }
        XCTAssertEqual(fn1(), 1)
        XCTAssertEqual(fn2(), 2)

        XCTAssertNil(bucket.element(for: k2.next()))

    }

    func testRemove() {
        var bucket = Bucket<Fn>()

        let k1 = bucket.append { 1 }
        let k2 = bucket.append { 2 }

        let fn1 = bucket.removeElement(for: k1)
        XCTAssertNotNil(fn1)

        let fn2 = bucket.removeElement(for: k2)
        XCTAssertNotNil(fn2)

        XCTAssertNil(bucket.removeElement(for: k2.next()))

        bucket.removeAll()
        XCTAssertEqual(bucket.count, 0)

        bucket.append { 3 }
        XCTAssertEqual(bucket.count, 1)
    }

    func testSequence() {
        var bucket = Bucket<Fn>()
        bucket.append { 0 }
        bucket.append { 1 }
        bucket.append { 2 }

        var i = 0
        for fn in bucket {
            XCTAssertEqual(fn(), i)
            i += 1
        }
    }

    static var allTests = [
        ("testBucketKey", testBucketKey),
        ("testAppend", testAppend),
        ("testGet", testGet),
        ("testRemove", testRemove),
        ("testSequence", testSequence)
    ]
}
