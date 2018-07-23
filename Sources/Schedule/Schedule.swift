//
//  Schedule.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

/// `Schedule` represents a plan that gives the times
/// at which a task should be invoked.
///
/// `Schedule` is interval based.
/// When a new task is created in the `do` method, it will ask for the first
/// interval in this schedule, then set up a timer to invoke itself
/// after the interval.
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
    ///   - queue: The dispatch queue to which the task will be submitted.
    ///   - tag: The tag to attach to the task.
    ///   - onElapse: The task to invoke when time is out.
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
    ///   - queue: The dispatch queue to which the task will be submitted.
    ///   - tag: The tag to attach to the queue
    ///   - onElapse: The task to invoke when time is out.
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
    /// The task will be invoke after each interval
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
    /// The task will be invoke after each interval in the sequence.
    public static func from<S>(_ sequence: S) -> Schedule where S: Sequence, S.Element == Interval {
        return Schedule(sequence)
    }
    
    /// Creates a schedule from an interval array.
    /// The task will be invoke after each interval in the array.
    public static func of(_ intervals: Interval...) -> Schedule {
        return Schedule(intervals)
    }
}

extension Schedule {
    
    /// Creates a schedule from a `makeUnderlyingIterator()` method.
    ///
    /// The task will be invoke at each date
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
    ///     > "task: 2001-01-01 00:00:03
    ///     ...
    ///
    /// You should not return `Date()` in making interator
    /// if you want to invoke a task immediately,
    /// use `Schedule.now` then `concat` another schedule instead.
    public static func make<I>(_ makeUnderlyingIterator: @escaping () -> I) -> Schedule where I: IteratorProtocol, I.Element == Date {
        return Schedule.make { () -> AnyIterator<Interval> in
            var iterator = makeUnderlyingIterator()
            var previous: Date!
            return AnyIterator {
                previous = previous ?? Date()
                guard let next = iterator.next() else { return nil }
                defer { previous = next }
                return next.interval(since: previous)
            }
        }
    }
    
    /// Creates a schedule from a date sequence.
    /// The task will be invoke at each date in the sequence.
    public static func from<S>(_ sequence: S) -> Schedule where S: Sequence, S.Element == Date {
        return Schedule.make(sequence.makeIterator)
    }
    
    /// Creates a schedule from a date array.
    /// The task will be invoke at each date in the array.
    public static func of(_ dates: Date...) -> Schedule {
        return Schedule.from(dates)
    }
    
    /// A dates sequence corresponding to this schedule.
    public var dates: AnySequence<Date> {
        return AnySequence { () -> AnyIterator<Date> in
            let iterator = self.makeIterator()
            var previous: Date!
            return AnyIterator {
                previous = previous ?? Date()
                guard let interval = iterator.next() else { return nil }
                previous = previous + interval
                return previous
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
    
    /// A schedule with no date.
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
    ///     > 1.second, 1.second, 1.second, 1.second, 1.second, 1.second
    public func merge(_ schedule: Schedule) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let i0 = self.dates.makeIterator()
            let i1 = schedule.dates.makeIterator()
            var buffer0: Date!
            var buffer1: Date!
            let iterator = AnyIterator<Date> {
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
            return Schedule.make({ iterator }).makeIterator()
        }
    }
    
    /// Returns a new schedule by cutting out a specific number of this schedule.
    ///
    /// For example:
    ///
    ///     let s0 = Schedule.every(1.second)
    ///     let s1 = s0.count(3)
    ///     > s1
    ///     1.second, 1.second, 1.second
    public func count(_ count: Int) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let iterator = self.makeIterator()
            var tick = 0
            return AnyIterator {
                guard tick < count, let interval = iterator.next() else { return nil }
                tick += 1
                return interval
            }
        }
    }
    
    /// Returns a new schedule by cutting out the part which is before the date.
    public func until(_ date: Date) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let iterator = self.makeIterator()
            var previous: Date!
            return AnyIterator {
                previous = previous ?? Date()
                guard let interval = iterator.next(),
                      previous.addingTimeInterval(interval.seconds) < date else {
                        return nil
                }
                previous.addTimeInterval(interval.seconds)
                return interval
            }
        }
    }
    
    /// Creates a schedule that invokes the task immediately.
    public static var now: Schedule {
        return Schedule.of(0.nanosecond)
    }
    
    /// Creates a schedule that invokes the task after the delay.
    public static func after(_ delay: Interval) -> Schedule {
        return Schedule.of(delay)
    }
    
    /// Creates a schedule that invokes the task every interval.
    public static func every(_ interval: Interval) -> Schedule {
        return Schedule.make {
            AnyIterator { interval }
        }
    }
    
    /// Creates a schedule that invokes the task at the specific date.
    public static func at(_ date: Date) -> Schedule {
        return Schedule.of(date)
    }
    
    /// Creates a schedule that invokes the task after the delay then repeat
    /// every interval.
    public static func after(_ delay: Interval, repeating interval: Interval) -> Schedule {
        return Schedule.after(delay).concat(Schedule.every(interval))
    }
    
    /// Creates a schedule that invokes the task every period.
    public static func every(_ period: Period) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.autoupdatingCurrent
            var previous: Date!
            return AnyIterator {
                previous = previous ?? Date()
                guard let next = calendar.date(byAdding: period.asDateComponents(),
                                               to: previous) else {
                    return nil
                }
                defer { previous = next }
                return next.interval(since: previous)
            }
        }
    }
}

