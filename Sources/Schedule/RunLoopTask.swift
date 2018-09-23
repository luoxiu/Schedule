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
    /// - Parameters:
    ///   - mode: The mode in which to add the schedule.
    ///   - host: The object to be hosted on.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(mode: RunLoop.Mode = .default,
                     host: AnyObject? = nil,
                     onElapse: @escaping (Task) -> Void) -> Task {
        return RunLoopTask(schedule: self, mode: mode, host: host, onElapse: onElapse)
    }

    /// Schedules a task with this schedule.
    ///
    /// - Parameters:
    ///   - mode: The mode in which to add the schedule.
    ///   - host: The object to be hosted on.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(mode: RunLoop.Mode = .default,
                     host: AnyObject? = nil,
                     onElapse: @escaping () -> Void) -> Task {
        return self.do(mode: mode, host: host) { (_) in
            onElapse()
        }
    }
}

private final class RunLoopTask: Task {

    var timer: Timer!

    init(schedule: Schedule, mode: RunLoop.Mode, host: AnyObject?, onElapse: @escaping (Task) -> Void) {

        var this: Task?

        let distant = Date.distantFuture.timeIntervalSinceReferenceDate
        timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, distant, distant, 0, 0) { _ in
            guard let task = this else { return }
            onElapse(task)
        }

        RunLoop.current.add(timer, forMode: mode)

        super.init(schedule: schedule, queue: nil, host: host) { (task) in
            guard let task = task as? RunLoopTask else { return }
            task.timer.fireDate = Date()
        }

        this = self
    }

    deinit {
        timer.invalidate()
    }
}
