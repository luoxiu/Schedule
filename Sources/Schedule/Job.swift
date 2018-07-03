//
//  Job.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

public class Job {
    
    public private(set) var lastTime: Date?
    public private(set) var nextTime: Date?
    
    private var iterator: Atomic<AnyIterator<Interval>>
    private let onElapse: (Job) -> Void
    private let timer: DispatchSourceTimer
    
    private var suspensions = Atomic<UInt>(0)
    
    init(schedule: Schedule,
         queue: DispatchQueue? = nil,
         onElapse: @escaping (Job) -> Void) {
        self.iterator = Atomic(schedule.makeIterator())
        self.onElapse = onElapse
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        
        let interval = self.iterator.withLock({ $0.next() })?.dispatchInterval ?? DispatchTimeInterval.never
        self.timer.schedule(wallDeadline: .now() + interval)
        self.timer.setEventHandler { [weak self] in
            self?.elapse()
        }
        self.timer.resume()
        JobCenter.shared.add(self)
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
        timer.schedule(wallDeadline: .now() + i.dispatchInterval)
    }
    
    public func reschedule(_ schedule: Schedule) {
        iterator.withLock {
            $0 = schedule.makeIterator()
        }
    }
    
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
    
    public func cancel() {
        timer.cancel()
        JobCenter.shared.remove(self)
    }
    
    public func cancel(_ tag: String) {
        JobCenter.shared.jobs(for: tag).forEach { $0.cancel() }
    }
    
    public func suspend(_ tag: String) {
        JobCenter.shared.jobs(for: tag).forEach { $0.suspend() }
    }
    
    public func resume(_ tag: String) {
        JobCenter.shared.jobs(for: tag).forEach { $0.resume() }
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
    
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
    public static func ==(lhs: Job, rhs: Job) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Optional: Hashable where Wrapped: Job {
    
    public var hashValue: Int {
        if case .some(let wrapped) = self {
            return wrapped.hashValue
        }
        return 0
    }
    
    public static func ==(lhs: Optional<Job>, rhs: Optional<Job>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

private class JobCenter {
    
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

