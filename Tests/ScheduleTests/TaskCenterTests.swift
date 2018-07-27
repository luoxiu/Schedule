//
//  TaskCenterTests.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import XCTest
@testable import Schedule

final class TaskCenterTests: XCTestCase {

    func makeTask() -> Task {
        return Schedule.never.do { }
    }

    var center: TaskCenter {
        return TaskCenter.shared
    }

    func testAdd() {
        let task = makeTask()
        center.add(task)
        XCTAssertTrue(center.contains(task))
    }

    func testRemove() {
        let task = makeTask()
        center.add(task)
        center.remove(task)
        XCTAssertFalse(center.contains(task))
    }

    func testTag() {
        let task = makeTask()
        let tag0 = UUID().uuidString
        center.add(task, withTag: tag0)
        XCTAssertTrue(center.tasks(forTag: tag0).contains(task))

        let tag1 = UUID().uuidString
        center.add(tag: tag1, to: task)
        XCTAssertTrue(center.tasks(forTag: tag1).contains(task))

        center.remove(tag: tag0, from: task)
        XCTAssertFalse(center.tasks(forTag: tag0).contains(task))
    }

    static var allTests = [
        ("testAdd", testAdd),
        ("testRemove", testRemove),
        ("testTag", testTag)
    ]
}
