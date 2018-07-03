//
//  Schedule.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

public struct Schedule {
    
    private var sequence: AnySequence<Interval>
    private init<S>(_ sequence: S) where S: Sequence, S.Element == Interval {
        self.sequence = AnySequence(sequence)
    }
    
    internal func makeIterator() -> AnyIterator<Interval> {
        return sequence.makeIterator()
    }
    
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     onElapse: @escaping (Job) -> Void) -> Job {
        return Job(schedule: self, queue: queue, onElapse: onElapse)
    }
    
    @discardableResult
    public func `do`(queue: DispatchQueue? = nil,
                     onElapse: @escaping () -> Void) -> Job {
        return self.do(queue: queue, onElapse: { (_) in onElapse() })
    }
    
    public static func make<I>(_ makeIterator: @escaping () -> I) -> Schedule where I: IteratorProtocol, I.Element == Interval {
        return Schedule(AnySequence(makeIterator))
    }
    
    public static func from<S>(_ sequence: S) -> Schedule where S: Sequence, S.Element == Interval {
        return Schedule(sequence)
    }
    
    public static func of(_ intervals: Interval...) -> Schedule {
        return Schedule(intervals)
    }
}

extension Schedule {
    
    public static func make<I>(_ makeIterator: @escaping () -> I) -> Schedule where I: IteratorProtocol, I.Element == Date {
        return Schedule.make { () -> AnyIterator<Interval> in
            var iterator = makeIterator()
            var previous: Date!
            return AnyIterator {
                previous = previous ?? Date()
                guard let next = iterator.next() else { return nil }
                defer { previous = next }
                return next.interval(since: previous)
            }
        }
    }
    
    public static func from<S>(_ sequence: S) -> Schedule where S: Sequence, S.Element == Date {
        return Schedule.make(sequence.makeIterator)
    }
    
    public static func of(_ dates: Date...) -> Schedule {
        return Schedule.from(dates)
    }
    
    public static func at(_ date: Date) -> Schedule {
        return Schedule.of(date)
    }
    
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
    
    public static var distantPast: Schedule {
        return Schedule.of(Date.distantPast)
    }
    
    public static var distantFuture: Schedule {
        return Schedule.of(Date.distantFuture)
    }
    
    public static var never: Schedule {
        return Schedule.make {
            AnyIterator<Interval> { nil }
        }
    }
}

extension Schedule {
    
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
    
    public func until(_ date: Date) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let iterator = self.makeIterator()
            var previous: Date!
            return AnyIterator {
                previous = previous ?? Date()
                guard let interval = iterator.next(), previous.addingTimeInterval(interval.seconds) < date else { return nil }
                previous.addTimeInterval(interval.seconds)
                return interval
            }
        }
    }
    
    public static var now: Schedule {
        return Schedule.of(0.nanosecond)
    }
    
    public static func after(_ delay: Interval) -> Schedule {
        return Schedule.of(delay)
    }
    
    public static func every(_ interval: Interval) -> Schedule {
        return Schedule.make {
            AnyIterator { interval }
        }
    }
}

extension Schedule {
    
    public static func after(_ delay: Interval, repeating interval: Interval) -> Schedule {
        return Schedule.after(delay).concat(Schedule.every(interval))
    }
    
    public static func every(_ period: Period) -> Schedule {
        return Schedule.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.autoupdatingCurrent
            var previous: Date!
            return AnyIterator {
                previous = previous ?? Date()
                guard let next = calendar.date(byAdding: period.asDateComponents(), to: previous) else { return nil }
                defer { previous = next }
                return next.interval(since: previous)
            }
        }
    }
}

extension Schedule {
    
    public struct EveryDateMiddleware {
        
        fileprivate let schedule: Schedule
        
        public func at(_ timing: Time) -> Schedule {
            return Schedule.make { () -> AnyIterator<Interval> in
                let iterator = self.schedule.dates.makeIterator()
                let calendar = Calendar.autoupdatingCurrent
                var previous: Date!
                return AnyIterator {
                    previous = previous ?? Date()
                    guard let date = iterator.next(),
                        let next = calendar.nextDate(after: date, matching: timing.asDateComponents(), matchingPolicy: .strict) else { return nil }
                    defer { previous = next }
                    return next.interval(since: previous)
                }
            }
        }
        
        public func at(_ timing: String) -> Schedule {
            guard let time = Time(timing: timing) else {
                return Schedule.never
            }
            return at(time)
        }
        
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
    
    public static func every(_ weekday: Weekday) -> EveryDateMiddleware {
        let schedule = Schedule.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.autoupdatingCurrent
            let components = DateComponents(weekday: weekday.rawValue)
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
    
    public static func every(_ weekdays: Weekday...) -> EveryDateMiddleware {
        var schedule = every(weekdays[0]).schedule
        if weekdays.count > 1 {
            for i in 1..<weekdays.count {
                schedule = schedule.merge(Schedule.every(weekdays[i]).schedule)
            }
        }
        return EveryDateMiddleware(schedule: schedule)
    }
    
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
