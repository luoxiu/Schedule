//
//  Schedule.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

/// `Schedule` represents a plan that gives the times
/// at which a task should be executed.
///
/// `Schedule` is `Interval` based.
public struct Schedule {

    private var sequence: AnySequence<Interval>
    private init<S>(_ sequence: S) where S: Sequence, S.Element == Interval {
        self.sequence = AnySequence(sequence)
    }

    func makeIterator() -> AnyIterator<Interval> {
        return sequence.makeIterator()
    }

    /// Schedules a task with this schedule.
    ///
    /// - Parameters:
    ///   - queue: The queue to which the task will be dispatched.
    ///   - tag: The tag to be associated to the task.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     tag: String? = nil,
                     onElapse: @escaping (Task) -> Void) -> Task {
        return Task(schedule: self, queue: queue, tag: tag, onElapse: onElapse)
    }

    /// Schedules a task with this schedule.
    ///
    /// - Parameters:
    ///   - queue: The queue to which the task will be dispatched.
    ///   - tag: The tag to be associated to the task.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     tag: String? = nil,
                     onElapse: @escaping () -> Void) -> Task {
        return self.do(queue: queue, tag: tag, onElapse: { (_) in onElapse() })
    }
}

extension Schedule {

    /// Creates a schedule from a `makeUnderlyingIterator()` method.
    ///
    /// The task will be executed after each interval
    /// produced by the iterator that `makeUnderlyingIterator` returns.
    ///
    /// For example:
    ///
    ///     let schedule = Schedule.make {
    ///         var i = 0
    ///         return AnyIterator {
    ///             i += 1
    ///             return i
    ///         }
    ///     }
    ///     schedule.do {
    ///         print(Date())
    ///     }
    ///
    ///     > "2001-01-01 00:00:00"
    ///     > "2001-01-01 00:00:01"
    ///     > "2001-01-01 00:00:03"
    ///     > "2001-01-01 00:00:06"
    ///     ...
    public static func make<I>(_ makeUnderlyingIterator: @escaping () -> I) -> Schedule where I: IteratorProtocol, I.Element == Interval {
        return Schedule(AnySequence(makeUnderlyingIterator))
    }

    /// Creates a schedule from an interval sequence.
    /// The task will be executed after each interval in the sequence.
    public static func from<S>(_ sequence: S) -> Schedule where S: Sequence, S.Element == Interval {
        return Schedule(sequence)
    }

    /// Creates a schedule from an interval array.
    /// The task will be executed after each interval in the array.
    public static func of(_ intervals: Interval...) -> Schedule {
        return Schedule(intervals)
    }
}

extension Schedule {

    /// Creates a schedule from a `makeUnderlyingIterator()` method.
    ///
    /// The task will be executed at each date
    /// produced by the iterator that `makeUnderlyingIterator` returns.
    ///
    /// For example:
    ///
    ///     let schedule = Schedule.make {
    ///         return AnyIterator {
    ///             return Date().addingTimeInterval(3)
    ///         }
    ///     }
    ///     print("now:", Date())
    ///     schedule.do {
    ///         print("task", Date())
    ///     }
    ///
    ///     > "now: 2001-01-01 00:00:00"
    ///     > "task: 2001-01-01 00:00:03"
    ///     ...
    ///
    /// You are not supposed to return `Date()` in making interator.
    /// If you want to execute a task immediately,
    /// use `Schedule.now` then `concat` another schedule instead.
    public static func make<I>(_ makeUnderlyingIterator: @escaping () -> I) -> Schedule where I: IteratorProtocol, I.Element == Date {
        return Schedule.make { () -> AnyIterator<Interval> in
            var iterator = makeUnderlyingIterator()
            var last: Date!
            return AnyIterator {
                last = last ?? Date()
                guard let next = iterator.next() else { return nil }
                defer { last = next }
                return next.interval(since: last)
            }
        }
    }

    /// Creates a schedule from a date sequence.
    /// The task will be executed at each date in the sequence.
    public static func from<S>(_ sequence: S) -> Schedule where S: Sequence, S.Element == Date {
        return Schedule.make(sequence.makeIterator)
    }

    /// Creates a schedule from a date array.
    /// The task will be executed at each date in the array.
    public static func of(_ dates: Date...) -> Schedule {
        return Schedule.from(dates)
    }

