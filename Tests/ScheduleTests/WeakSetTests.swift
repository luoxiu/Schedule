//
//  WeakSetTests.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import XCTest
@testable import Schedule

private class Object { }

final class WeakSetTests: XCTestCase {

    func testInsert() {
        var set = WeakSet<Object>()

        let block = {
            let obj = Object()
            set.insert(obj)
        }
        block()
        XCTAssertEqual(set.count, 0)

        let obj = Object()
        set.insert(obj)
        set.insert(obj)
        XCTAssertEqual(set.count, 1)
    }

    func testRemove() {
        var set = WeakSet<Object>()
        let obj = Object()
        set.insert(obj)
        set.remove(obj)
        XCTAssertEqual(set.count, 0)
    }

    func testContains() {
        var set = WeakSet<Object>()

        let block = {
            let obj = Object()
            set.insert(obj)
        }
        block()
        XCTAssertTrue(set.containsNil())

        let obj = Object()
        set.insert(obj)
        XCTAssertTrue(set.contains(obj))
    }

    func testObjects() {
        var set = WeakSet<Object>()

        let obj0 = Object()
        let obj1 = Object()
        set.insert(obj0)
        set.insert(obj1)

        let objs = set.objects
        XCTAssertEqual(objs.count, 2)
        XCTAssertTrue(objs.contains(where: { $0 === obj0 }))
        XCTAssertTrue(objs.contains(where: { $0 === obj1 }))
    }

    func testIterator() {
        var set = WeakSet<Object>()

        let obj0 = Object()
        let obj1 = Object()
        set.insert(obj0)
        set.insert(obj1)

        let it = set.makeIterator()
        XCTAssertNotNil(it.next())
        XCTAssertNotNil(it.next())
        XCTAssertNil(it.next())
    }

    func testPurify() {
        var set = WeakSet<Object>()

        let block = {
            let obj = Object()
            set.insert(obj)
        }
        autoreleasepool {
            block()
        }

        let obj = Object()
        set.insert(obj)

        set.purify()
        XCTAssertFalse(set.containsNil())
    }

    static var allTests = [
        ("testInsert", testInsert),
        ("testRemove", testRemove),
        ("testContains", testContains),
        ("testObjects", testObjects),
        ("testIterator", testIterator)
    ]
}
