//
//  DateTime.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

/// `Interval` represents a duration of time.
public struct Interval {
    
    ///  The length of this interval, measured in nanoseconds.
    public let nanoseconds: Double
    
    /// Creates an interval from the given number of nanoseconds.
    public init(nanoseconds: Double) {
        self.nanoseconds = nanoseconds
    }
    
    /// A boolean value indicating whether this interval is negative.
    ///
    /// A interval can be negative.
    ///
    /// - The interval between 6:00 and 7:00 is `1.hour`,
    /// but the interval between 7:00 and 6:00 is `-1.hour`.
    /// In this case, `-1.hour` means **one hour ago**.
    ///
    /// - The interval comparing `3.hour` and `1.hour` is `2.hour`,
    /// but the interval comparing `1.hour` and `3.hour` is `-2.hour`.
    /// In this case, `-2.hour` means **two hours shorter**
    public var isNegative: Bool {
        return nanoseconds.isLess(than: 0)
    }
    
    /// The magnitude of this interval.
    ///
    /// It's the absolute value of the length of this interval,
    /// measured in nanoseconds, but disregarding its sign.
    public var magnitude: Double {
        return nanoseconds.magnitude
    }
    
    internal var ns: Int {
        if nanoseconds > Double(Int.max) { return .max }
        if nanoseconds < Double(Int.min) { return .min }
        return Int(nanoseconds)
    }
    
    /// Returns a dispatchTimeInterval created from this interval.
    ///
    /// The returned value will be clamped to the `DispatchTimeInterval`'s
    /// usable range [`.nanoseconds(.min)....nanoseconds(.max)`].
    public func asDispatchTimeInterval() -> DispatchTimeInterval {
        return .nanoseconds(ns)
    }
    
    /// Returns a boolean value indicating whether this interval is longer than the given value.
    public func isLonger(than other: Interval) -> Bool {
        return magnitude > other.magnitude
    }
    
    /// Returns a boolean value indicating whether this interval is shorter than the given value.
    public func isShorter(than other: Interval) -> Bool {
        return magnitude < other.magnitude
    }
    
    /// Returns the longest interval of the given values.
    public static func longest(_ intervals: Interval...) -> Interval {
        return intervals.sorted(by: { $0.magnitude > $1.magnitude })[0]
    }
    
    /// Returns the shortest interval of the given values.
    public static func shortest(_ intervals: Interval...) -> Interval {
        return intervals.sorted(by: { $0.magnitude < $1.magnitude })[0]
    }
 
    /// Returns a new interval by multipling the left interval by the right number.
    ///
    ///     1.hour * 2 == 2.hours
    public static func *(lhs: Interval, rhs: Double) -> Interval {
        return Interval(nanoseconds: lhs.nanoseconds * rhs)
    }
    
    /// Returns a new interval by adding the right interval to the left interval.
    ///
    ///     1.hour + 1.hour == 2.hours
    public static func +(lhs: Interval, rhs: Interval) -> Interval {
        return Interval(nanoseconds: lhs.nanoseconds + rhs.nanoseconds)
    }
    
    /// Returns a new instarval by subtracting the right interval from the left interval.
    ///
    ///     2.hours - 1.hour == 1.hour
    public static func -(lhs: Interval, rhs: Interval) -> Interval {
        return Interval(nanoseconds: lhs.nanoseconds - rhs.nanoseconds)
    }
}

extension Interval {
    
    /// Creates an interval from the given number of seconds.
    public init(seconds: Double) {
        self.nanoseconds = seconds * pow(10, 9)
    }
    
    /// The length of this interval, measured in seconds.
    public var seconds: Double {
        return nanoseconds / pow(10, 9)
    }
    
    /// The length of this interval, measured in minutes.
    public var minutes: Double {
        return seconds / 60
    }
    
    /// The length of this interval, measured in hours.
    public var hours: Double {
        return minutes / 60
    }
    
    /// The length of this interval, measured in days.
    public var days: Double {
        return hours / 24
    }
    
    /// The length of this interval, measured in weeks.
    public var weeks: Double {
        return days / 7
    }
}

extension Interval: Hashable {
    
    /// The hashValue of this interval.
    public var hashValue: Int {
        return nanoseconds.hashValue
    }
    
