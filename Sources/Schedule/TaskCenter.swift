import Foundation

private let _default = TaskCenter()

private class _TaskWrapper {
    weak var task: Task?

    let hashValue: Int

    init(_ task: Task) {
        self.task = task
        self.hashValue = task.hashValue
    }
}

extension _TaskWrapper: Hashable {

    static func == (lhs: _TaskWrapper, rhs: _TaskWrapper) -> Bool {
        return lhs.task == rhs.task
    }
}

open class TaskCenter {

    private let _lock = NSLock()
    private var _tasks: Set<_TaskWrapper> = []

    open class var `default`: TaskCenter {
        return _default
    }

    open func add(_ task: Task) {
        if let center = task.taskCenter {
            if center === self {
                return
            }

            center.remove(task)
        }

        task.taskCenter = self

        _lock.withLock {
            let wrapper = _TaskWrapper(task)
            _tasks.insert(wrapper)

            task.onDeinit { [weak self, weak wrapper = wrapper] task in
                guard let self = self, let wrapper = wrapper else { return }
                self._tasks.remove(wrapper)
            }
        }
    }

    open func remove(_ task: Task) {
        guard task.taskCenter === self else {
            return
        }

        task.taskCenter = nil

        _lock.withLock {
            let wrapper = _TaskWrapper(task)
            _tasks.remove(wrapper)
        }
    }

    open func tasksWithTag(_ tag: String) -> [Task] {
        return _lock.withLock {
            return _tasks.compactMap { wrapper in
                if let task = wrapper.task, task.tags.contains(tag) {
                    return task
                }
                return nil
            }
        }
    }

    open var allTasks: [Task] {
        return _lock.withLock {
            return _tasks.compactMap { $0.task }
        }
    }

    open func clear() {
        _lock.withLock {
            _tasks = []
        }
    }
}