extension Schedule {
    
    /// `EveryDateMiddleware` represents a middleware that wraps a schedule
    /// which only specify date without time.
    ///
    /// You should call `at` method to get the time specified schedule.
    public struct EveryDateMiddleware {
        
        fileprivate let schedule: Schedule
        
        /// Returns a schedule at the specific timing.
        public func at(_ timing: Time) -> Schedule {

            return Schedule.make { () -> AnyIterator<Interval> in
                let iterator = self.schedule.dates.makeIterator()
                let calendar = Calendar.autoupdatingCurrent
                var previous: Date!
                return AnyIterator {
                    previous = previous ?? Date()
                    guard let date = iterator.next(),
                        let next = calendar.nextDate(after: date,
                                                     matching: timing.asDateComponents(),
                                                     matchingPolicy: .strict) else {
                        return nil
                    }
                    defer { previous = next }
                    return next.interval(since: previous)
                }
            }
        }
        
        /// Returns a schedule at the specific timing.
        ///
        /// For example:
        ///
        ///     let s = Schedule.every(.monday).at("11:11")
        ///
        /// Available format:
        ///
        ///     Time("11") == Time(hour: 11)
        ///     Time("11:12") == Time(hour: 11, minute: 12)
        ///     Time("11:12:13") == Time(hour: 11, minute: 12, second: 13)
        ///     Time("11:12:13.123") == Time(hour: 11, minute: 12, second: 13, nanosecond: 123)
        public func at(_ timing: String) -> Schedule {
            guard let time = Time(timing: timing) else {
                return Schedule.never
            }
            return at(time)
        }
        
        /// Returns a schedule at the specific timing.
        public func at(_ timing: Int...) -> Schedule {
            let hour = timing[0]
            let minute = timing.count > 1 ? timing[1] : 0
            let second = timing.count > 2 ? timing[2] : 0
            let nanosecond = timing.count > 3 ? timing[3]: 0
            
            guard let time = Time(hour: hour, minute: minute, second: second, nanosecond: nanosecond) else {
                return Schedule.never
            }
            return at(time)
        }
    }
    
    /// Creates a schedule that invokes the task every specific weekday.
    public static func every(_ weekday: Weekday) -> EveryDateMiddleware {
        let schedule = Schedule.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.autoupdatingCurrent
            let components = DateComponents(weekday: weekday.rawValue)
            var date: Date!
            let iterator = AnyIterator<Date> {
                if date == nil {
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                } else {
                    date = calendar.date(byAdding: .day, value: 7, to: date)
                }
                return date
            }
            return Schedule.make({ iterator }).makeIterator()
        }
        return EveryDateMiddleware(schedule: schedule)
    }
    
    /// Creates a schedule that invokes the task every specific weekdays.
    public static func every(_ weekdays: Weekday...) -> EveryDateMiddleware {
        var schedule = every(weekdays[0]).schedule
        if weekdays.count > 1 {
            for i in 1..<weekdays.count {
                schedule = schedule.merge(Schedule.every(weekdays[i]).schedule)
            }
        }
        return EveryDateMiddleware(schedule: schedule)
    }
    
    /// Creates a schedule that invokes the task every specific day in the month.
    public static func every(_ monthDay: MonthDay) -> EveryDateMiddleware {
        let schedule = Schedule.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.autoupdatingCurrent
            let components = monthDay.asDateComponents()
            
            var date: Date!
            let iterator = AnyIterator<Date> {
                if date == nil {
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                } else {
                    date = calendar.date(byAdding: .year, value: 1, to: date)
                }
                return date
            }
            return Schedule.make({ iterator }).makeIterator()
        }
        return EveryDateMiddleware(schedule: schedule)
    }
    
    /// Creates a schedule that invokes the task every specific days in the months.
    public static func every(_ mondays: MonthDay...) -> EveryDateMiddleware {
        var schedule = every(mondays[0]).schedule
        if mondays.count > 1 {
            for i in 1..<mondays.count {
                schedule = schedule.merge(Schedule.every(mondays[i]).schedule)
            }
        }
        return EveryDateMiddleware(schedule: schedule)
    }
}
