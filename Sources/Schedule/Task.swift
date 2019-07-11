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

    // MARK: - Private properties
    
    private let _lock = NSLock()

    private var _iterator: AnyIterator<Interval>
    private let _timer: DispatchSourceTimer

    private var _actions = Bag<Action>()

    private var _suspensionCount = 0
    private var _executionCount = 0

    private var _executionDates: [Date]?
    private var _estimatedNextExecutionDate: Date?

    private var _taskCenter: TaskCenter?
    private var _tags: Set<String> = []

    // MARK: - Public properties

    /// The unique id of this task.
    public let id = UUID()

    public typealias Action = (Task) -> Void

    /// The date of creation.
    public let creationDate = Date()

    /// The date of first execution.
    open var firstExecutionDate: Date? {
        return _lock.withLock { _executionDates?.first }
    }

    /// The date of last execution.
    open var lastExecutionDate: Date? {
        return _lock.withLock { _executionDates?.last }
    }

    /// Histories of executions.
    open var executionDates: [Date]? {
        return _lock.withLock { _executionDates }
    }

    /// The date of estimated next execution.
    open var estimatedNextExecutionDate: Date? {
        return _lock.withLock { _estimatedNextExecutionDate }
    }

    /// The number of task executions.
    public var executionCount: Int {
        return _lock.withLock {
            _executionCount
        }
    }

    /// The number of task suspensions.
    public var suspensionCount: Int {
        return _lock.withLock {
            _suspensionCount
        }
    }

    /// The number of actions in this task.
    public var actionCount: Int {
        return _lock.withLock {
            _actions.count
        }
    }

    /// A Boolean indicating whether the task was canceled.
    public var isCancelled: Bool {
        return _lock.withLock {
            _timer.isCancelled
        }
    }

    /// The task center to which this task currently belongs.
    open var taskCenter: TaskCenter? {
        return _lock.withLock { _taskCenter }
    }


    // MARK: - Init

    /// Initializes a timing task.
    ///
    /// - Parameters:
    ///   - plan: The plan.
    ///   - queue: The dispatch queue to which the action should be dispatched.
    ///   - action: A block to be executed when time is up.
    init(
        plan: Plan,
        queue: DispatchQueue?,
        action: @escaping (Task) -> Void
    ) {
        _iterator = plan.makeIterator()
        _timer = DispatchSource.makeTimerSource(queue: queue)

        _actions.append(action)

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

        self.removeFromTaskCenter()
    }

    private func elapse() {
        scheduleNextExecution()
        executeNow()
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
    open func executeNow() {
        let actions = _lock.withLock { () -> Bag<Task.Action> in
            let now = Date()
            if _executionDates == nil {
                _executionDates = [now]
            } else {
                _executionDates?.append(now)
            }
            _executionCount += 1
            return _actions
        }
        actions.forEach { $0(self) }
    }

    // MARK: - Features

    /// Reschedules this task with the new plan.
    public func reschedule(_ new: Plan) {
        _lock.lock()
        if _timer.isCancelled {
            _lock.unlock()
            return
        }
        
        _iterator = new.makeIterator()
        _lock.unlock()
        scheduleNextExecution()
    }

    /// Suspends this task.
    public func suspend() {
        _lock.withLockVoid {
            if _timer.isCancelled { return }

            if _suspensionCount < UInt64.max {
                _timer.suspend()
                _suspensionCount += 1
            }
        }
    }

    /// Resumes this task.
    public func resume() {
        _lock.withLockVoid {
            if _timer.isCancelled { return }

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
            _suspensionCount = 0
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
    
    /// Adds this task to the given task center.
    func addToTaskCenter(_ center: TaskCenter) {
        _lock.lock(); defer { _lock.unlock() }
        
        if _taskCenter === center { return }
        
        let c = _taskCenter
        _taskCenter = center
        c?.removeSimply(self)
        center.addSimply(self)
    }
    
    /// Removes this task from the given task center.
    public func removeFromTaskCenter() {
        _lock.lock(); defer { _lock.unlock() }
        
        guard let center = self._taskCenter else {
            return
        }
        _taskCenter = nil
        center.removeSimply(self)
    }
}

extension Task: Hashable {

    /// Hashes the essential components of this value by feeding them into the given hasher.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Returns a boolean value indicating whether two tasks are equal.
    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }
}