    /// A dates sequence corresponding to this schedule.
    public var dates: AnySequence<Date> {
        return AnySequence { () -> AnyIterator<Date> in
            let iterator = self.makeIterator()
            var last: Date!
            return AnyIterator {
                last = last ?? Date()
                guard let interval = iterator.next() else { return nil }
                // swiftlint:disable shorthand_operator
                last = last + interval
                return last
            }
        }
    }
}

extension Schedule {

    /// A schedule with a distant past date.
    public static var distantPast: Schedule {
        return Schedule.of(Date.distantPast)
    }

    /// A schedule with a distant future date.
    public static var distantFuture: Schedule {
        return Schedule.of(Date.distantFuture)
    }

    /// A schedule that is never going to happen.
    public static var never: Schedule {
        return Schedule.make {
            AnyIterator<Date> { nil }
        }
    }
}

extension Schedule {

    /// Returns a new schedule by concatenating a schedule to this schedule.
    ///
    /// For example:
    ///
    ///     let s0 = Schedule.of(1.second, 2.seconds, 3.seconds)
    ///     let s1 = Schedule.of(4.seconds, 4.seconds, 4.seconds)
    ///     let s2 = s0.concat(s1)
    ///
    ///     > s2
    ///     > 1.second, 2.seconds, 3.seconds, 4.seconds, 4.seconds, 4.seconds
    public func concat(_ schedule: Schedule) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let i0 = self.makeIterator()
            let i1 = schedule.makeIterator()
            return AnyIterator {
                if let interval = i0.next() { return interval }
                return i1.next()
            }
        }
    }

    /// Returns a new schedule by merging a schedule to this schedule.
    ///
    /// For example:
    ///
    ///     let s0 = Schedule.of(1.second, 3.seconds, 5.seconds)
    ///     let s1 = Schedule.of(2.seconds, 4.seconds, 6.seconds)
    ///     let s2 = s0.concat(s1)
    ///     > s2
    ///     > 1.second, 1.seconds, 2.seconds, 2.seconds, 3.seconds, 3.seconds
    public func merge(_ schedule: Schedule) -> Schedule {
        return Schedule.make { () -> AnyIterator<Date> in
            let i0 = self.dates.makeIterator()
            let i1 = schedule.dates.makeIterator()
            var buffer0: Date!
            var buffer1: Date!
            return AnyIterator<Date> {
                if buffer0 == nil { buffer0 = i0.next() }
                if buffer1 == nil { buffer1 = i1.next() }

                var d: Date!
                if let d0 = buffer0, let d1 = buffer1 {
                    d = Swift.min(d0, d1)
                } else {
                    d = buffer0 ?? buffer1
                }

                if d == buffer0 { buffer0 = nil }
                if d == buffer1 { buffer1 = nil }
                return d
            }
        }
    }

    /// Returns a new schedule by only taking the first specific number of this schedule.
    ///
    /// For example:
    ///
    ///     let s0 = Schedule.every(1.second)
    ///     let s1 = s0.first(3)
    ///     > s1
    ///     1.second, 1.second, 1.second
    public func first(_ count: Int) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let iterator = self.makeIterator()
            var num = 0
            return AnyIterator {
                guard num < count, let interval = iterator.next() else { return nil }
                num += 1
                return interval
            }
        }
    }

    /// Returns a new schedule by only taking the part before the date.
    public func until(_ date: Date) -> Schedule {
        return Schedule.make { () -> AnyIterator<Date> in
            let iterator = self.dates.makeIterator()
            return AnyIterator {
                guard let next = iterator.next(), next < date else {
                        return nil
                }
                return next
            }
        }
    }
}

extension Schedule {

    /// Creates a schedule that executes the task immediately.
    public static var now: Schedule {
        return Schedule.of(0.nanosecond)
    }

    /// Creates a schedule that executes the task after delay.
    public static func after(_ delay: Interval) -> Schedule {
        return Schedule.of(delay)
    }

    /// Creates a schedule that executes the task every interval.
    public static func every(_ interval: Interval) -> Schedule {
        return Schedule.make {
            AnyIterator { interval }
        }
    }

    /// Creates a schedule that executes the task after delay then repeat
    /// every interval.
    public static func after(_ delay: Interval, repeating interval: Interval) -> Schedule {
        return Schedule.after(delay).concat(Schedule.every(interval))
    }

