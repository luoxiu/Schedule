import Foundation

final class TaskHub {

    static let shared = TaskHub()

    private init() { }
    private let lock = Lock()
    private var tasks: Set<Task> = []
    private var registry: [String: Set<Task>] = [:]

    func add(_ task: Task, withTag tag: String? = nil) {
        lock.withLock {
            tasks.insert(task)
            if let tag = tag {
                if registry[tag] == nil {
                    registry[tag] = []
                }
                registry[tag]?.insert(task)
            }
        }
    }

    func remove(_ task: Task) {
        lock.withLock {
            _ = tasks.remove(task)

            let tags = task.tags
            for tag in tags {
                registry[tag]?.remove(task)
            }
        }
    }

    func add(tag: String, to task: Task) {
        lock.withLock {
            guard tasks.contains(task) else { return }
            if registry[tag] == nil {
                registry[tag] = []
            }
            registry[tag]?.insert(task)
        }
    }

    func remove(tag: String, from task: Task) {
        lock.withLock {
            _ = registry[tag]?.remove(task)
        }
    }

    func tasks(forTag tag: String) -> [Task] {
        return lock.withLock {
            guard let tasks = registry[tag] else { return [] }
            return Array(tasks)
        }
    }

    func contains(_ task: Task) -> Bool {
        return lock.withLock {
            tasks.contains(task)
        }
    }

    var countOfTasks: Int {
        return lock.withLock {
            tasks.count
        }
    }

    @discardableResult
    func clear() -> [Task] {
        var holder: [Task] = []
        lock.withLock {
            holder = Array(tasks)
            tasks = []
            registry = [:]
        }
        return holder
    }
}
