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
        let e = expectation(description: "testSchedule")
        let date = Date()
        let task = Schedule.after(0.5.second).do {
            XCTAssertTrue(Date().timeIntervalSince(date).isAlmostEqual(to: 0.5, leeway: 0.1))
            e.fulfill()
        }
        waitForExpectations(timeout: 2)
        task.cancel()
    }

    func testSuspendResume() {
        let block = {
            let task = Schedule.distantFuture.do { }
            XCTAssertEqual(task.suspensions, 0)
            task.suspend()
            task.suspend()
            task.suspend()
            XCTAssertEqual(task.suspensions, 3)
            task.resume()
            XCTAssertEqual(task.suspensions, 2)
        }
        block()

        let tag = UUID().uuidString
        let task = Schedule.distantFuture.do { }
        task.addTag(tag)
        Task.suspend(byTag: tag)
        XCTAssertEqual(task.suspensions, 1)
        Task.resume(byTag: tag)
        XCTAssertEqual(task.suspensions, 0)
        Task.cancel(byTag: tag)
        XCTAssertTrue(task.isCancelled)
    }

    func testAddAndRemoveActions() {
        let e = expectation(description: "testAddAndRemoveActions")
        let task = Schedule.after(0.5.second).do { }
        let date = Date()
        let key = task.addAction { _ in
            XCTAssertTrue(Date().timeIntervalSince(date).isAlmostEqual(to: 0.5, leeway: 0.1))
            e.fulfill()
        }
        XCTAssertEqual(task.countOfActions, 2)
        waitForExpectations(timeout: 2)
        task.removeAction(byKey: key)
        XCTAssertEqual(task.countOfActions, 1)
        task.cancel()

        task.removeAllActions()
        XCTAssertEqual(task.countOfActions, 0)
    }

    func testAddAndRemoveTags() {
        let task = Schedule.never.do { }
        let tagA = UUID().uuidString
        let tagB = UUID().uuidString
        let tagC = UUID().uuidString
        task.addTag(tagA)
        task.addTags(tagB, tagC)
        XCTAssertTrue(task.tags.contains(tagA))
        XCTAssertTrue(task.tags.contains(tagC))
        task.removeTag(tagA)
        XCTAssertFalse(task.tags.contains(tagA))
        task.removeTags(tagB, tagC)
        XCTAssertFalse(task.tags.contains(tagB))
        XCTAssertFalse(task.tags.contains(tagC))
        task.cancel()
    }

    func testReschedule() {
        let e = expectation(description: "testReschedule")
        var i = 0
        let task = Schedule.after(0.1.second).do { (task) in
            i += 1
            if task.countOfExecution == 6 && task.timeline.estimatedNextExecution == nil {
                e.fulfill()
            }
            if task.countOfExecution > 6 {
                XCTFail("should never come here")
            }
        }
        DispatchQueue.global().async(after: 0.5.second) {
            task.reschedule(Schedule.every(0.1.second).first(5))
        }
        waitForExpectations(timeout: 2)
        task.cancel()
    }

    func testParasiticTask() {
        let e = expectation(description: "testParasiticTask")
        let fn = {
            let obj = NSObject()
            Schedule.after(0.5.second).do(host: obj, onElapse: {
                XCTFail("should never come here")
            })
        }
        fn()
        DispatchQueue.main.async(after: 0.75.seconds) {
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testLifetime() {
        let e = expectation(description: "testLifetime")
        let task = Schedule.after(1.hour).do { }
        task.setLifetime(1.second)
        XCTAssertEqual(task.lifetime, 1.second)

        DispatchQueue.global().async(after: 0.5.second) {
            XCTAssertTrue(task.restOfLifetime.isAlmostEqual(to: 0.5.second, leeway: 0.1.second))
            task.subtractLifetime(-0.5.second)
        }
        DispatchQueue.global().async(after: 1.second) {
            XCTAssertFalse(task.isCancelled)
        }
        DispatchQueue.global().async(after: 2.second) {
            XCTAssertTrue(task.isCancelled)
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
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
