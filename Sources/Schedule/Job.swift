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
    public private(set) var lastFire: Date?
    
    /// Next time this job will be invoked at.
    public var nextFire: Date? { return deadline }
    
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
        self.tasks.put(onElapse)
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer.setEventHandler { [weak self] in
            self?.elapse()
        }
        self.timer.schedule(after: interval)
        self.timer.resume()
        JobCenter.shared.add(self, tag: tag)
    }
    
    private func elapse() {
        let now = Date()
        lock.lock()
        lastFire = now
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
    
    // MARK: Tasks
    public func add(_ task: @escaping (Job) -> Void) -> TaskKey {
        lock.lock()
        let key = tasks.put(task)
        lock.unlock()
        return key
    }
    
    public func remove(_ key: TaskKey) {
        lock.lock()
        tasks.delete(BucketKey(rawValue: key.underlying))
        lock.unlock()
    }
    
    public func removeAllTasks() {
        lock.lock()
        tasks.clear()
        lock.unlock()
    }
    
    // MARK: Jobs
    
    /// Suspend this job.
    public func suspend() {
        lock.lock()
        suspensions = suspensions.clampedAdding(1)
        lock.unlock()
        timer.suspend()
    }
    
    /// Resume this job.
    public func resume() {
        lock.lock()
        let canResume = suspensions > 0
        suspensions -= 1
        lock.unlock()
        
        if canResume {
            timer.resume()
        }
    }
    
    /// Cancel this job.
    public func cancel() {
        timer.cancel()
        JobCenter.shared.remove(self)
    }
    
    /// Suspend all job that attach the tag.
    public static func suspend(_ tag: String) {
        JobCenter.shared.jobs(for: tag).forEach { $0.suspend() }
    }
    
    /// Resume all job that attach the tag.
    public static func resume(_ tag: String) {
        JobCenter.shared.jobs(for: tag).forEach { $0.resume() }
    }
    
    /// Cancel all job that attach the tag.
    public static func cancel(_ tag: String) {
        JobCenter.shared.jobs(for: tag).forEach { $0.cancel() }
    }
    
    deinit {
        lock.lock()
        while suspensions > 0 {
            timer.resume()
            suspensions -= 1
        }
        lock.unlock()
        timer.cancel()
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

extension Optional: Hashable where Wrapped: Job {
    
    /// The hashValue of this job.
    ///
    /// If job is nil, then return 0.
    public var hashValue: Int {
        if case .some(let wrapped) = self {
            return wrapped.hashValue
        }
        return 0
    }
    
    /// Returns a boolean value indicating whether the job is equal to another job.
    ///
    /// If both of these two are nil, then return true.
    public static func ==(lhs: Optional<Job>, rhs: Optional<Job>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
