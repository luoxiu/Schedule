//
//  RunLoopTask.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/9/22.
//

import Foundation

extension Schedule {

    /// Schedules a task with this schedule.
    ///
    /// This method will receive a `host` object as a parameter,
    /// the returned task will not retain this object, instead,
    /// it will observe this object, when this object is dealloced,
    /// the task will not be scheduled any more, something like parasitism.
    ///
    /// This feature is very useful when you want a scheduled task live and die
    /// with a controller.
    ///
    /// - Parameters:
    ///   - queue: The queue to which the task will be dispatched.
    ///   - tag: The tag to be associated to the task.
    ///   - host: The object to be hosted on.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(mode: RunLoop.Mode = .default,
                     tag: String? = nil,
                     onElapse: @escaping (Task) -> Void) -> Task {
        return RunLoopTask(schedule: self, mode: mode, tag: tag, onElapse: onElapse)
    }

    /// Schedules a task with this schedule.
    ///
    /// This method will receive a `host` object as a parameter,
    /// the returned task will not retain this object, instead,
    /// it will observe this object, when this object is dealloced,
    /// the task will not scheduled any more, something like parasitism.
    ///
    /// This feature is very useful when you want a scheduled task live and die
    /// with a controller.
    ///
    /// - Parameters:
    ///   - queue: The queue to which the task will be dispatched.
    ///   - tag: The tag to be associated to the task.
    ///   - host: The object to be hosted on.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(mode: RunLoop.Mode = .default,
                     tag: String? = nil,
                     onElapse: @escaping () -> Void) -> Task {
        return self.do(mode: mode, tag: tag) { (_) in
            onElapse()
        }
    }
}

private final class RunLoopTask: Task {

    var timer: Timer!

    init(schedule: Schedule, mode: RunLoop.Mode, tag: String?, onElapse: @escaping (Task) -> Void) {

        var this: Task?

        let distant = Date.distantFuture.timeIntervalSinceReferenceDate
        timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, distant, distant, 0, 0) { _ in
            guard let task = this else { return }
            onElapse(task)
        }

        RunLoop.current.add(timer, forMode: mode)

        super.init(schedule: schedule, queue: nil, tag: tag) { (task) in
            guard let task = task as? RunLoopTask else { return }
            task.timer.fireDate = Date()
        }

        this = self
    }

    deinit {
        timer.invalidate()
    }
}
