import Foundation

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

private let _default = TaskCenter()

/// A task center that enables batch operation.
open class TaskCenter {

    private let lock = NSLock()

    private var tags: [String: Set<TaskBox>] = [:]
    private var tasks: [TaskBox: Set<String>] = [:]

    /// Default task center.
    open class var `default`: TaskCenter {
        return _default
    }
    
    public init() { }

    /// Adds the given task to this center.
    ///
    /// Please note: task center will not retain tasks.
    open func add(_ task: Task) {
        task.addToTaskCenter(self)
    }
    
    func addSimply(_ task: Task) {
        lock.withLockVoid {
            let box = TaskBox(task)
            self.tasks[box] = []
        }
    }
    
    func removeSimply(_ task: Task) {
        lock.withLockVoid {
            let box = TaskBox(task)
            guard let tags = self.tasks[box] else {
                return
            }
            
            self.tasks[box] = nil
            for tag in tags {
                self.tags[tag]?.remove(box)
                if self.tags[tag]?.count == 0 {
                    self.tags[tag] = nil
                }
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
        lock.withLockVoid {
            let box = TaskBox(task)
            guard self.tasks[box] != nil else {
                return
            }
            
            for tag in tags {
                self.tasks[box]?.insert(tag)
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
        lock.withLockVoid {
            let box = TaskBox(task)
            guard self.tasks[box] != nil else {
                return
            }
            
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
        allTasks.forEach {
            $0.removeFromTaskCenter()
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
