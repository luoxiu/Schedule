import Foundation

/// `Plan` represents a sequence of times at which a task should be
/// executed.
///
/// `Plan` is `Interval` based.
public struct Plan: Sequence {

    private var seq: AnySequence<Interval>

    private init<S>(_ sequence: S) where S: Sequence, S.Element == Interval {
        seq = AnySequence(sequence)
    }

    /// Returns an iterator over the interval of this sequence.
    public func makeIterator() -> AnyIterator<Interval> {
        return seq.makeIterator()
    }

    /// Schedules a task with this plan.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the action should be dispatched.
    ///   - action: A block to be executed when time is up.
    /// - Returns: The task just created.
    public func `do`(
        queue: DispatchQueue,
        action: @escaping (Task) -> Void
    ) -> Task {
        return Task(plan: self, queue: queue, action: action)
    }

    /// Schedules a task with this plan.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to which the action should be dispatched.
    ///   - action: A block to be executed when time is up.
    /// - Returns: The task just created.
    public func `do`(
        queue: DispatchQueue,
        action: @escaping () -> Void
    ) -> Task {
        return self.do(queue: queue, action: { (_) in action() })
    }
}

extension Plan {

    /// Creates a plan whose `makeIterator()` method forwards to makeUnderlyingIterator.
    ///
    /// The task will be executed after each interval.
    ///
    /// For example:
    ///
    ///     let plan = Plan.make {
    ///         var i = 0
    ///         return AnyIterator {
    ///             i += 1
    ///             return i    // 1, 2, 3, ...
    ///         }
    ///     }
    ///     plan.do {
    ///         logTimestamp()
    ///     }
    ///
    ///     > "2001-01-01 00:00:00"
    ///     > "2001-01-01 00:00:01"
    ///     > "2001-01-01 00:00:03"
    ///     > "2001-01-01 00:00:06"
    ///     ...
    public static func make<I>(
        _ makeUnderlyingIterator: @escaping () -> I
    ) -> Plan where I: IteratorProtocol, I.Element == Interval {
        return Plan(AnySequence(makeUnderlyingIterator))
    }

    /// Creates a plan from a list of intervals.
    ///
    /// The task will be executed after each interval in the array.
    public static func of(_ intervals: Interval...) -> Plan {
        return Plan.of(intervals)
    }

    /// Creates a plan from a list of intervals.
    ///
    /// The task will be executed after each interval in the array.
    public static func of<S>(_ intervals: S) -> Plan where S: Sequence, S.Element == Interval {
        return Plan(intervals)
    }
}

extension Plan {

    /// Creates a plan whose `makeIterator()` method forwards to makeUnderlyingIterator.
    ///
    /// The task will be executed at each date.
    ///
    /// For example:
    ///
    ///     let plan = Plan.make {
    ///         return AnyIterator {
    ///             return Date().addingTimeInterval(3)
    ///         }
    ///     }
    ///
    ///     plan.do {
    ///         logTimestamp()
    ///     }
    ///
    ///     > "2001-01-01 00:00:00"
    ///     > "2001-01-01 00:00:03"
    ///     > "2001-01-01 00:00:06"
    ///     > "2001-01-01 00:00:09"
    ///     ...
    ///
    /// You should not return `Date()` in making iterator.
    /// If you want to execute a task immediately, use `Plan.now`.
    public static func make<I>(
        _ makeUnderlyingIterator: @escaping () -> I
    ) -> Plan where I: IteratorProtocol, I.Element == Date {
        return Plan.make { () -> AnyIterator<Interval> in
            var iterator = makeUnderlyingIterator()
            var prev: Date!
            return AnyIterator {
                prev = prev ?? Date()
                guard let next = iterator.next() else { return nil }
                defer { prev = next }
                return next.interval(since: prev)
            }
        }
    }

    /// Creates a plan from a list of dates.
    ///
    /// The task will be executed at each date in the array.
    public static func of(_ dates: Date...) -> Plan {
        return Plan.of(dates)
    }

    /// Creates a plan from a list of dates.
    ///
    /// The task will be executed at each date in the array.
    public static func of<S>(_ sequence: S) -> Plan where S: Sequence, S.Element == Date {
        return Plan.make(sequence.makeIterator)
    }

    /// A dates sequence corresponding to this plan.
    public var dates: AnySequence<Date> {
        return AnySequence { () -> AnyIterator<Date> in
            let iterator = self.makeIterator()
            var prev: Date!
            return AnyIterator {
                prev = prev ?? Date()
                guard let interval = iterator.next() else { return nil }
                // swiftlint:disable shorthand_operator
                prev = prev + interval
                return prev
            }
        }
    }
}

extension Plan {

    /// A plan of a distant past date.
    public static var distantPast: Plan {
        return Plan.of(Date.distantPast)
    }

    /// A plan of a distant future date.
    public static var distantFuture: Plan {
        return Plan.of(Date.distantFuture)
    }

