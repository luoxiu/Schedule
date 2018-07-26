//
//  BucketTests.swift
//  ScheduleTests
//
//  Created by Quentin Jin on 2018/7/24.
//

import XCTest
@testable import Schedule

final class BucketTests: XCTestCase {

    typealias Fn = () -> Int

    func testAdd() {
        var bucket = Bucket<Fn>()
        let key = bucket.add({ 1 })
        let element = bucket.element(for: key)
        XCTAssertNotNil(element)
        guard let fn = element else { return }
        XCTAssertEqual(fn(), 1)
    }

    func testRemove() {
        var bucket = Bucket<Fn>()
        let k0 = bucket.add { 0 }
        bucket.add { 1 }
        bucket.add { 2 }
        XCTAssertEqual(bucket.count, 3)

        let e0 = bucket.removeElement(for: k0)
        XCTAssertNotNil(e0)

        guard let fn0 = e0 else { return }
        XCTAssertEqual(fn0(), 0)

        XCTAssertEqual(bucket.count, 2)

        bucket.removeAll()
        XCTAssertEqual(bucket.count, 0)
    }

    func testSequence() {
        var bucket = Bucket<Fn>()
        bucket.add { 0 }
        bucket.add { 1 }
        bucket.add { 2 }

        var i = 0
        for fn in bucket {
            XCTAssertEqual(fn(), i)
            i += 1
        }
    }

    static var allTests = [
        ("testAdd", testAdd),
        ("testRemove", testRemove),
        ("testSequence", testSequence)
    ]
}
