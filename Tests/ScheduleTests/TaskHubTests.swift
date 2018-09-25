import XCTest
@testable import Schedule

final class TaskHubTests: XCTestCase {

    @discardableResult
    func makeTask() -> Task {
        return Plan.never.do { }
    }

    var shared: TaskHub {
        return TaskHub.shared
    }

    func testAdd() {
        let task = makeTask()
        XCTAssertTrue(shared.contains(task))
        shared.add(task)
        XCTAssertEqual(shared.countOfTasks, 1)
    }

    func testRemove() {
        let task = makeTask()
        shared.remove(task)
        XCTAssertFalse(shared.contains(task))
    }

    func testTag() {

        let task = makeTask()
        let tag0 = UUID().uuidString
        shared.add(task, withTag: tag0)
        XCTAssertTrue(shared.tasks(forTag: tag0).contains(task))

        let tag1 = UUID().uuidString
        shared.add(tag: tag1, to: task)
        XCTAssertTrue(shared.tasks(forTag: tag1).contains(task))

        shared.remove(tag: tag0, from: task)
        XCTAssertFalse(shared.tasks(forTag: tag0).contains(task))
    }

    func testCount() {
        shared.clear()
        XCTAssertEqual(shared.countOfTasks, 0)
        makeTask()
        XCTAssertEqual(shared.countOfTasks, 1)
    }

    static var allTests = [
        ("testAdd", testAdd),
        ("testRemove", testRemove),
        ("testTag", testTag)
    ]
}