    /// A plan that will never happen.
    public static var never: Plan {
        return Plan.make {
            AnyIterator<Interval> { nil }
        }
    }
}

extension Plan {

    /// Returns a new plan by concatenating the given plan to this plan.
    ///
    /// For example:
    ///
    ///     let s0 = Plan.of(1.second, 2.seconds, 3.seconds)
    ///     let s1 = Plan.of(4.seconds, 4.seconds, 4.seconds)
    ///     let s2 = s0.concat(s1)
    ///
    ///     > s2
    ///     > 1.second, 2.seconds, 3.seconds, 4.seconds, 4.seconds, 4.seconds
    public func concat(_ plan: Plan) -> Plan {
        return Plan.make { () -> AnyIterator<Interval> in
            let i0 = self.makeIterator()
            let i1 = plan.makeIterator()
            return AnyIterator {
                if let interval = i0.next() { return interval }
                return i1.next()
            }
        }
    }

    /// Returns a new plan by merging the given plan to this plan.
    ///
    /// For example:
    ///
    ///     let s0 = Plan.of(1.second, 3.seconds, 5.seconds)
    ///     let s1 = Plan.of(2.seconds, 4.seconds, 6.seconds)
    ///     let s2 = s0.merge(s1)
    ///     > s2
    ///     > 1.second, 1.seconds, 2.seconds, 2.seconds, 3.seconds, 3.seconds
    public func merge(_ plan: Plan) -> Plan {
        return Plan.make { () -> AnyIterator<Date> in
            let i0 = self.dates.makeIterator()
            let i1 = plan.dates.makeIterator()

            var buf0: Date!
            var buf1: Date!

            return AnyIterator<Date> {
                if buf0 == nil { buf0 = i0.next() }
                if buf1 == nil { buf1 = i1.next() }

                var d: Date!
                if let d0 = buf0, let d1 = buf1 {
                    d = Swift.min(d0, d1)
                } else {
                    d = buf0 ?? buf1
                }

                if d == nil { return d }

                if d == buf0 { buf0 = nil; return d }
                if d == buf1 { buf1 = nil }
                return d
            }
        }
    }

    /// Returns a new plan by taking the first specific number of intervals from this plan.
    ///
    /// For example:
    ///
    ///     let s0 = Plan.every(1.second)
    ///     let s1 = s0.first(3)
    ///     > s1
    ///     1.second, 1.second, 1.second
    public func first(_ count: Int) -> Plan {
        return Plan.make { () -> AnyIterator<Interval> in
            let iterator = self.makeIterator()
            var num = 0
            return AnyIterator {
                guard num < count, let interval = iterator.next() else { return nil }
                num += 1
                return interval
            }
        }
    }

    /// Returns a new plan by taking the part before the given date.
    public func until(_ date: Date) -> Plan {
        return Plan.make { () -> AnyIterator<Date> in
            let iterator = self.dates.makeIterator()
            return AnyIterator {
                guard let next = iterator.next(), next < date else {
                    return nil
                }
                return next
            }
        }
    }

    /// Creates a plan that executes the task immediately.
    public static var now: Plan {
        return Plan.of(0.nanosecond)
    }

    /// Creates a plan that executes the task after the given interval.
    public static func after(_ delay: Interval) -> Plan {
        return Plan.of(delay)
    }

    /// Creates a plan that executes the task after the given interval then repeat the execution.
    public static func after(_ delay: Interval, repeating interval: Interval) -> Plan {
        return Plan.after(delay).concat(Plan.every(interval))
    }

    /// Creates a plan that executes the task at the given date.
    public static func at(_ date: Date) -> Plan {
        return Plan.of(date)
    }

    /// Creates a plan that executes the task every given interval.
    public static func every(_ interval: Interval) -> Plan {
        return Plan.make {
            AnyIterator { interval }
        }
    }

    /// Creates a plan that executes the task every given period.
    public static func every(_ period: Period) -> Plan {
        return Plan.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.gregorian
            var prev: Date!
            return AnyIterator {
                prev = prev ?? Date()
                guard
                    let next = calendar.date(
                        byAdding: period.asDateComponents(),
                        to: prev)
                else {
                    return nil
                }
                defer { prev = next }
                return next.interval(since: prev)
            }
        }
    }

    /// Creates a plan that executes the task every period.
    ///
    /// See Period's constructor: `init?(_ string: String)`.
    public static func every(_ period: String) -> Plan {
        guard let p = Period(period) else {
            return Plan.never
        }
        return Plan.every(p)
    }
}

extension Plan {

    /// `DateMiddleware` represents a middleware that wraps a plan
    /// which was only specified with date without time.
    ///
    /// You should call `at` method to specified time of the plan.
    public struct DateMiddleware {

        fileprivate let plan: Plan

