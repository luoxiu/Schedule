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
        let task = makeTask()
        XCTAssertEqual(center.allTasks.count, 1)

        let c = TaskCenter()
        c.add(task)

        XCTAssertEqual(center.allTasks.count, 0)
        XCTAssertEqual(c.allTasks.count, 1)

        center.add(task)
        XCTAssertEqual(center.allTasks.count, 1)
        XCTAssertEqual(c.allTasks.count, 0)

        center.removeAll()
    }

    func testRemove() {
        let task = makeTask()
        let tag = UUID().uuidString
        center.addTag(tag, to: task)

        center.remove(task)

        XCTAssertFalse(center.allTasks.contains(task))
        XCTAssertFalse(center.allTags.contains(tag))

        center.removeAll()
    }

    func testTag() {
        let task = makeTask()
        let tag = UUID().uuidString

        center.addTag(tag, to: task)
        XCTAssertTrue(center.tasks(forTag: tag).contains(task))
        XCTAssertTrue(center.tags(forTask: task).contains(tag))

        center.removeTag(tag, from: task)
        XCTAssertFalse(center.tasks(forTag: tag).contains(task))
        XCTAssertFalse(center.tags(forTask: task).contains(tag))

        center.removeAll()
    }

    func testAll() {
        let task = makeTask()
        let tag1 = UUID().uuidString
        let tag2 = UUID().uuidString

        center.addTags([tag1, tag2], to: task)

        XCTAssertEqual(center.allTags.sorted(), [tag1, tag2].sorted())
        XCTAssertEqual(center.allTasks, [task])

        center.removeAll()
    }

    func testOperation() {
        let task = makeTask()
        let tag = UUID().uuidString

        center.addTag(tag, to: task)

        center.suspend(byTag: tag)
        XCTAssertEqual(task.suspensionCount, 1)

        center.resume(byTag: tag)
        XCTAssertEqual(task.suspensionCount, 0)

        center.cancel(byTag: tag)
        XCTAssertTrue(task.isCancelled)

        center.removeAll()
    }

    func testWeak() {
        let block = {
            let task = self.makeTask()
            XCTAssertEqual(self.center.allTasks.count, 1)
            _ = task
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
