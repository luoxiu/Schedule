import Foundation

private let _default = TaskCenter()

extension TaskCenter {

    private class TaskBox: Hashable {

        weak var task: Task?

        // To find slot
        let hash: Int

        init(_ task: Task) {
            self.task = task
            self.hash = task.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(hash)
        }

        // To find task
        static func == (lhs: TaskBox, rhs: TaskBox) -> Bool {
            return lhs.task == rhs.task
        }
    }
}

open class TaskCenter {

    private let mutex = NSRecursiveLock()

    private var taskMap: [String: Set<TaskBox>] = [:]
    private var tagMap: [TaskBox: Set<String>] = [:]

    open class var `default`: TaskCenter {
        return _default
    }

    open func add(_ task: Task) {
        task.taskCenterMutex.lock()
        defer {
            task.taskCenterMutex.unlock()
        }

        if let center = task.taskCenter {
            if center === self { return }
            center.remove(task)
        }
        task.taskCenter = self

        mutex.withLock {
            let box = TaskBox(task)
            tagMap[box] = []
        }

        task.onDeinit { [weak self] (t) in
            guard let self = self else { return }
            self.remove(t)
        }
    }

    open func remove(_ task: Task) {
        task.taskCenterMutex.lock()
        defer {
            task.taskCenterMutex.unlock()
        }

        guard task.taskCenter === self else {
            return
        }
        task.taskCenter = nil

        mutex.withLock {
            let box = TaskBox(task)
            if let tags = self.tagMap[box] {
                for tag in tags {
                    self.taskMap[tag]?.remove(box)
                }
                self.tagMap[box] = nil
            }
        }
    }

    open func addTag(_ tag: String, to task: Task) {
        addTags([tag], to: task)
    }

    open func addTags(_ tags: [String], to task: Task) {
        guard task.taskCenter === self else { return }

        mutex.withLock {
            let box = TaskBox(task)
            if tagMap[box] == nil {
                tagMap[box] = []
            }
            for tag in tags {
                tagMap[box]?.insert(tag)
                if taskMap[tag] == nil {
                    taskMap[tag] = []
                }
                taskMap[tag]?.insert(box)
            }
        }
    }

    open func removeTag(_ tag: String, from task: Task) {
        removeTags([tag], from: task)
    }

    open func removeTags(_ tags: [String], from task: Task) {
        guard task.taskCenter === self else { return }

        mutex.withLock {
            let box = TaskBox(task)
            for tag in tags {
                tagMap[box]?.remove(tag)
                taskMap[tag]?.remove(box)
            }
        }
    }

    open func tagsForTask(_ task: Task) -> [String] {
        guard task.taskCenter === self else { return [] }

        return mutex.withLock {
            Array(tagMap[TaskBox(task)] ?? [])
        }
    }

    open func tasksForTag(_ tag: String) -> [Task] {
        return mutex.withLock {
            taskMap[tag]?.compactMap { $0.task } ?? []
        }
    }

    open var allTasks: [Task] {
        return mutex.withLock {
            tagMap.compactMap { $0.key.task }
        }
    }

    open var allTags: [String] {
        return mutex.withLock {
            taskMap.map { $0.key }
        }
    }

    open func clear() {
        mutex.withLock {
            tagMap = [:]
            taskMap = [:]
        }
    }

    open func suspendByTag(_ tag: String) {
        tasksForTag(tag).forEach { $0.suspend() }
    }

    open func resumeByTag(_ tag: String) {
        tasksForTag(tag).forEach { $0.resume() }
    }

    open func cancelByTag(_ tag: String) {
        tasksForTag(tag).forEach { $0.cancel() }
    }
}
