import Foundation

private let _default = TaskCenter()

extension TaskCenter {

    private class TaskBox: Hashable {

        weak var task: Task?

        // Used to find slot
        let hash: Int

        init(_ task: Task) {
            self.task = task
            self.hash = task.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(hash)
        }

        // Used to find task
        static func == (lhs: TaskBox, rhs: TaskBox) -> Bool {
            return lhs.task == rhs.task
        }
    }
}

/// A task mamanger that enables batch tasks operation.
open class TaskCenter {

    private let mutex = NSLock()

    private var taskMap: [String: Set<TaskBox>] = [:]
    private var tagMap: [TaskBox: Set<String>] = [:]

    open class var `default`: TaskCenter {
        return _default
    }

    /// Adds a task to this center.
    ///
    /// Center won't retain the task.
    open func add(_ task: Task) {
        task.taskCenterMutex.lock()

        if let center = task.taskCenter {
            if center === self { return }
            center.remove(task)
        }
        task.taskCenter = self

        task.taskCenterMutex.unlock()

        mutex.withLock {
            let box = TaskBox(task)
            tagMap[box] = []
        }

        task.onDeinit { [weak self] (t) in
            guard let self = self else { return }
            self.remove(t)
        }
    }

    /// Removes a task from this center.
    open func remove(_ task: Task) {
        task.taskCenterMutex.lock()

        guard task.taskCenter === self else {
            return
        }
        task.taskCenter = nil

        task.taskCenterMutex.unlock()

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

        mutex.withLock {
            let box = TaskBox(task)
            for tag in tags {
                tagMap[box]?.remove(tag)
                taskMap[tag]?.remove(box)
            }
        }
    }

    /// Returns all tags on the task.
    ///
    /// If the task is not in this center, return an empty array.
    open func tagsForTask(_ task: Task) -> [String] {
        guard task.taskCenter === self else { return [] }

        return mutex.withLock {
            Array(tagMap[TaskBox(task)] ?? [])
        }
    }

    /// Returns all tasks that have the tag.
    open func tasksForTag(_ tag: String) -> [Task] {
        return mutex.withLock {
            taskMap[tag]?.compactMap { $0.task } ?? []
        }
    }

    /// Returns all tasks in this center.
    open var allTasks: [Task] {
        return mutex.withLock {
            tagMap.compactMap { $0.key.task }
        }
    }

    /// Returns all existing tags in this center.
    open var allTags: [String] {
        return mutex.withLock {
            taskMap.map { $0.key }
        }
    }

    /// Removes all tasks in this center.
    open func clear() {
        mutex.withLock {
            tagMap = [:]
            taskMap = [:]
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
