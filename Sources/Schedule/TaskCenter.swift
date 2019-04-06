import Foundation

private let _default = TaskCenter()

extension TaskCenter {

    private class TaskBox: Hashable {

        weak var task: Task?

        // Used to find slot in dictionary/set
        let hash: Int

        init(_ task: Task) {
            self.task = task
            self.hash = task.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(hash)
        }

        // Used to find task in a slot in dictionary/set
        static func == (lhs: TaskBox, rhs: TaskBox) -> Bool {
            return lhs.task == rhs.task
        }
    }
}

/// A task center that enables batch operation.
open class TaskCenter {

    private let lock = NSLock()

    private var tags: [String: Set<TaskBox>] = [:]
    private var tasks: [TaskBox: Set<String>] = [:]

    /// Default task center.
    open class var `default`: TaskCenter {
        return _default
    }

    /// Adds the given task to this center.
    open func add(_ task: Task) {
        task.addToTaskCenter(self)

        lock.withLockVoid {
            let box = TaskBox(task)
            self.tasks[box] = []
        }
    }

    /// Removes the given task from this center.
    open func remove(_ task: Task) {
        task.removeFromTaskCenter(self)

        lock.withLockVoid {
            let box = TaskBox(task)
            if let tags = self.tasks[box] {
                for tag in tags {
                    self.tags[tag]?.remove(box)
                    if self.tags[tag]?.count == 0 {
                        self.tags[tag] = nil
                    }
                }
                self.tasks[box] = nil
            }
        }
    }

    /// Adds a tag to the task.
    ///
    /// If the task is not in this center, do nothing.
    open func addTag(_ tag: String, to task: Task) {
        addTags([tag], to: task)
    }

    /// Adds tags to the task.
    ///
    /// If the task is not in this center, do nothing.
    open func addTags(_ tags: [String], to task: Task) {
        guard task.taskCenter === self else { return }

        lock.withLockVoid {
            let box = TaskBox(task)
            for tag in tags {
                tasks[box]?.insert(tag)
                if self.tags[tag] == nil {
                    self.tags[tag] = []
                }
                self.tags[tag]?.insert(box)
            }
        }
    }

    /// Removes a tag from the task.
    ///
    /// If the task is not in this center, do nothing.
    open func removeTag(_ tag: String, from task: Task) {
        removeTags([tag], from: task)
    }

    /// Removes tags from the task.
    ///
    /// If the task is not in this center, do nothing.
    open func removeTags(_ tags: [String], from task: Task) {
        guard task.taskCenter === self else { return }

        lock.withLockVoid {
            let box = TaskBox(task)
            for tag in tags {
                self.tasks[box]?.remove(tag)
                self.tags[tag]?.remove(box)
                if self.tags[tag]?.count == 0 {
                    self.tags[tag] = nil
                }
            }
        }
    }

    /// Returns all tags for the task.
    ///
    /// If the task is not in this center, return an empty array.
    open func tags(forTask task: Task) -> [String] {
        guard task.taskCenter === self else { return [] }

        return lock.withLock {
            Array(tasks[TaskBox(task)] ?? [])
        }
    }

    /// Returns all tasks for the tag.
    open func tasks(forTag tag: String) -> [Task] {
        return lock.withLock {
            tags[tag]?.compactMap { $0.task } ?? []
        }
    }

    /// Returns all tasks in this center.
    open var allTasks: [Task] {
        return lock.withLock {
            tasks.compactMap { $0.key.task }
        }
    }

    /// Returns all tags in this center.
    open var allTags: [String] {
        return lock.withLock {
            tags.map { $0.key }
        }
    }

    /// Removes all tasks from this center.
    open func removeAll() {
        lock.withLockVoid {
            tasks = [:]
            tags = [:]
        }
    }

    /// Suspends all tasks by tag.
    open func suspend(byTag tag: String) {
        tasks(forTag: tag).forEach { $0.suspend() }
    }

    /// Resumes all tasks by tag.
    open func resume(byTag tag: String) {
        tasks(forTag: tag).forEach { $0.resume() }
    }

    /// Cancels all tasks by tag.
    open func cancel(byTag tag: String) {
        tasks(forTag: tag).forEach { $0.cancel() }
    }
}
