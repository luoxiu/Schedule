//
//  Job.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

/// `Job` represents an action that to be invoke.
public final class Job {
    
    /// Last time this job was invoked at.
    public private(set) var lastTime: Date?
    
    /// Next time this job will be invoked at.
    public private(set) var nextTime: Date?
    
    private var iterator: AtomicBox<AnyIterator<Interval>>
    private let onElapse: (Job) -> Void
    private let timer: DispatchSourceTimer
    
    private var suspensions = AtomicBox<UInt>(0)
    
    init(schedule: Schedule,
         queue: DispatchQueue? = nil,
         tag: String? = nil,
         onElapse: @escaping (Job) -> Void) {
        self.iterator = AtomicBox(schedule.makeIterator())
        self.onElapse = onElapse
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        
        let interval = self.iterator.withLock({ $0.next() })?.asDispatchTimeInterval() ?? DispatchTimeInterval.never
        self.timer.schedule(wallDeadline: .now() + interval)
        self.timer.setEventHandler { [weak self] in
            self?.elapse()
        }
        self.timer.resume()
        JobCenter.shared.add(self, tag: tag)
    }
    
    private func elapse() {
        let now = Date()
        self.lastTime = now
        
        let interval = iterator.withLock({ $0.next() })
        
        guard let i = interval, !i.isNegative else {
            nextTime = nil
            onElapse(self)
            return
        }
        
        nextTime = now.addingTimeInterval(i.nanoseconds / pow(10, 9))
        onElapse(self)
        timer.schedule(wallDeadline: .now() + i.asDispatchTimeInterval())
    }
    
    /// Reschedule this job with the schedule.
    public func reschedule(_ schedule: Schedule) {
        iterator.withLock {
            $0 = schedule.makeIterator()
        }
    }
    
    /// Suspend this job.
    public func suspend() {
        let canSuspend = suspensions.withLock { (n) -> Bool in
            guard n < UInt.max else { return false }
            n += 1
            return true
        }
        
        if canSuspend {
            timer.suspend()
        }
    }
    
    /// Resume this job.
    public func resume() {
        let canResume = suspensions.withLock { (n) -> Bool in
            guard n > 0 else { return false }
            n -= 1
            return true
        }
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
        suspensions.withLock { (n) in
            while n > 0 {
                timer.resume()
                n -= 1
            }
        }
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

private final class JobCenter {
    
    static let shared = JobCenter()
    
    private var lock = NSLock()
    
    private var jobs: [Int: Job] = [:]
    private var tags: [String: Set<Job?>] = [:]
    
    func add(_ job: Job, tag: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        jobs[job.hashValue] = job
        if let tag = tag {
            if tags[tag] == nil { tags[tag] = [] }
            weak var j = job
            tags[tag]?.insert(j)
        }
    }
    
    func remove(_ job: Job) {
        lock.lock()
        defer { lock.unlock() }
        
        jobs[job.hashValue] = nil
    }
    
    func jobs(for tag: String) -> [Job] {
        lock.lock()
        defer { lock.unlock() }
        
        if let jobs = tags[tag] {
            return jobs.compactMap({ $0 })
        }
        return []
    }
}

