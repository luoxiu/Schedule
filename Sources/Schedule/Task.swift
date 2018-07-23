//
//  Task.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

public protocol ActionKey {
    var underlying: UInt64 { get }
}

extension BucketKey: ActionKey {
    var underlying: UInt64 {
        return rawValue
    }
}

/// `Task` represents a series of actions to be scheduled.
public class Task {
    
    /// The timstamp last time this task was scheduled at.
    public var lastSchedule: Date? {
        lock.lock()
        defer { lock.unlock() }
        return _lastSchedule
    }
    private var _lastSchedule: Date?
    
    /// The timestamp next time this task will be scheduled at.
    public var nextSchedule: Date? {
        lock.lock()
        defer { lock.unlock() }
        return deadline
    }
    
    /// All tags associate with this task.
    public var tags: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return _tags
    }
    private var _tags: Set<String> = []
    
    private lazy var lock = NSRecursiveLock()
    
    private var iterator: AnyIterator<Interval>
    
    private var deadline: Date!
    
    private typealias Action = (Task) -> Void
    private var actions = Bucket<Action>.empty

    private var timer: DispatchSourceTimer!
    
    private var suspensions: UInt64 = 0
    
    init(schedule: Schedule,
         queue: DispatchQueue? = nil,
         tag: String? = nil,
         onElapse: @escaping (Task) -> Void) {
        
        self.iterator = schedule.makeIterator()
        guard let interval = self.iterator.next() else {
            return
        }
        self.deadline = Date() + interval
        self.actions.insert(onElapse)
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer.setEventHandler { [weak self] in
            self?.elapse()
        }
        self.timer.schedule(after: interval)
        self.timer.resume()
        TaskCenter.shared.add(self, withTag: tag)
    }
    
    private func elapse() {
        let now = Date()
        
        lock.lock()
        _lastSchedule = now
        guard let interval = iterator.next(), !interval.isNegative else {
            deadline = nil
            let _actions = actions
            lock.unlock()
            _actions.forEach { $0(self) }
            return
        }
        deadline = deadline.addingInterval(interval)
        let _actions = actions
        timer.schedule(after: interval)
        lock.unlock()
        
        _actions.forEach { $0(self) }
    }
    
    /// Reschedules this task with the new schedule.
    public func reschedule(_ new: Schedule) {
        lock.lock()
        iterator = new.makeIterator()
        lock.unlock()
    }
    
    /// Suspends this task.
    public func suspend() {
        lock.lock()
        if suspensions < UInt64.max {
            suspensions += 1
            timer.suspend()
        }
        lock.unlock()
    }
    
    /// Resumes this task.
    public func resume() {
        lock.lock()
        if suspensions > 0 {
            suspensions -= 1
            timer.resume()
        }
        lock.unlock()
    }
    
    /// Cancels this task.
    public func cancel() {
        lock.lock()
        timer.cancel()
        lock.unlock()
        TaskCenter.shared.remove(self)
    }
    
    deinit {
        lock.lock()
        while suspensions > 0 {
            suspensions -= 1
            timer.resume()
        }
        lock.unlock()
        cancel()
    }
}


extension Task {
    
    /// Adds an action to this task.
    @discardableResult
    public func addAction(_ action: @escaping (Task) -> Void) -> ActionKey {
        lock.lock()
        let key = actions.insert(action)
        lock.unlock()
        return key
    }
    
    /// Removes the key's corresponding action from this task.
    public func removeAction(byKey key: ActionKey) {
        lock.lock()
        actions.removeElement(byKey: BucketKey(rawValue: key.underlying))
        lock.unlock()
    }
    
    /// Removes all actions from this task.
    public func removeAllActions() {
        lock.lock()
        actions.removeAll()
        lock.unlock()
    }
}

extension Task {
    
    /// Adds tags to this task.
    public func addTags(_ tags: [String]) {
        let set = Set(tags)
        
        lock.lock()
        let intersection = set.intersection(self._tags)
        guard intersection.count > 0 else {
            lock.unlock()
            return
        }
        self._tags.formUnion(intersection)
        lock.unlock()
        
        for tag in intersection {
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
        let set = Set(tags)
        lock.lock()
        let intersection = set.intersection(self._tags)
        guard intersection.count > 0 else {
            lock.unlock()
            return
        }
        for tag in intersection {
            self._tags.insert(tag)
        }
        lock.unlock()
        
        for tag in intersection {
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
