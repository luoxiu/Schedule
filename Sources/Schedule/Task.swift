import Foundation

/// `ActionKey` represents a token that can be used to remove the action.
public protocol ActionKey {
    var underlying: UInt64 { get }
}

extension BucketKey: ActionKey { }

/// `Task` represents a timed task.
public class Task {

    private let _lock = Lock()

    private var _iterator: AnyIterator<Interval>
    private var _timer: DispatchSourceTimer

    private typealias Action = (Task) -> Void
    private lazy var _actions = Bucket<Action>()

    private lazy var _suspensions: UInt64 = 0
    private lazy var _timeline = Timeline()
    private lazy var _tags: Set<String> = []
    private lazy var _countOfExecutions: Int = 0

    #if !canImport(ObjectiveC)
    private weak var _host: AnyObject? = TaskHub.shared
    #endif

    private lazy var _lifetime: Interval = Int.max.seconds
    private lazy var _lifetimeTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource()
        timer.setEventHandler {
            self.cancel()
        }
        timer.schedule(after: _lifetime)
        timer.resume()
        return timer
    }()

    init(plan: Plan,
         queue: DispatchQueue?,
         host: AnyObject?,
         onElapse: @escaping (Task) -> Void) {

        _iterator = plan.makeIterator()
        _timer = DispatchSource.makeTimerSource(queue: queue)

        _actions.append(onElapse)

        _timer.setEventHandler { [weak self] in
            guard let self = self else { return }

            #if !canImport(ObjectiveC)
            guard self._host != nil else {
                self.cancel()
                return
            }
            #endif

            self.elapse()
        }

        if let interval = _iterator.next(), !interval.isNegative {
            _timer.schedule(after: interval)
            _timeline.estimatedNextExecution = Date().adding(interval)
        }

        if let host = host {
            #if canImport(ObjectiveC)
            DeinitObserver.observe(host) { [weak self] in
                self?.cancel()
            }
            #else
            _host = host
            #endif
        }

        TaskHub.shared.add(self)
        _timer.resume()
    }

    deinit {
        _lock.withLock {
            while _suspensions > 0 {
                _timer.resume()
                _suspensions -= 1
            }
        }
        cancel()
    }

    private func scheduleNext() {
        _lock.withLock {
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
        let actions = _lock.withLock { () -> Bucket<Task.Action> in
            let now = Date()
            if _timeline.firstExecution == nil {
                _timeline.firstExecution = now
            }
            _timeline.lastExecution = now
            _countOfExecutions += 1
            return _actions
        }
        actions.forEach { $0(self) }
    }

    private func elapse() {
        scheduleNext()
        execute()
    }

    /// The number of times the task has been executed.
    public var countOfExecutions: Int {
        return _lock.withLock {
            _countOfExecutions
        }
    }

    /// A Boolean indicating whether the task was canceled.
    public var isCancelled: Bool {
        return _lock.withLock {
            _timer.isCancelled
        }
    }

    // MARK: - Manage

    /// Reschedules this task with the new plan.
    public func reschedule(_ new: Plan) {
        _lock.withLock {
            _iterator = new.makeIterator()
        }
        scheduleNext()
    }

    /// Suspensions of this task.
    public var suspensions: UInt64 {
        return _lock.withLock {
            _suspensions
        }
    }

    /// Suspends this task.
    public func suspend() {
        _lock.withLock {
            if _suspensions < UInt64.max {
                _timer.suspend()
                _suspensions += 1
            }
        }
    }

    /// Resumes this task.
    public func resume() {
        _lock.withLock {
            if _suspensions > 0 {
                _timer.resume()
                _suspensions -= 1
            }
        }
    }

    /// Cancels this task.
    public func cancel() {
        _lock.withLock {
            _timer.cancel()
        }
        TaskHub.shared.remove(self)
    }

    // MARK: - Lifecycle

    /// The snapshot timeline of this task.
    public var timeline: Timeline {
        return _lock.withLock {
            _timeline
        }
    }

    /// The lifetime of this task.
    public var lifetime: Interval {
        return _lock.withLock {
            _lifetime
        }
    }

    /// The rest of lifetime.
    public var restOfLifetime: Interval {
        return _lock.withLock {
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

        _lock.lock()
        let age = Date().interval(since: _timeline.initialization)
        guard age.isShorter(than: interval) else {
            _lock.unlock()
            return false
        }

        _lifetime = interval
        _lifetimeTimer.schedule(after: interval - age)
        _lock.unlock()
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
        _lock.withLock {
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
        return _lock.withLock {
            _actions.count
        }
    }

    /// Adds action to this task.
    @discardableResult
    public func addAction(_ action: @escaping (Task) -> Void) -> ActionKey {
        return _lock.withLock {
            _actions.append(action)
        }
    }

    /// Removes action by key from this task.
    public func removeAction(byKey key: ActionKey) {
        _lock.withLock {
            _ = _actions.removeElement(for: BucketKey(key.underlying))
        }
    }

    /// Removes all actions from this task.
    public func removeAllActions() {
        _lock.withLock {
            _actions.removeAll()
        }
    }

    // MARK: - Tag

    /// All tags associated with this task.
    public var tags: Set<String> {
        return _lock.withLock {
            _tags
        }
    }

    /// Adds tags to this task.
    public func addTags(_ tags: [String]) {
        var set = Set(tags)

        _lock.lock()
        set.subtract(_tags)
        guard set.count > 0 else {
            _lock.unlock()
            return
        }
        _tags.formUnion(set)
        _lock.unlock()

        for tag in set {
            TaskHub.shared.add(tag: tag, to: self)
        }
    }

    /// Adds tags to this task.
    public func addTags(_ tags: String...) {
        addTags(tags)
    }

    /// Adds the tag to this task.
    public func addTag(_ tag: String) {
        addTags(tag)
    }

    /// Removes tags from this task.
    public func removeTags(_ tags: [String]) {
        var set = Set(tags)
        _lock.lock()
        set.formIntersection(_tags)
        guard set.count > 0 else {
            _lock.unlock()
            return
        }
        _tags.subtract(set)
        _lock.unlock()

        for tag in set {
            TaskHub.shared.remove(tag: tag, from: self)
        }
    }

    /// Removes tags from this task.
    public func removeTags(_ tags: String...) {
        removeTags(tags)
    }

    /// Removes the tag from this task.
    public func removeTag(_ tag: String) {
        removeTags(tag)
    }

    /// Suspends all tasks that have the tag.
    public static func suspend(byTag tag: String) {
        TaskHub.shared.tasks(forTag: tag).forEach { $0.suspend() }
    }

    /// Resumes all tasks that have the tag.
    public static func resume(byTag tag: String) {
        TaskHub.shared.tasks(forTag: tag).forEach { $0.resume() }
    }

    /// Cancels all tasks that have the tag.
    public static func cancel(byTag tag: String) {
        TaskHub.shared.tasks(forTag: tag).forEach { $0.cancel() }
    }
}

extension Task: Hashable {

    /// The task's hash value.
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    /// Returns a boolean value indicating whether two tasks are equal.
    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Task: CustomStringConvertible {

    /// A textual representation of this task.
    public var description: String {
        return "Task: { " +
        "\"isCancelled\": \(_timer.isCancelled)" +
        "\"tags\": \(_tags), " +
        "\"countOfActions\": \(_actions.count), " +
        "\"countOfExecutions\": \(_countOfExecutions), " +
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