    /// Returns a boolean value indicating whether the interval is equal to another interval.
    public static func ==(lhs: Interval, rhs: Interval) -> Bool {
        return lhs.nanoseconds == rhs.nanoseconds
    }
}

extension Date {
    
    /// The interval between this date and now.
    ///
    /// If the date is earlier than now, the interval is negative.
    public var intervalSinceNow: Interval {
        return timeIntervalSinceNow.seconds
    }
    
    /// Returns the interval between this date and the given date.
    ///
    /// If the date is earlier than the given date, the interval is negative.
    public func interval(since date: Date) -> Interval {
        return timeIntervalSince(date).seconds
    }
    
    /// Return a new date by adding an interval to the date.
    public static func +(lhs: Date, rhs: Interval) -> Date {
        return lhs.addingTimeInterval(rhs.seconds)
    }
    
    /// Add an interval to the date.
    public static func +=(lhs: inout Date, rhs: Interval) {
        lhs = lhs + rhs
    }
}

/// `IntervalConvertible` provides a set of intuitive apis for creating interval.
public protocol IntervalConvertible {
    
    var nanoseconds: Interval { get }
}

extension Int: IntervalConvertible {
    
    public var nanoseconds: Interval {
        return Interval(nanoseconds: Double(self))
    }
}

extension Double: IntervalConvertible {
    
    public var nanoseconds: Interval {
        return Interval(nanoseconds: self)
    }
}

extension IntervalConvertible {
    
    public var nanosecond: Interval {
        return nanoseconds
    }
    
    public var microsecond: Interval {
        return microseconds
    }
    
    public var microseconds: Interval {
        return nanoseconds * pow(10, 3)
    }
    
    public var millisecond: Interval {
        return milliseconds
    }
    
    public var milliseconds: Interval {
        return nanoseconds * pow(10, 6)
    }
    
    public var second: Interval {
        return seconds
    }
    
    public var seconds: Interval {
        return nanoseconds * pow(10, 9)
    }
    
    public var minute: Interval {
        return minutes
    }
    
    public var minutes: Interval {
        return seconds * 60
    }
    
    public var hour: Interval {
        return hours
    }
    
    public var hours: Interval {
        return minutes * 60
    }
    
    public var day: Interval {
        return days
    }
    
    public var days: Interval {
        return hours * 24
    }
    
    public var week: Interval {
        return weeks
    }
    
    public var weeks: Interval {
        return days * 7
    }
}


/// `Time` represents a time without a date.
///
/// It is a specific point in a day.
public struct Time {
    
    public let hour: Int
    
    public let minute: Int
    
    public let second: Int
    
    public let nanosecond: Int
    
    /// Create a date with `hour`, `minute`, `second` and `nanosecond` fields.
    ///
    /// If parameter is illegal, then return nil.
    ///
    ///     Time(hour: 25) == nil
    ///     Time(hour: 1, minute: 61) == nil
    public init?(hour: Int, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) {
        guard hour >= 0 && hour < 24 else { return nil }
        guard minute >= 0 && minute < 60 else { return nil }
        guard second >= 0 && second < 60 else { return nil }
        guard nanosecond >= 0 && nanosecond < Int(NSEC_PER_SEC) else { return nil }
        
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }
    
    /// Create a time with a timing string
    ///
    /// For example:
    ///
    ///     Time("11") == Time(hour: 11)
    ///     Time("11:12") == Time(hour: 11, minute: 12)
    ///     Time("11:12:13") == Time(hour: 11, minute: 12, second: 13)
    ///     Time("11:12:13.123") == Time(hour: 11, minute: 12, second: 13, nanosecond: 123000000)
    ///
    /// If timing's format is illegal, then return nil.
    public init?(timing: String) {
        let args = timing.split(separator: ":")
        if args.count > 3 { return nil }
        
        var h = 0, m = 0, s = 0, ns = 0
        
        guard let _h = Int(args[0]) else { return nil }
        h = _h
        if args.count > 1 {
            guard let _m = Int(args[1]) else { return nil }
            m = _m
        }
        if args.count > 2 {
            let values = args[2].split(separator: ".")
            if values.count > 2 { return nil }
            guard let _s = Int(values[0]) else { return nil }
            s = _s
            
            if values.count > 1 {
                guard let _ns = Int(values[1]) else { return nil }
                let digits = values[1].count
                ns = Int(Double(_ns) * pow(10, Double(9 - digits)))
            }
        }
        
        self.init(hour: h, minute: m, second: s, nanosecond: ns)
    }
    
