import Foundation

extension Plan {

    /// Schedules a task with this plan.
    ///
    /// When time is up, the task will be executed on current thread. It behaves
    /// like a `Timer`, so you need to make sure that the current thread has a
    /// available runloop.
    ///
    /// Since this method relies on run loop, it is remove recommended to use
    /// `do(queue: _, onElapse: _)`.
    ///
    /// - Parameters:
    ///   - mode: The mode to which the block should be added.
    ///   - block: A block to be executed when time is up.
    /// - Returns: The task just created.
    public func `do`(
        mode: RunLoop.Mode = .common,
        block: @escaping (Task) -> Void
    ) -> Task {
        return RunLoopTask(plan: self, mode: mode, block: block)
    }

    /// Schedules a task with this plan.
    ///
    /// When time is up, the task will be executed on current thread. It behaves
    /// like a `Timer`, so you need to make sure that the current thread has a
    /// available runloop.
    ///
    /// Since this method relies on run loop, it is remove recommended to use
    /// `do(queue: _, onElapse: _)`.
    ///
    /// - Parameters:
    ///   - mode: The mode to which the block should be added.
    ///   - block: A block to be executed when time is up.
    /// - Returns: The task just created.
    public func `do`(
        mode: RunLoop.Mode = .common,
        block: @escaping () -> Void
    ) -> Task {
        return self.do(mode: mode) { _ in
            block()
        }
    }
}

private final class RunLoopTask: Task {

    var timer: Timer!

    init(
        plan: Plan,
        mode: RunLoop.Mode,
        block: @escaping (Task) -> Void
    ) {
        super.init(plan: plan, queue: nil) { (task) in
            guard let task = task as? RunLoopTask, let timer = task.timer else { return }
            timer.fireDate = Date()
        }

        timer = Timer(
            fire: Date.distantFuture,
            interval: .greatestFiniteMagnitude,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            block(self)
        }

        RunLoop.current.add(timer, forMode: mode)
    }

    deinit {
        timer.invalidate()
    }
}
