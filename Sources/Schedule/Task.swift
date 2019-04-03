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

/// `Task` represents a timed task.
open class Task {

    /// The unique id of this task.
    public let id = UUID()

    public typealias Action = (Task) -> Void

    private let _mutex = NSRecursiveLock()

    private var _iterator: AnyIterator<Interval>
    private var _timer: DispatchSourceTimer

    private lazy var _onElapseActions = Bag<Action>()
    private lazy var _onDeinitActions = Bag<Action>()

    private lazy var _suspensions: UInt64 = 0
    private lazy var _timeline = Timeline()

    private lazy var _countOfExecutions: Int = 0

    private lazy var _lifetime: Interval = Int.max.seconds
    private lazy var _lifetimeTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource()
        timer.setEventHandler { [weak self] in
            self?.cancel()
        }
        timer.schedule(after: _lifetime)
        timer.resume()
        return timer
    }()

    /// The task center which this task currently in.
    open internal(set) weak var taskCenter: TaskCenter?

    /// The mutex used to guard task center operations.
    let taskCenterMutex = NSRecursiveLock()

    /// Initializes a normal task with specified plan and dispatch queue.
    ///
    /// - Parameters:
    ///   - plan: The plan.
    ///   - queue: The dispatch queue to which all actions should be added.
    ///   - onElapse: The action to do when time is out.
    init(plan: Plan,
         queue: DispatchQueue?,
         onElapse: @escaping (Task) -> Void) {

        _iterator = plan.makeIterator()
        _timer = DispatchSource.makeTimerSource(queue: queue)

        _onElapseActions.append(onElapse)

        _timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.elapse()
        }

        if let interval = _iterator.next(), !interval.isNegative {
            _timer.schedule(after: interval)
            _timeline.estimatedNextExecution = Date().adding(interval)
        }

        _timer.resume()
        TaskCenter.default.add(self)
    }

    deinit {
        for action in _onDeinitActions {
            action(self)
        }

        while _suspensions > 0 {
            _timer.resume()
            _suspensions -= 1
        }

        cancel()
    }

    private func scheduleNext() {
        _mutex.withLock {
            let now = Date()
            var estimated = _timeline.estimatedNextExecution ?? now
            repeat {
                guard let interval = _iterator.next(), !interval.isNegative else {
                    _timeline.estimatedNextExecution = nil
                    return
                }
                estimated = estimated.adding(interval)
            } while (estimated < now)

            _timeline.estimatedNextExecution = estimated
            _timer.schedule(after: _timeline.estimatedNextExecution!.interval(since: now))
        }
    }

    /// Execute this task now, without disrupting its plan.
    public func execute() {
        let actions = _mutex.withLock { () -> Bag<Task.Action> in
            let now = Date()
            if _timeline.firstExecution == nil {
                _timeline.firstExecution = now
            }
            _timeline.lastExecution = now
            _countOfExecutions += 1
            return _onElapseActions
        }
        actions.forEach { $0(self) }
    }

    private func elapse() {
        scheduleNext()
        execute()
    }

    #if canImport(ObjectiveC)
    open func host(on target: AnyObject) {
        DeinitObserver.observe(target) { [weak self] in
            self?.cancel()
        }
    }
    #endif

    /// The number of times the task has been executed.
    public var countOfExecutions: Int {
        return _mutex.withLock {
            _countOfExecutions
        }
    }

    /// A Boolean indicating whether the task was canceled.
    public var isCancelled: Bool {
        return _mutex.withLock {
            _timer.isCancelled
        }
    }

    // MARK: - Manage

    /// Reschedules this task with the new plan.
    public func reschedule(_ new: Plan) {
        _mutex.withLock {
            _iterator = new.makeIterator()
        }
        scheduleNext()
    }

    /// Suspensions of this task.
    public var suspensions: UInt64 {
        return _mutex.withLock {
            _suspensions
        }
    }

    /// Suspends this task.
    public func suspend() {
        _mutex.withLock {
            if _suspensions < UInt64.max {
                _timer.suspend()
                _suspensions += 1
            }
        }
    }

    /// Resumes this task.
    public func resume() {
        _mutex.withLock {
            if _suspensions > 0 {
                _timer.resume()
                _suspensions -= 1
            }
        }
    }

    /// Cancels this task.
    public func cancel() {
        _mutex.withLock {
            _timer.cancel()
        }
        TaskCenter.default.remove(self)
    }

    @discardableResult
    open func onDeinit(_ body: @escaping Action) -> ActionKey {
        return _mutex.withLock {
            return _onDeinitActions.append(body).asActionKey()
        }
    }

    // MARK: - Lifecycle

    /// The snapshot timeline of this task.
    public var timeline: Timeline {
        return _mutex.withLock {
            _timeline
        }
    }

    /// The lifetime of this task.
    public var lifetime: Interval {
        return _mutex.withLock {
            _lifetime
        }
    }

    /// The rest of lifetime.
    public var restOfLifetime: Interval {
        return _mutex.withLock {
            _lifetime - Date().interval(since: _timeline.initialization)
        }
    }

    /// Set a new lifetime for this task.
    ///
    /// If this task has already ended its lifetime, setting will fail,
    /// if new lifetime is shorter than its age, setting will fail, too.
    ///
    /// - Returns: `true` if set successfully, `false` if not.
    @discardableResult
    public func setLifetime(_ interval: Interval) -> Bool {
        guard restOfLifetime.isPositive else { return false }

        _mutex.lock()
        let age = Date().interval(since: _timeline.initialization)
        guard age.isShorter(than: interval) else {
            _mutex.unlock()
            return false
        }

        _lifetime = interval
        _lifetimeTimer.schedule(after: interval - age)
        _mutex.unlock()
        return true
    }

    /// Add an interval to this task's lifetime.
    ///
    /// If this task has already ended its lifetime, adding will fail,
    /// if new lifetime is shorter than its age, adding will fail, too.
    ///
    /// - Returns: `true` if set successfully, `false` if not.
    @discardableResult
    public func addLifetime(_ interval: Interval) -> Bool {
        var rest = restOfLifetime
        guard rest.isPositive else { return false }
        rest += interval
        guard rest.isPositive else { return false }
        _mutex.withLock {
            _lifetime += interval
            _lifetimeTimer.schedule(after: rest)
        }
        return true
    }

    /// Subtract an interval to this task's lifetime.
    ///
    /// If this task has already ended its lifetime, subtracting will fail,
    /// if new lifetime is shorter than its age, subtracting will fail, too.
    ///
    /// - Returns: `true` if set successfully, `false` if not.
    @discardableResult
    public func subtractLifetime(_ interval: Interval) -> Bool {
        return addLifetime(interval.opposite)
    }

    // MARK: - Action

    /// The number of actions in this task.
    public var countOfActions: Int {
        return _mutex.withLock {
            _onElapseActions.count
        }
    }

    /// Adds action to this task.
    @discardableResult
    public func addAction(_ action: @escaping (Task) -> Void) -> ActionKey {
        return _mutex.withLock {
            return _onElapseActions.append(action).asActionKey()
        }
    }

    /// Removes action by key from this task.
    public func removeAction(byKey key: ActionKey) {
        _mutex.withLock {
            _ = _onElapseActions.delete(key.bagKey)
        }
    }

    /// Removes all actions from this task.
    public func removeAllActions() {
        _mutex.withLock {
            _onElapseActions.clear()
        }
    }

    // MARK: - Tag
    open func add(to: TaskCenter) {
        _mutex.lock()
    }
}

extension Task: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Returns a boolean value indicating whether two tasks are equal.
    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs === rhs
    }
}

extension Task: CustomStringConvertible {

    /// A textual representation of this task.
    public var description: String {
        return "Task: { " +
        "\"isCancelled\": \(_timer.isCancelled), " +
        "\"countOfElapseActions\": \(_onElapseActions.count), " +
        "\"countOfDeinitActions\": \(_onDeinitActions.count), " +
        "\"countOfExecutions\": \(_countOfExecutions), " +
        "\"lifeTime\": \(_lifetime), " +
        "\"timeline\": \(_timeline)" +
        " }"
    }
}

extension Task: CustomDebugStringConvertible {

    /// A textual representation of this task for debugging.
    public var debugDescription: String {
        return description
    }
}
