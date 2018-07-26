//
//  ParasiticTask.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

extension Schedule {
    
    /// Schedules a task with this schedule.
    ///
    /// This method will receive a `host` object as a parameter,
    /// the returned task will not retain this object, on the contrary,
    /// it will observe this object, when this object is dealloced,
    /// task will not be scheduled any more, something like parasitism.
    ///
    /// This feature is very useful when you want a timer live and die
    /// with a controller.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the task will be submitted.
    ///   - tag: The tag to associate with the task.
    ///   - host: The object to host on.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     tag: String? = nil,
                     host: AnyObject,
                     onElapse: @escaping (Task) -> Void) -> Task {
        return ParasiticTask(schedule: self, queue: queue, host: host, onElapse: onElapse)
    }
    
    /// Schedules a task with this schedule.
    ///
    /// This method will receive a `host` object as a parameter,
    /// the returned task will not retain this object, on the contrary,
    /// it will observe this object, when this object is dealloced,
    /// task will not scheduled any more, something like parasitism.
    ///
    /// This feature is very useful when you want a timer live and die
    /// with a controller.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the task will be submitted.
    ///   - tag: The tag to associate with the task.
    ///   - host: The object to host on.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     tag: String? = nil,
                     host: AnyObject,
                     onElapse: @escaping () -> Void) -> Task {
        return self.do(queue: queue, host: host, onElapse: { (_) in onElapse() })
    }
}


private final class ParasiticTask: Task {
    
    weak var parasitifer: AnyObject?
    
    init(schedule: Schedule, queue: DispatchQueue?, host: AnyObject, onElapse: @escaping (Task) -> Void) {
        super.init(schedule: schedule, queue: queue) { (task) in
            guard (task as? ParasiticTask)?.parasitifer != nil else {
                task.cancel()
                return
            }
            onElapse(task)
        }
        self.parasitifer = host
    }
}
