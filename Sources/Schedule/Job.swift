//
//  Job.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

public protocol TaskKey {
    var underlying: UInt64 { get }
}

extension BucketKey: TaskKey {
    var underlying: UInt64 {
        return rawValue
    }
}

/// `Job` represents an action that to be invoke.
public class Job {
    
    /// Last time this job was invoked at.
    public var lastFire: Date? {
        lock.lock()
        defer { lock.unlock() }
        return _lastFire
    }
    private var _lastFire: Date?
    
    /// Next time this job will be invoked at.
    public var nextFire: Date? {
        lock.lock()
        defer { lock.unlock() }
        return deadline
    }
    
    public var tags: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return _tags
    }
    private var _tags: Set<String> = []
    
    private lazy var lock = NSRecursiveLock()
    
    private var iterator: AnyIterator<Interval>
    
    private var deadline: Date!
    
    private typealias Task = (Job) -> Void
    private var tasks = Bucket<Task>.empty

    private var timer: DispatchSourceTimer!
    
    private var suspensions: UInt64 = 0
    
    init(schedule: Schedule,
         queue: DispatchQueue? = nil,
         tag: String? = nil,
         onElapse: @escaping (Job) -> Void) {
        
        self.iterator = schedule.makeIterator()
        guard let interval = self.iterator.next() else {
            return
        }
        self.deadline = Date() + interval
        self.tasks.insert(onElapse)
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer.setEventHandler { [weak self] in
            self?.elapse()
        }
        self.timer.schedule(after: interval)
        self.timer.resume()
        JobCenter.shared.add(self, withTag: tag)
    }
    
    private func elapse() {
        let now = Date()
        lock.lock()
        _lastFire = now
        guard let interval = iterator.next(), !interval.isNegative else {
            deadline = nil
            tasks.forEach { $0(self) }
            return
        }
        deadline = deadline.addingInterval(interval)
        tasks.forEach { $0(self) }
        lock.unlock()
        
        timer.schedule(after: interval)
    }
    
    // MARK: Reschedule
    
    /// Reschedule this job with the schedule.
    public func reschedule(_ schedule: Schedule) {
        lock.lock()
        iterator = schedule.makeIterator()
        lock.unlock()
    }
    
    /// Suspend this job.
    public func suspend() {
        lock.lock()
        let canSuspend = suspensions < UInt64.max
        if canSuspend {
            suspensions += 1
            timer.suspend()
        }
        lock.unlock()
    }
    
    /// Resume this job.
    public func resume() {
        lock.lock()
        let canResume = suspensions > 0
        if canResume {
            suspensions -= 1
            timer.resume()
        }
        lock.unlock()
    }
    
    /// Cancel this job.
    public func cancel() {
        timer.cancel()
        JobCenter.shared.remove(self)
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


extension Job {
    
    public func addTask(_ task: @escaping (Job) -> Void) -> TaskKey {
        lock.lock()
        let key = tasks.insert(task)
        lock.unlock()
        return key
    }
    
    public func removeTask(for key: TaskKey) {
        lock.lock()
        tasks.removeElement(for: BucketKey(rawValue: key.underlying))
        lock.unlock()
    }
    
    public func removeAllTasks() {
        lock.lock()
        tasks.removeAll()
        lock.unlock()
    }
}

extension Job {
    
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
            JobCenter.shared.add(tag: tag, for: self)
        }
    }
    
    public func addTags(_ tags: String...) {
        addTags(tags)
    }
    
    public func addTag(_ tag: String) {
        addTags(tag)
    }
    
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
            JobCenter.shared.remove(tag: tag, from: self)
        }
    }
    
    public func removeTags(_ tags: String...) {
        removeTags(tags)
    }
    
    public func removeTag(_ tag: String) {
        removeTags(tag)
    }
}


extension Job {
    
    /// Suspend all job that attach the tag.
    public static func suspend(_ tag: String) {
        JobCenter.shared.jobs(forTag: tag).forEach { $0.suspend() }
    }
    
    /// Resume all job that attach the tag.
    public static func resume(_ tag: String) {
        JobCenter.shared.jobs(forTag: tag).forEach { $0.resume() }
    }
    
    /// Cancel all job that attach the tag.
    public static func cancel(_ tag: String) {
        JobCenter.shared.jobs(forTag: tag).forEach { $0.cancel() }
    }
}


extension Job: Hashable {
    
    /// The hashValue of this job.
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
    /// Returns a boolean value indicating whether the job is equal to another job.
    public static func ==(lhs: Job, rhs: Job) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
