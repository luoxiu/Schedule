import XCTest
@testable import Schedule

final class TaskTests: XCTestCase {

    func testAfter() {
        let e = expectation(description: "testSchedule")
        let date = Date()
        let task = Plan.after(0.1.second).do {
            XCTAssertTrue(Date().timeIntervalSince(date).isAlmostEqual(to: 0.1, leeway: 0.1))
            e.fulfill()
        }
        waitForExpectations(timeout: 0.5)
        task.cancel()
    }

    func testRepeat() {
        let e = expectation(description: "testRepeat")
        var t = 0
        let task = Plan.every(0.1.second).first(3).do {
            t += 1
            if t == 3 { e.fulfill() }
        }
        waitForExpectations(timeout: 1)
        task.cancel()
    }

    func testDispatchQueue() {
        let e = expectation(description: "testQueue")
        let queue = DispatchQueue(label: "testQueue")

        let task = Plan.after(0.1.second).do(queue: queue) {
            XCTAssertTrue(DispatchQueue.is(queue))
            e.fulfill()
        }
        waitForExpectations(timeout: 0.5)
        task.cancel()
    }

    func testThread() {
        let e = expectation(description: "testThread")
        DispatchQueue.global().async {
            let thread = Thread.current
            Plan.after(0.1.second).do { task in
                XCTAssertTrue(thread === Thread.current)
                e.fulfill()
                task.cancel()
            }
            RunLoop.current.run()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testSuspendResume() {
        let task1 = Plan.distantFuture.do { }
        XCTAssertEqual(task1.suspensions, 0)
        task1.suspend()
        task1.suspend()
        task1.suspend()
        XCTAssertEqual(task1.suspensions, 3)
        task1.resume()
        XCTAssertEqual(task1.suspensions, 2)

        let tag = UUID().uuidString
        let task2 = Plan.distantFuture.do { }
        task2.addTag(tag)
        Task.suspend(byTag: tag)
        XCTAssertEqual(task2.suspensions, 1)
        Task.resume(byTag: tag)
        XCTAssertEqual(task2.suspensions, 0)
        Task.cancel(byTag: tag)
        XCTAssertTrue(task2.isCancelled)
    }

    func testAddAndRemoveActions() {
        let e = expectation(description: "testAddAndRemoveActions")
        let task = Plan.after(0.1.second).do { }
        let date = Date()
        let key = task.addAction { _ in
            XCTAssertTrue(Date().timeIntervalSince(date).isAlmostEqual(to: 0.1, leeway: 0.1))
            e.fulfill()
        }
        XCTAssertEqual(task.countOfActions, 2)
        waitForExpectations(timeout: 0.5)

        task.removeAction(byKey: key)
        XCTAssertEqual(task.countOfActions, 1)
        
        task.cancel()

        task.removeAllActions()
        XCTAssertEqual(task.countOfActions, 0)
    }

    func testAddAndRemoveTags() {
        let task = Plan.never.do { }
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
        let task = Plan.after(0.1.second).do { (task) in
            i += 1
            if task.countOfExecutions == 6 && task.timeline.estimatedNextExecution == nil {
                e.fulfill()
            }
            if task.countOfExecutions > 6 {
                XCTFail("should never come here")
            }
        }
        DispatchQueue.global().async(after: 0.5.second) {
            task.reschedule(Plan.every(0.1.second).first(5))
        }
        waitForExpectations(timeout: 2)
        task.cancel()
    }

    func testHost() {
        let e = expectation(description: "testHost")
        let fn = {
            let obj = NSObject()
            Plan.after(0.1.second).do(queue: .main, host: obj, onElapse: {
                XCTFail()
            })
        }
        fn()
        DispatchQueue.main.async(after: 0.2.seconds) {
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testLifetime() {
        let e = expectation(description: "testLifetime")
        let task = Plan.after(1.hour).do { }
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
        waitForExpectations(timeout: 3)
    }

    static var allTests = [
        ("testAfter", testAfter),
        ("testRepeat", testRepeat),
        ("testDispatchQueue", testDispatchQueue),
        ("testThread", testThread),
        ("testAddAndRemoveActions", testAddAndRemoveActions),
        ("testAddAndRemoveTags", testAddAndRemoveTags),
        ("testReschedule", testReschedule),
        ("testHost", testHost),
        ("testLifetime", testLifetime)
    ]
}