    internal func asDateComponents() -> DateComponents {
        return DateComponents(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }
}


/// `Period` represents a period of time defined in terms of fields.
///
/// It's a little different from `Interval`.
///
/// For example:
///
/// If you add a period `1.month` to the 1st January,
/// you will get the 1st February.
/// If you add the same period to the 1st February,
/// you will get the 1st March.
/// But the intervals(`31.days` in case 1, `28.days` or `29.days` in case 2)
/// in these two cases are quite different.
public struct Period {
    
    public let years: Int
    
    public let months: Int
    
    public let days: Int
    
    public let hours: Int
    
    public let minutes: Int
    
    public let seconds: Int
    
    public let nanoseconds: Int
    
    public init(years: Int = 0, months: Int = 0, days: Int = 0,
                hours: Int = 0, minutes: Int = 0, seconds: Int = 0,
                nanoseconds: Int = 0) {
        self.years = years
        self.months = months
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.nanoseconds = nanoseconds
    }
    
    /// Returns a new date by adding the right period to the left period.
    public static func +(lhs: Period, rhs: Period) -> Period {
        return Period(years: lhs.years.clampedAdding(rhs.years),
                      months: lhs.months.clampedAdding(rhs.months),
                      days: lhs.days.clampedAdding(rhs.days),
                      hours: lhs.hours.clampedAdding(rhs.hours),
                      minutes: lhs.minutes.clampedAdding(rhs.minutes),
                      seconds: lhs.seconds.clampedAdding(rhs.seconds),
                      nanoseconds: lhs.nanoseconds.clampedAdding(rhs.nanoseconds))
    }
    
    /// Returns a new date by adding the right period to the left date.
    public static func +(lhs: Date, rhs: Period) -> Date {
        return Calendar.autoupdatingCurrent.date(byAdding: rhs.asDateComponents(), to: lhs) ?? .distantFuture
    }
    
    /// Returns a new period by adding the right interval to the left period.
    public static func +(lhs: Period, rhs: Interval) -> Period {
        return Period(years: lhs.years, months: lhs.months, days: lhs.days,
                      hours: lhs.hours, minutes: lhs.minutes, seconds: lhs.seconds,
                      nanoseconds: lhs.nanoseconds.clampedAdding(rhs.ns))
    }
    
    internal func asDateComponents() -> DateComponents {
        return DateComponents(year: years, month: months, day: days,
                              hour: hours, minute: minutes, second: seconds,
                              nanosecond: nanoseconds)
    }
}

extension Int {
    
    /// Period by setting years to this value.
    public var years: Period {
        return Period(years: self)
    }
    
    /// Period by setting years to this value.
    public var year: Period {
        return years
    }
    
    /// Period by setting months to this value.
    public var months: Period {
        return Period(months: self)
    }
    
    /// Period by setting months to this value.
    public var month: Period {
        return months
    }
}


/// `Weekday` represents a day of the week, without a time.
public enum Weekday: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}


/// `MonthDay` represents a day in the month, without a time.
public enum MonthDay {
    
    case january(Int)
    
    case february(Int)
    
    case march(Int)
    
    case april(Int)
    
    case may(Int)
    
    case june(Int)
    
    case july(Int)
    
    case august(Int)
    
    case september(Int)
    
    case october(Int)
    
    case november(Int)
    
    case december(Int)
    
    internal func asDateComponents() -> DateComponents {
        switch self {
        case .january(let day):     return DateComponents(month: 1, day: day)
        case .february(let day):    return DateComponents(month: 2, day: day)
        case .march(let day):       return DateComponents(month: 3, day: day)
        case .april(let day):       return DateComponents(month: 4, day: day)
        case .may(let day):         return DateComponents(month: 5, day: day)
        case .june(let day):        return DateComponents(month: 6, day: day)
        case .july(let day):        return DateComponents(month: 7, day: day)
        case .august(let day):      return DateComponents(month: 8, day: day)
        case .september(let day):   return DateComponents(month: 9, day: day)
        case .october(let day):     return DateComponents(month: 10, day: day)
        case .november(let day):    return DateComponents(month: 11, day: day)
        case .december(let day):    return DateComponents(month: 12, day: day)
        }
    }
}
