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

    func testAdd() {
        var set = WeakSet<Object>()

        let block = {
            let obj = Object()
            set.add(obj)
        }

        block()
        XCTAssertEqual(set.count, 0)

        let obj = Object()
        set.add(obj)
        set.add(obj)
        XCTAssertEqual(set.count, 1)
    }

    func testRemove() {
        var set = WeakSet<Object>()
        let obj = Object()
        set.add(obj)
        set.remove(obj)
        XCTAssertEqual(set.count, 0)
    }

    static var allTests = [
        ("testAdd", testAdd),
        ("testRemove", testRemove)
    ]
}