    /// Creates a schedule that executes the task at the specific date.
    public static func at(_ date: Date) -> Schedule {
        return Schedule.of(date)
    }

    /// Creates a schedule that executes the task every period.
    public static func every(_ period: Period) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.gregorian
            var last: Date!
            return AnyIterator {
                last = last ?? Date()
                guard let next = calendar.date(byAdding: period.toDateComponents(),
                                               to: last) else {
                    return nil
                }
                defer { last = next }
                return next.interval(since: last)
            }
        }
    }

    /// Creates a schedule that executes the task every period.
    ///
    /// See Period's constructor
    public static func every(_ period: String) -> Schedule {
        guard let p = Period(period) else {
            return Schedule.never
        }
        return Schedule.every(p)
    }
}

extension Schedule {

    /// `DateMiddleware` represents a middleware that wraps a schedule
    /// which was only specified date without time.
    ///
    /// You should call `at` method to get the schedule with time specified.
    public struct DateMiddleware {

        fileprivate let schedule: Schedule

        /// Returns a schedule at the specific time.
        public func at(_ time: Time) -> Schedule {
            var interval = time.intervalSinceZeroClock
            return Schedule.make { () -> AnyIterator<Interval> in
                let it = self.schedule.makeIterator()
                return AnyIterator {
                    if let next = it.next() {
                        defer { interval = 0.nanoseconds }
                        return next + interval
                    }
                    return nil
                }
            }
        }

        /// Returns a schedule at the specific time.
        ///
        /// See Time's constructor
        public func at(_ time: String) -> Schedule {
            guard let time = Time(time) else {
                return Schedule.never
            }
            return at(time)
        }

        /// Returns a schedule at the specific time.
        ///
        ///     .at(1)              => 01
        ///     .at(1, 2)           => 01:02
        ///     .at(1, 2, 3)        => 01:02:03
        ///     .at(1, 2, 3, 456)   => 01:02:03.456
        public func at(_ time: Int...) -> Schedule {
            let hour = time[0]
            let minute = time.count > 1 ? time[1] : 0
            let second = time.count > 2 ? time[2] : 0
            let nanosecond = time.count > 3 ? time[3]: 0

            guard let time = Time(hour: hour, minute: minute, second: second, nanosecond: nanosecond) else {
                return Schedule.never
            }
            return at(time)
        }
    }

    /// Creates a schedule that executes the task every specific weekday.
    public static func every(_ weekday: Weekday) -> DateMiddleware {
        let schedule = Schedule.make { () -> AnyIterator<Date> in
            let calendar = Calendar.gregorian
            var date: Date!
            return AnyIterator<Date> {
                if weekday.isToday {
                    date = Date().zeroClock()
                } else if date == nil {
                    date = calendar.next(weekday, after: Date())
                } else {
                    date = calendar.date(byAdding: .day, value: 7, to: date)
                }
                return date
            }
        }
        return DateMiddleware(schedule: schedule)
    }

    /// Creates a schedule that executes the task every specific weekdays.
    public static func every(_ weekdays: Weekday...) -> DateMiddleware {
        var schedule = every(weekdays[0]).schedule
        if weekdays.count > 1 {
            for i in 1..<weekdays.count {
                schedule = schedule.merge(Schedule.every(weekdays[i]).schedule)
            }
        }
        return DateMiddleware(schedule: schedule)
    }

    /// Creates a schedule that executes the task every specific day in the month.
    public static func every(_ monthday: Monthday) -> DateMiddleware {
        let schedule = Schedule.make { () -> AnyIterator<Date> in
            let calendar = Calendar.gregorian
            var date: Date!
            return AnyIterator<Date> {
                if monthday.isToday {
                    date = Date().zeroClock()
                } else if date == nil {
                    date = calendar.next(monthday, after: Date())
                } else {
                    date = calendar.date(byAdding: .year, value: 1, to: date)
                }
                return date
            }
        }
        return DateMiddleware(schedule: schedule)
    }

    /// Creates a schedule that executes the task every specific days in the months.
    public static func every(_ mondays: Monthday...) -> DateMiddleware {
        var schedule = every(mondays[0]).schedule
        if mondays.count > 1 {
            for i in 1..<mondays.count {
                schedule = schedule.merge(Schedule.every(mondays[i]).schedule)
            }
        }
        return DateMiddleware(schedule: schedule)
    }
}
