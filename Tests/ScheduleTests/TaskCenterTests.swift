import XCTest
@testable import Schedule

final class TaskCenterTests: XCTestCase {

    @discardableResult
    func makeTask() -> Task {
        return Plan.never.do { }
    }

    var center: TaskCenter {
        return TaskCenter.default
    }

    func testDefault() {
        let task = makeTask()
        XCTAssertTrue(center.allTasks.contains(task))
        center.removeAll()
    }

    func testAdd() {
        let c = TaskCenter()

        let task = makeTask()
        XCTAssertEqual(center.allTasks.count, 1)

        c.add(task)
        XCTAssertEqual(center.allTasks.count, 0)
        XCTAssertEqual(c.allTasks.count, 1)

        c.add(task)
        XCTAssertEqual(c.allTasks.count, 1)

        center.removeAll()
    }

    func testRemove() {
        let task = makeTask()
        center.remove(task)
        XCTAssertFalse(center.allTasks.contains(task))
    }

    func testTag() {
        let task = makeTask()

        let tag = UUID().uuidString

        center.addTag(tag, to: task)
        XCTAssertTrue(center.tasksForTag(tag).contains(task))
        XCTAssertTrue(center.tagsForTask(task).contains(tag))

        center.removeTag(tag, from: task)
        XCTAssertFalse(center.tasksForTag(tag).contains(task))
        XCTAssertFalse(center.tagsForTask(task).contains(tag))

        center.removeAll()
    }

    func testAll() {
        let task = makeTask()

        let tag = UUID().uuidString

        center.addTag(tag, to: task)
        XCTAssertEqual(center.allTags, [tag])
        XCTAssertEqual(center.allTasks, [task])

        center.removeAll()
    }

    func testOperation() {
        let task = makeTask()

        let tag = UUID().uuidString

        center.addTag(tag, to: task)

        center.suspendByTag(tag)
        XCTAssertEqual(task.suspensions, 1)

        center.resumeByTag(tag)
        XCTAssertEqual(task.suspensions, 0)

        center.cancelByTag(tag)
        XCTAssertTrue(task.isCancelled)

        center.removeAll()
    }

    func testWeak() {
        let block = {
            _ = self.makeTask()
        }
        block()

        XCTAssertEqual(center.allTasks.count, 0)
    }

    static var allTests = [
        ("testDefault", testDefault),
        ("testAdd", testAdd),
        ("testRemove", testRemove),
        ("testTag", testTag),
        ("testAll", testAll),
        ("testOperation", testOperation),
        ("testWeak", testWeak)
    ]
}
