import Foundation

/// `Plan` represents a plan that gives time at which a task should be
/// executed.
///
/// `Plan` is `Interval` based.
public struct Plan {

    private var iSeq: AnySequence<Interval>

    private init<S>(_ sequence: S) where S: Sequence, S.Element == Interval {
        iSeq = AnySequence(sequence)
    }

    func makeIterator() -> AnyIterator<Interval> {
        return iSeq.makeIterator()
    }

    /// Schedules a task with this plan.
    ///
    /// - Parameters:
    ///   - queue: The queue to which the task will be dispatched.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    public func `do`(queue: DispatchQueue,
                     onElapse: @escaping (Task) -> Void) -> Task {
        return Task(plan: self, queue: queue, onElapse: onElapse)
    }

    /// Schedules a task with this plan.
    ///
    /// - Parameters:
    ///   - queue: The queue to which the task will be dispatched.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    public func `do`(queue: DispatchQueue,
                     onElapse: @escaping () -> Void) -> Task {
        return self.do(queue: queue, onElapse: { (_) in onElapse() })
    }
}

extension Plan {

    /// Creates a plan from a `makeUnderlyingIterator()` method.
    ///
    /// The task will be executed after each interval produced by the iterator
    /// that `makeUnderlyingIterator` returns.
    ///
    /// For example:
    ///
    ///     let plan = Plan.make {
    ///         var i = 0
    ///         return AnyIterator {
    ///             i += 1
    ///             return i
    ///         }
    ///     }
    ///     plan.do {
    ///         print(Date())
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
    /// The task will be executed after each interval in the array.
    /// - Note: Returns `Plan.never` if given no parameters.
    public static func of(_ intervals: Interval...) -> Plan {
        return Plan.of(intervals)
    }

    /// Creates a plan from a list of intervals.
    /// The task will be executed after each interval in the array.
    /// - Note: Returns `Plan.never` if given an empty array.
    public static func of<S>(_ intervals: S) -> Plan where S: Sequence, S.Element == Interval {
        return Plan(intervals)
    }
}

extension Plan {

