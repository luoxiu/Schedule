import Foundation

private let _default = TaskCenter()

extension TaskCenter {

    private class TaskBox: Hashable {

        weak var task: Task?

        let hash: Int

        init(_ task: Task) {
            self.task = task
            self.hash = task.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(hash)
        }

        static func == (lhs: TaskBox, rhs: TaskBox) -> Bool {
            return lhs.task == rhs.task
        }
    }
}

/// A task center that enables batch operation.
open class TaskCenter {

    private let lock = NSLock()

    private var tasksOfTag: [String: Set<TaskBox>] = [:]
    private var tagsOfTask: [TaskBox: Set<String>] = [:]

    /// Default task center.
    open class var `default`: TaskCenter {
        return _default
    }

    /// Adds the given task to this center.
    ///
    /// Center won't retain the task.
    open func add(_ task: Task) {
        task.addToTaskCenter(self)

        lock.withLockVoid {
            let box = TaskBox(task)
            tagsOfTask[box] = []
        }
    }

    /// Removes the given task from this center.
    open func remove(_ task: Task) {
        task.removeFromTaskCenter(self)

        lock.withLockVoid {
            let box = TaskBox(task)
            if let tags = self.tagsOfTask[box] {
                for tag in tags {
                    self.tasksOfTag[tag]?.remove(box)
                    
                    if self.tasksOfTag[tag]?.count == 0 {
                        self.tasksOfTag[tag] = nil
                    }
                }
                self.tagsOfTask[box] = nil
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
            if tagsOfTask[box] == nil {
                tagsOfTask[box] = []
            }
            for tag in tags {
                tagsOfTask[box]?.insert(tag)
                if tasksOfTag[tag] == nil {
                    tasksOfTag[tag] = []
                }
                tasksOfTag[tag]?.insert(box)
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
                tagsOfTask[box]?.remove(tag)
                tasksOfTag[tag]?.remove(box)
            }
        }
    }

    /// Returns all tags on the task.
    ///
    /// If the task is not in this center, return an empty array.
    open func tagsForTask(_ task: Task) -> [String] {
        guard task.taskCenter === self else { return [] }

        return lock.withLock {
            Array(tagsOfTask[TaskBox(task)] ?? [])
        }
    }

    /// Returns all tasks that have the tag.
    open func tasksForTag(_ tag: String) -> [Task] {
        return lock.withLock {
            tasksOfTag[tag]?.compactMap { $0.task } ?? []
        }
    }

    /// Returns all tasks in this center.
    open var allTasks: [Task] {
        return lock.withLock {
            tagsOfTask.compactMap { $0.key.task }
        }
    }

    /// Returns all existing tags in this center.
    open var allTags: [String] {
        return lock.withLock {
            tasksOfTag.map { $0.key }
        }
    }

    /// Removes all tasks from this center.
    open func removeAll() {
        lock.withLockVoid {
            tagsOfTask = [:]
            tasksOfTag = [:]
        }
    }

    /// Suspends all tasks that have the tag.
    open func suspendByTag(_ tag: String) {
        tasksForTag(tag).forEach { $0.suspend() }
    }

    /// Resumes all tasks that have the tag.
    open func resumeByTag(_ tag: String) {
        tasksForTag(tag).forEach { $0.resume() }
    }

    /// Cancels all tasks that have the tag.
    open func cancelByTag(_ tag: String) {
        tasksForTag(tag).forEach { $0.cancel() }
    }
}
