//
//  DependentJob.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

extension Schedule {
    
    /// Schedule a job with this schedule.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the job will be submitted.
    ///   - dependOn: The object to bind.
    ///   - onElapse: The job to invoke when time is out.
    /// - Returns: The job just created.
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     dependOn: AnyObject,
                     onElapse: @escaping (Job) -> Void) -> Job {
        
        return DependentJob(schedule: self, queue: queue, dependOn: dependOn, onElapse: onElapse)
    }
    
    /// Schedule a job with this schedule.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the job will be submitted.
    ///   - dependOn: The object to bind.
    ///   - onElapse: The job to invoke when time is out.
    /// - Returns: The job just created.
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     dependOn: AnyObject,
                     onElapse: @escaping () -> Void) -> Job {
        return self.do(queue: queue, dependOn: dependOn, onElapse: { (_) in onElapse() })
    }
}

private final class DependentJob: Job {
    
    weak var dependOn: AnyObject?
    
    init(schedule: Schedule, queue: DispatchQueue?, dependOn: AnyObject, onElapse: @escaping (Job) -> Void) {
        super.init(schedule: schedule, queue: queue) { (job) in
            guard (job as? DependentJob)?.dependOn != nil else {
                job.cancel()
                return
            }
            onElapse(job)
        }
        self.dependOn = dependOn
    }
}