    /// Creates a plan from a `makeUnderlyingIterator()` method.
    ///
    /// The task will be executed at each date
    /// produced by the iterator that `makeUnderlyingIterator` returns.
    ///
    /// For example:
    ///
    ///     let plan = Plan.make {
    ///         return AnyIterator {
    ///             return Date().addingTimeInterval(3)
    ///         }
    ///     }
    ///     print("now:", Date())
    ///     plan.do {
    ///         print("task", Date())
    ///     }
    ///
    ///     > "now: 2001-01-01 00:00:00"
    ///     > "task: 2001-01-01 00:00:03"
    ///     ...
    ///
    /// You are not supposed to return `Date()` in making interator.
    /// If you want to execute a task immediately,
    /// use `Plan.now` then `concat` another plan instead.
    public static func make<I>(
        _ makeUnderlyingIterator: @escaping () -> I
    ) -> Plan where I: IteratorProtocol, I.Element == Date {
        return Plan.make { () -> AnyIterator<Interval> in
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

    /// Creates a plan from a list of dates.
    /// The task will be executed at each date in the array.
    public static func of(_ dates: Date...) -> Plan {
        return Plan.of(dates)
    }

    /// Creates a plan from a list of dates.
    /// The task will be executed at each date in the array.
    /// - Note: Returns `Plan.never` if given no parameters.
    public static func of<S>(_ sequence: S) -> Plan where S: Sequence, S.Element == Date {
        return Plan.make(sequence.makeIterator)
    }

    /// A dates sequence corresponding to this plan.
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

extension Plan {

    /// A plan with a distant past date.
    public static var distantPast: Plan {
        return Plan.of(Date.distantPast)
    }

    /// A plan with a distant future date.
    public static var distantFuture: Plan {
        return Plan.of(Date.distantFuture)
    }

    /// A plan that is never going to happen.
    public static var never: Plan {
        return Plan.make {
            AnyIterator<Date> { nil }
        }
    }
}

extension Plan {

    /// Returns a new plan by concatenating a plan to this plan.
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

    /// Returns a new plan by merging a plan to this plan.
    ///
    /// For example:
    ///
    ///     let s0 = Plan.of(1.second, 3.seconds, 5.seconds)
    ///     let s1 = Plan.of(2.seconds, 4.seconds, 6.seconds)
    ///     let s2 = s0.concat(s1)
    ///     > s2
    ///     > 1.second, 1.seconds, 2.seconds, 2.seconds, 3.seconds, 3.seconds
    public func merge(_ plan: Plan) -> Plan {
        return Plan.make { () -> AnyIterator<Date> in
            let i0 = self.dates.makeIterator()
            let i1 = plan.dates.makeIterator()
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

    /// Returns a new plan by only taking the first specific number of this plan.
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

    /// Returns a new plan by only taking the part before the date.
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
}

extension Plan {

    /// Creates a plan that executes the task immediately.
    public static var now: Plan {
        return Plan.of(0.nanosecond)
    }

    /// Creates a plan that executes the task after delay.
    public static func after(_ delay: Interval) -> Plan {
        return Plan.of(delay)
    }

    /// Creates a plan that executes the task every interval.
    public static func every(_ interval: Interval) -> Plan {
        return Plan.make {
            AnyIterator { interval }
        }
    }

    /// Creates a plan that executes the task after delay then repeat
    /// every interval.
    public static func after(_ delay: Interval, repeating interval: Interval) -> Plan {
        return Plan.after(delay).concat(Plan.every(interval))
    }

    /// Creates a plan that executes the task at the specific date.
    public static func at(_ date: Date) -> Plan {
        return Plan.of(date)
    }

    /// Creates a plan that executes the task every period.
    public static func every(_ period: Period) -> Plan {
        return Plan.make { () -> AnyIterator<Interval> in
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

    /// Creates a plan that executes the task every period.
    ///
    /// See Period's constructor
    public static func every(_ period: String) -> Plan {
        guard let p = Period(period) else {
            return Plan.never
        }
        return Plan.every(p)
    }
}

extension Plan {

    /// `DateMiddleware` represents a middleware that wraps a plan
    /// which was only specified date without time.
    ///
    /// You should call `at` method to get the plan with time specified.
    public struct DateMiddleware {

        fileprivate let plan: Plan

        /// Returns a plan at the specific time.
        public func at(_ time: Time) -> Plan {
            guard !self.plan.isNever() else { return .never }

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

        /// Returns a plan at the specific time.
        ///
        /// See Time's constructor
        public func at(_ time: String) -> Plan {
            guard
                !self.plan.isNever(),
                let time = Time(time)
            else {
                return .never
            }

            return at(time)
        }

        /// Returns a plan at the specific time.
        ///
        ///     .at(1)              => 01
        ///     .at(1, 2)           => 01:02
        ///     .at(1, 2, 3)        => 01:02:03
        ///     .at(1, 2, 3, 456)   => 01:02:03.456
        ///
        /// - Note: Returns `Plan.never` if given no parameters.
        public func at(_ time: Int...) -> Plan {
            return self.at(time)
        }

        /// Returns a plan at the specific time.
        ///
        ///     .at([1])              => 01
        ///     .at([1, 2])           => 01:02
        ///     .at([1, 2, 3])        => 01:02:03
        ///     .at([1, 2, 3, 456])   => 01:02:03.456
        ///
        /// - Note: Returns `Plan.never` if given an empty array.
        public func at(_ time: [Int]) -> Plan {
            guard !time.isEmpty, !self.plan.isNever() else { return .never }

            let hour = time[0]
            let minute = time.count > 1 ? time[1] : 0
            let second = time.count > 2 ? time[2] : 0
            let nanosecond = time.count > 3 ? time[3]: 0

            guard let time = Time(hour: hour, minute: minute, second: second, nanosecond: nanosecond) else {
                return Plan.never
            }
            return at(time)
        }
    }

    /// Creates a plan that executes the task every specific weekday.
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
                    let components = weekday.toDateComponents()
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                }
                return date
            }
        }
        return DateMiddleware(plan: plan)
    }

    /// Creates a plan that executes the task every specific weekdays.
    /// - Note: Returns initialized with `Plan.never` if given no parameters.
    public static func every(_ weekdays: Weekday...) -> DateMiddleware {
        return Plan.every(weekdays)
    }

    /// Creates a plan that executes the task every specific weekdays.
    /// - Note: Returns initialized with `Plan.never` if given an empty array.
    public static func every(_ weekdays: [Weekday]) -> DateMiddleware {
        guard !weekdays.isEmpty else { return .init(plan: .never) }

        var plan = every(weekdays[0]).plan
        if weekdays.count > 1 {
            for i in 1..<weekdays.count {
                plan = plan.merge(Plan.every(weekdays[i]).plan)
            }
        }
        return DateMiddleware(plan: plan)
    }

    /// Creates a plan that executes the task every specific day in the month.
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
                    let components = monthday.toDateComponents()
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                }
                return date
            }
        }
        return DateMiddleware(plan: plan)
    }

    /// Creates a plan that executes the task every specific days in the months.
    /// - Note: Returns initialized with `Plan.never` if given no parameters.
    public static func every(_ mondays: Monthday...) -> DateMiddleware {
        return Plan.every(mondays)
    }

    /// Creates a plan that executes the task every specific days in the months.
    /// - Note: Returns initialized with `Plan.never` if given an empty array.
    public static func every(_ mondays: [Monthday]) -> DateMiddleware {
        guard !mondays.isEmpty else { return .init(plan: .never) }

        var plan = every(mondays[0]).plan
        if mondays.count > 1 {
            for i in 1..<mondays.count {
                plan = plan.merge(Plan.every(mondays[i]).plan)
            }
        }
        return DateMiddleware(plan: plan)
    }
}

extension Plan {

    /// Returns a Boolean value indicating whether this plan is empty.
    public func isNever() -> Bool {
        return iSeq.makeIterator().next() == nil
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
    public func offset(by intervalOffset: @escaping () -> Interval?) -> Plan {
        return Plan.make { () -> AnyIterator<Interval> in
            let it = self.makeIterator()
            return AnyIterator {
                if let next = it.next() {
                    return next + (intervalOffset() ?? 0.second)
                }
                return nil
            }
        }
    }

    /// Creates a new plan that is offset by the specified interval.
    ///
    /// If the specified interval offset is `nil`, then no offset is
    /// added to the plan (ie. it stays the same).
    public func offset(by intervalOffset: Interval?) -> Plan {
        return self.offset(by: { intervalOffset })
    }
}
