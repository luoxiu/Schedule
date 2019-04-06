import Foundation

/// `ActionKey` represents a token that can be used to remove the action.
public struct ActionKey {

    fileprivate let bagKey: BagKey
}

extension BagKey {

    fileprivate func asActionKey() -> ActionKey {
        return ActionKey(bagKey: self)
    }
}

/// `Task` represents a timing task.
open class Task {

    /// The unique id of this task.
    public let id = UUID()

    public typealias Action = (Task) -> Void

    private let _lock = NSRecursiveLock()

    private var _iterator: AnyIterator<Interval>
    private var _timer: DispatchSourceTimer

    private lazy var _actions = Bag<Action>()

    private lazy var _suspensionCount: UInt64 = 0
    private lazy var _executionCount: Int = 0

    private var _firstExecutionDate: Date?
    private var _lastExecutionDate: Date?
    private var _estimatedNextExecutionDate: Date?

    /// The date of creation.
    public let creationDate = Date()

    /// The date of first execution.
    open var firstExecutionDate: Date? {
        return _lock.withLock { _firstExecutionDate }
    }

    /// The date of last execution.
    open var lastExecutionDate: Date? {
        return _lock.withLock { _lastExecutionDate }
    }

    /// The date of estimated next execution.
    open var estimatedNextExecutionDate: Date? {
        return _lock.withLock { _estimatedNextExecutionDate }
    }

    private weak var _taskCenter: TaskCenter?

    /// The task center to which this task currently belongs.
    open var taskCenter: TaskCenter? {
        return _lock.withLock { _taskCenter }
    }

    private let _taskCenterLock = NSRecursiveLock()

    /// Adds this task to the given task center.
    func addToTaskCenter(_ center: TaskCenter) {
        _taskCenterLock.lock()
        defer { _taskCenterLock.unlock() }

        if _taskCenter === center { return }

        let c = _taskCenter
        _taskCenter = center

        c?.remove(self)
    }

    /// Removes this task from the given task center.
    func removeFromTaskCenter(_ center: TaskCenter) {
        _taskCenterLock.lock()
        defer { _taskCenterLock.unlock() }

        if _taskCenter !== center { return }

        _taskCenter = nil
        center.remove(self)
    }

    /// Initializes a timing task.
    ///
    /// - Parameters:
    ///   - plan: The plan.
    ///   - queue: The dispatch queue to which the block should be dispatched.
    ///   - block: A block to be executed when time is up.
    init(
        plan: Plan,
        queue: DispatchQueue?,
        block: @escaping (Task) -> Void
    ) {
        _iterator = plan.makeIterator()
        _timer = DispatchSource.makeTimerSource(queue: queue)

        _actions.append(block)

        _timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.elapse()
        }

        if let interval = _iterator.next(), !interval.isNegative {
            _timer.schedule(after: interval)
            _estimatedNextExecutionDate = Date().adding(interval)
        }

        _timer.resume()

        TaskCenter.default.add(self)
    }

    deinit {
        while _suspensionCount > 0 {
            _timer.resume()
            _suspensionCount -= 1
        }

        cancel()

        taskCenter?.remove(self)
    }

    private func elapse() {
        scheduleNextExecution()
        execute()
    }

    private func scheduleNextExecution() {
        _lock.withLockVoid {
            let now = Date()
            var estimated = _estimatedNextExecutionDate ?? now
            repeat {
                guard let interval = _iterator.next(), !interval.isNegative else {
                    _estimatedNextExecutionDate = nil
                    return
                }
                estimated = estimated.adding(interval)
            } while (estimated < now)

            _estimatedNextExecutionDate = estimated
            _timer.schedule(after: _estimatedNextExecutionDate!.interval(since: now))
        }
    }

    /// Execute this task now, without interrupting its plan.
    open func execute() {
        let actions = _lock.withLock { () -> Bag<Task.Action> in
            let now = Date()
            if _firstExecutionDate == nil {
                _firstExecutionDate = now
            }
            _lastExecutionDate = now
            _executionCount += 1
            return _actions
        }
        actions.forEach { $0(self) }
    }

    /// Host this task to an object, that is, when the object deallocates, this task will be cancelled.
    #if canImport(ObjectiveC)
    open func host(to target: AnyObject) {
        DeinitObserver.observe(target) { [weak self] in
            self?.cancel()
        }
    }
    #endif

    /// The number of task executions.
    public var executionCount: Int {
        return _lock.withLock {
            _executionCount
        }
    }

    /// A Boolean indicating whether the task was canceled.
    public var isCancelled: Bool {
        return _lock.withLock {
            _timer.isCancelled
        }
    }

    /// Reschedules this task with the new plan.
    public func reschedule(_ new: Plan) {
        _lock.withLockVoid {
            _iterator = new.makeIterator()
        }
        scheduleNextExecution()
    }

    /// The number of task suspensions.
    public var suspensionCount: UInt64 {
        return _lock.withLock {
            _suspensionCount
        }
    }

    /// Suspends this task.
    public func suspend() {
        _lock.withLockVoid {
            if _suspensionCount < UInt64.max {
                _timer.suspend()
                _suspensionCount += 1
            }
        }
    }

    /// Resumes this task.
    public func resume() {
        _lock.withLockVoid {
            if _suspensionCount > 0 {
                _timer.resume()
                _suspensionCount -= 1
            }
        }
    }

    /// Cancels this task.
    public func cancel() {
        _lock.withLockVoid {
            _timer.cancel()
        }
        TaskCenter.default.remove(self)
    }

    // MARK: - Action

    /// The number of actions in this task.
    public var countOfActions: Int {
        return _lock.withLock {
            _actions.count
        }
    }

    /// Adds action to this task.
    @discardableResult
    public func addAction(_ action: @escaping (Task) -> Void) -> ActionKey {
        return _lock.withLock {
            return _actions.append(action).asActionKey()
        }
    }

    /// Removes action by key from this task.
    public func removeAction(byKey key: ActionKey) {
        _lock.withLockVoid {
            _ = _actions.removeValue(for: key.bagKey)
        }
    }

    /// Removes all actions from this task.
    public func removeAllActions() {
        _lock.withLockVoid {
            _actions.removeAll()
        }
    }
}

extension Task: Hashable {

    /// Hashes the essential components of this value by feeding them into the given hasher.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Returns a boolean value indicating whether two tasks are equal.
    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs === rhs
    }
}
