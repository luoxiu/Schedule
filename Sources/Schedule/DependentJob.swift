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
    /// This method will receive a `dependOn` object as parameter,
    /// the returned job will not retain this object, on the contrary,
    /// it will observe this object's dealloc event: it this object
    /// is dealloced, job will not fire any more.
    ///
    /// This feature is very useful when you want to let a timer live and die
    /// with a controller.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the job will be submitted.
    ///   - dependOn: The object to depend on.
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
    /// This method will receive a `dependOn` object as parameter,
    /// the returned job will not retain this object, on the contrary,
    /// it will observe this object's dealloc event: it this object
    /// is dealloced, job will not fire any more.
    ///
    /// This feature is very useful when you want to let a timer live and die
    /// with a controller.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the job will be submitted.
    ///   - dependOn: The object to depend on.
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
