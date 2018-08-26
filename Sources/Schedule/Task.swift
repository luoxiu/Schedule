//
//  Task.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

/// `ActionKey` represents a token that can be used to manage action.
public protocol ActionKey {
    var underlying: UInt64 { get }
}

extension BucketKey: ActionKey {
    var underlying: UInt64 {
        return rawValue
    }
}

/// `Task` represents a job to be scheduled.
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

    private lazy var _lifetime: Interval = Int.max.second
    private lazy var _lifetimeTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource()
        timer.setEventHandler {
            self.cancel()
            timer.cancel()
        }
        timer.schedule(after: _lifetime)
        timer.resume()
        return timer
    }()

    init(schedule: Schedule,
         queue: DispatchQueue? = nil,
         tag: String? = nil,
         onElapse: @escaping (Task) -> Void) {

        _iterator = schedule.makeIterator()
        _timer = DispatchSource.makeTimerSource(queue: queue)

        _actions.append(onElapse)

        _timer.setEventHandler { [weak self] in
            self?.elapse()
        }

        // Consider `nil` a distant future.
        let interval = _iterator.next() ?? Date.distantFuture.intervalSinceNow
        _timer.schedule(after: interval)
        _timeline.estimatedNextExecution = Date().adding(interval)

        TaskHub.shared.add(self, withTag: tag)
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
            guard let interval = _iterator.next() else {
                _timeline.estimatedNextExecution = nil
                return
            }
            _timeline.estimatedNextExecution = _timeline.estimatedNextExecution?.adding(interval)
            _timer.schedule(after: (_timeline.estimatedNextExecution ?? Date.distantFuture).interval(since: Date()))
        }
    }

    /// Execute this task now, without disrupting its schedule.
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

    /// The number of times this task has been executed.
    public var countOfExecution: Int {
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

    /// Reschedules this task with the new schedule.
    public func reschedule(_ new: Schedule) {
        _lock.withLock {
            _iterator = new.makeIterator()
            _timeline.estimatedNextExecution = Date()
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
            _lifetime - Date().interval(since: _timeline.initialize)
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
        let age = Date().interval(since: _timeline.initialize)
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
            _ = _actions.removeElement(for: BucketKey(rawValue: key.underlying))
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
}

extension Task {

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
