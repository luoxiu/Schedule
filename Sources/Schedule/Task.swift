//
//  Task.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

/// `ActionKey` represents a token that can be used to operate action.
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
    
    private var _timer: DispatchSourceTimer?
    
    private typealias Action = (Task) -> Void
    private lazy var _actions = Bucket<Action>()
    
    private lazy var _suspensions: UInt64 = 0
    private lazy var _timeline = Timeline()
    private lazy var _tags: Set<String> = []
    
    init(schedule: Schedule,
         queue: DispatchQueue? = nil,
         tag: String? = nil,
         onElapse: @escaping (Task) -> Void) {
        
        self._iterator = schedule.makeIterator()
        
        guard let interval = self._iterator.next() else { return }
        
        self._timer = DispatchSource.makeTimerSource(queue: queue)
        
        self._actions.add(onElapse)
        self._timer?.setEventHandler { [weak self] in
            self?.elapse()
        }
        self._timer?.schedule(after: interval)
        
        let now = Date()
        self._timeline.activate = now
        self._timeline.nextSchedule = now.addingInterval(interval)
        TaskCenter.shared.add(self, withTag: tag)
        
        self._timer?.resume()
    }
    
    private func elapse() {
        _lock.lock()
        let now = Date()
        if _timeline.firstSchedule == nil {
            _timeline.firstSchedule = now
        }
        _timeline.lastSchedule = now
        
        guard let interval = _iterator.next() else {
            _timeline.nextSchedule = nil
            let actions = _actions
            _lock.unlock()
            actions.forEach { $0(self) }
            return
        }
        
        _timeline.nextSchedule = _timeline.nextSchedule?.addingInterval(interval)
        
        _timer?.schedule(after: (_timeline.nextSchedule ?? Date.distantFuture).interval(since: now))
        let actions = _actions
        _lock.unlock()
        
        actions.forEach { $0(self) }
    }
    
    /// The timeline of this task.
    public var timeline: Timeline {
        return _lock.withLock {
            _timeline
        }
    }
    
    /// All tags associated with this task.
    public var tags: Set<String> {
        return _lock.withLock {
            _tags
        }
    }
    
    /// Reschedules this task with the new schedule.
    public func reschedule(_ new: Schedule) {
        _lock.withLock {
            _iterator = new.makeIterator()
        }
    }
    
    /// Suspends this task.
    public func suspend() {
        guard let timer = _timer else { return }
        _lock.withLock {
            if _suspensions < UInt64.max {
                timer.suspend()
                _suspensions += 1
            }
        }
    }
    
    /// Resumes this task.
    public func resume() {
        guard let timer = _timer else { return }
        _lock.withLock {
            if _suspensions > 0 {
                timer.resume()
                _suspensions -= 1
            }
        }
    }
    
    /// Cancels this task.
    public func cancel() {
        guard let timer = _timer else { return }
        _lock.withLock {
            timer.cancel()
            _timeline.cancel = Date()
        }
        TaskCenter.shared.remove(self)
    }
    
    deinit {
        guard let timer = _timer else { return }
        _lock.withLock {
            while _suspensions > 0 {
                timer.resume()
                _suspensions -= 1
            }
        }
        cancel()
    }
}


extension Task {
    
    /// Adds the action to this task.
    @discardableResult
    public func addAction(_ action: @escaping (Task) -> Void) -> ActionKey {
        return _lock.withLock {
            _actions.add(action)
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
}

extension Task {
    
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
            TaskCenter.shared.add(tag: tag, to: self)
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
            TaskCenter.shared.remove(tag: tag, from: self)
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
        TaskCenter.shared.tasks(forTag: tag).forEach { $0.suspend() }
    }
    
    /// Resumes all tasks that have the tag.
    public static func resume(byTag tag: String) {
        TaskCenter.shared.tasks(forTag: tag).forEach { $0.resume() }
    }
    
    /// Cancels all tasks that have the tag.
    public static func cancel(byTag tag: String) {
        TaskCenter.shared.tasks(forTag: tag).forEach { $0.cancel() }
    }
}


extension Task: Hashable {
    
    /// The task's hash value.
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
    /// Returns a boolean value indicating whether two tasks are equal.
    public static func ==(lhs: Task, rhs: Task) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
