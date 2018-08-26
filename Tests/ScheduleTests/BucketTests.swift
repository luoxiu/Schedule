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

    func testBucketKey() {
        let key = BucketKey(rawValue: 0)
        XCTAssertEqual(key.next().hashValue, BucketKey(rawValue: 1).hashValue)
    }

    func testAppend() {
        var bucket = Bucket<Fn>()
        let key = bucket.append { 1 }
        let element = bucket.element(for: key)
        guard let fn = element else {
            XCTFail("should not get nil here")
            return
        }
        XCTAssertEqual(fn(), 1)
    }

    func testMiss() {
        var bucket = Bucket<Fn>()
        let key = bucket.append { 1 }
        let element = bucket.element(for: key.next())
        XCTAssertNil(element)
    }

    func testRemove() {
        var bucket = Bucket<Fn>()

        bucket.append { 0 }
        bucket.append { 1 }
        let k = bucket.append { 2 }

        let e = bucket.removeElement(for: k)
        XCTAssertNotNil(e)

        XCTAssertNil(bucket.removeElement(for: k.next()))

        bucket.removeAll()
        XCTAssertEqual(bucket.count, 0)
    }

    func testCount() {
        var bucket = Bucket<Fn>()

        bucket.append { 0 }
        bucket.append { 1 }
        bucket.append { 2 }
        XCTAssertEqual(bucket.count, 3)
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
        ("testAppend", testAppend),
        ("testMiss", testMiss),
        ("testRemove", testRemove),
        ("testCount", testCount),
        ("testSequence", testSequence)
    ]
}
