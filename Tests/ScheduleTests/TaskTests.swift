//
//  TaskTests.swift
//  ScheduleTests
//
//  Created by Quentin MED on 2018/7/27.
//

import XCTest
@testable import Schedule

final class TaskTests: XCTestCase {

    func testSchedule() {
        let expectation = XCTestExpectation(description: "testSchedule")
        let date = Date()
        let task = Schedule.after(0.5.second).do {
            XCTAssertTrue(Date().timeIntervalSince(date).isAlmostEqual(to: 0.5, leeway: 0.1))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        task.cancel()
    }

    func testAddAndRemoveActions() {
        let expectation = XCTestExpectation(description: "testAddAndRemoveActions")
        let task = Schedule.after(0.5.second).do { }
        let date = Date()
        let key = task.addAction { _ in
            XCTAssertTrue(Date().timeIntervalSince(date).isAlmostEqual(to: 0.5, leeway: 0.1))
            expectation.fulfill()
        }
        XCTAssertEqual(task.countOfActions, 2)
        wait(for: [expectation], timeout: 2)
        task.removeAction(byKey: key)
        XCTAssertEqual(task.countOfActions, 1)
        task.cancel()
    }

    func testAddAndRemoveTags() {
        let task = Schedule.never.do { }
        task.addTag("c")
        task.addTags("n", "s", "z")
        XCTAssertTrue(task.tags.contains("c"))
        XCTAssertTrue(task.tags.contains("z"))
        task.removeTag("c")
        XCTAssertFalse(task.tags.contains("c"))
        task.removeTags("s", "z")
        XCTAssertFalse(task.tags.contains("s"))
        XCTAssertFalse(task.tags.contains("z"))
        task.cancel()
    }

    func testReschedule() {
        let expectation = XCTestExpectation(description: "testReschedule")
        var i = 0
        let task = Schedule.after(0.1.second).do { (task) in
            i += 1
            if task.countOfExecution == 6 && task.timeline.estimatedNextExecution == nil {
                expectation.fulfill()
            }
            if task.countOfExecution > 6 {
                XCTFail("should never come here")
            }
        }
        DispatchQueue.global().async(after: 0.5.second) {
            task.reschedule(Schedule.every(0.1.second).first(5))
        }
        wait(for: [expectation], timeout: 2)
        task.cancel()
    }

    func testParasiticTask() {
        let fn = {
            let obj = NSObject()
            Schedule.after(0.5.second).do(host: obj, onElapse: {
                XCTFail("should never come here")
            })
        }
        fn()
        wait(for: [], timeout: 1)
    }

    func testLifetime() {
        let expectation = XCTestExpectation(description: "testLifetime")
        let task = Schedule.after(1.hour).do { }
        task.setLifetime(1.second)
        DispatchQueue.global().async(after: 0.5.second) {
            XCTAssertTrue(task.restOfLifetime.isAlmostEqual(to: 0.5.second, leeway: 0.1.second))
            task.addLifetime(0.5.second)
        }
        DispatchQueue.global().async(after: 1.second) {
            XCTAssertFalse(task.isCancelled)
        }
        DispatchQueue.global().async(after: 2.second) {
            XCTAssertTrue(task.isCancelled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    static var allTests = [
        ("testSchedule", testSchedule),
        ("testAddAndRemoveActions", testAddAndRemoveActions),
        ("testAddAndRemoveTags", testAddAndRemoveTags),
        ("testReschedule", testReschedule),
        ("testParasiticTask", testParasiticTask),
        ("testLifetime", testLifetime)
    ]
}