        /// Creates a plan with time specified.
        public func at(_ time: Time) -> Plan {
            if plan.isNever() { return .never }

            var interval = time.intervalSinceStartOfDay
            return Plan.make { () -> AnyIterator<Interval> in
                let it = self.plan.makeIterator()
                return AnyIterator {
                    if let next = it.next() {
                        defer { interval = 0.nanoseconds }
                        return next + interval
                    }
                    return nil
                }
            }
        }

        /// Creates a plan with time specified.
        ///
        /// See Time's constructor: `init?(_ string: String)`.
        public func at(_ time: String) -> Plan {
            if plan.isNever() { return .never }
            guard let time = Time(time) else {
                return .never
            }
            return at(time)
        }

        /// Creates a plan with time specified.
        ///
        ///     .at(1)              => 01
        ///     .at(1, 2)           => 01:02
        ///     .at(1, 2, 3)        => 01:02:03
        ///     .at(1, 2, 3, 456)   => 01:02:03.456
        public func at(_ time: Int...) -> Plan {
            return self.at(time)
        }

        /// Creates a plan with time specified.
        ///
        ///     .at([1])              => 01
        ///     .at([1, 2])           => 01:02
        ///     .at([1, 2, 3])        => 01:02:03
        ///     .at([1, 2, 3, 456])   => 01:02:03.456
        public func at(_ time: [Int]) -> Plan {
            if plan.isNever() || time.isEmpty { return .never }

            let hour = time[0]
            let minute = time.count > 1 ? time[1] : 0
            let second = time.count > 2 ? time[2] : 0
            let nanosecond = time.count > 3 ? time[3]: 0

            guard let time = Time(
                hour: hour,
                minute: minute,
                second: second,
                nanosecond: nanosecond
            ) else {
                return Plan.never
            }
            return at(time)
        }
    }

    /// Creates a date middleware that executes the task on every specific week day.
    public static func every(_ weekday: Weekday) -> DateMiddleware {
        let plan = Plan.make { () -> AnyIterator<Date> in
            let calendar = Calendar.gregorian
            var date: Date?
            return AnyIterator<Date> {
                if let d = date {
                    date = calendar.date(byAdding: .day, value: 7, to: d)
                } else if Date().is(weekday) {
                    date = Date().startOfToday
                } else {
                    let components = weekday.asDateComponents()
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                }
                return date
            }
        }
        return DateMiddleware(plan: plan)
    }

    /// Creates a date middleware that executes the task on every specific week day.
    public static func every(_ weekdays: Weekday...) -> DateMiddleware {
        return Plan.every(weekdays)
    }

    /// Creates a date middleware that executes the task on every specific week day.
    public static func every(_ weekdays: [Weekday]) -> DateMiddleware {
        guard !weekdays.isEmpty else { return .init(plan: .never) }

        var plan = every(weekdays[0]).plan
        for weekday in weekdays.dropFirst() {
            plan = plan.merge(Plan.every(weekday).plan)
        }
        return DateMiddleware(plan: plan)
    }

    /// Creates a date middleware that executes the task on every specific month day.
    public static func every(_ monthday: Monthday) -> DateMiddleware {
        let plan = Plan.make { () -> AnyIterator<Date> in
            let calendar = Calendar.gregorian
            var date: Date?
            return AnyIterator<Date> {
                if let d = date {
                    date = calendar.date(byAdding: .year, value: 1, to: d)
                } else if Date().is(monthday) {
                    date = Date().startOfToday
                } else {
                    let components = monthday.asDateComponents()
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                }
                return date
            }
        }
        return DateMiddleware(plan: plan)
    }

    /// Creates a date middleware that executes the task on every specific month day.
    public static func every(_ mondays: Monthday...) -> DateMiddleware {
        return Plan.every(mondays)
    }

    /// Creates a date middleware that executes the task on every specific month day.
    public static func every(_ mondays: [Monthday]) -> DateMiddleware {
        guard !mondays.isEmpty else { return .init(plan: .never) }

        var plan = every(mondays[0]).plan
        for monday in mondays.dropFirst() {
            plan = plan.merge(Plan.every(monday).plan)
        }
        return DateMiddleware(plan: plan)
    }
}

extension Plan {

    /// Returns a Boolean value indicating whether this plan is empty.
    public func isNever() -> Bool {
        return seq.makeIterator().next() == nil
    }
}

extension Plan {

    /// Creates a new plan that is offset by the specified interval in the
    /// closure body.
    ///
    /// The closure is evaluated each time the next-run date is evaluated,
    /// so the interval can be calculated based on dynamic factors.
    ///
    /// If the returned interval offset is `nil`, then no offset is added
    /// to that next-run date.
    public func offset(by interval: @autoclosure @escaping () -> Interval?) -> Plan {
        return Plan.make { () -> AnyIterator<Interval> in
            let it = self.makeIterator()
            return AnyIterator {
                if let next = it.next() {
                    return next + (interval() ?? 0.second)
                }
                return nil
            }
        }
    }
}
