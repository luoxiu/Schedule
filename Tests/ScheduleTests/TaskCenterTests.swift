import XCTest
@testable import Schedule

final class TaskCenterTests: XCTestCase {

    @discardableResult
    func makeTask() -> Task {
        return Plan.never.do { }
    }

    var defaultCenter: TaskCenter {
        return TaskCenter.default
    }

    func testDefault() {
        let task = makeTask()
        XCTAssertTrue(defaultCenter.allTasks.contains(task))
        defaultCenter.clear()
    }

    func testAdd() {
        let centerA = TaskCenter()

        let task = makeTask()
        centerA.add(task)

        XCTAssertEqual(defaultCenter.allTasks.count, 0)
        XCTAssertEqual(centerA.allTasks.count, 1)

        centerA.add(task)
        XCTAssertEqual(centerA.allTasks.count, 1)
    }

    func testRemove() {
        let task = makeTask()
        defaultCenter.remove(task)
        XCTAssertFalse(defaultCenter.allTasks.contains(task))
    }

    func testTag() {
        let task = makeTask()

        let tag0 = UUID().uuidString
        task.addTag(tag0)
        XCTAssertTrue(defaultCenter.tasksWithTag(tag0).contains(task))

        let tag1 = UUID().uuidString
        task.addTag(tag1)
        XCTAssertTrue(defaultCenter.tasksWithTag(tag1).contains(task))

        task.removeTag(tag0)
        XCTAssertFalse(defaultCenter.tasksWithTag(tag0).contains(task))

        defaultCenter.clear()
    }

    func testCount() {
        XCTAssertEqual(defaultCenter.allTasks.count, 0)

        let task = makeTask()
        XCTAssertEqual(defaultCenter.allTasks.count, 1)

        _ = task

        defaultCenter.clear()
    }

    func testWeak() {
        let block = {
            _ = self.makeTask()
        }
        block()

        XCTAssertEqual(defaultCenter.allTasks.count, 0)
    }

    static var allTests = [
        ("testDefault", testDefault),
        ("testAdd", testAdd),
        ("testRemove", testRemove),
        ("testTag", testTag),
        ("testCount", testCount),
        ("testWeak", testWeak)
    ]
}
