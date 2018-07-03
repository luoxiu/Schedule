//
//  DateTime.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation

public struct Interval {
    
    public let nanoseconds: Double
    public init(nanoseconds: Double) {
        self.nanoseconds = nanoseconds
    }
    
    public init(seconds: Double) {
        self.nanoseconds = seconds * pow(10, 9)
    }
    
    public var seconds: Double {
        return nanoseconds / pow(10, 9)
    }
    
    public var isNegative: Bool {
        return nanoseconds.isLess(than: 0)
    }
    
    public var dispatchInterval: DispatchTimeInterval {
        if nanoseconds > Double(Int.max) { return .nanoseconds(.max) }
        if nanoseconds < Double(Int.min) { return .nanoseconds(.min) }
        return .nanoseconds(Int(nanoseconds))
    }
    
    public static func *(lhs: Interval, rhs: Double) -> Interval {
        return Interval(nanoseconds: lhs.nanoseconds * rhs)
    }
    
    public static func +(lhs: Interval, rhs: Interval) -> Interval {
        return Interval(nanoseconds: lhs.nanoseconds + rhs.nanoseconds)
    }
    
    public static func -(lhs: Interval, rhs: Interval) -> Interval {
        return Interval(nanoseconds: lhs.nanoseconds - rhs.nanoseconds)
    }
}

extension Interval: Hashable {
    
    public var hashValue: Int {
        return nanoseconds.hashValue
    }
    
    public static func ==(lhs: Interval, rhs: Interval) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Interval: Comparable {
    
    public static func < (lhs: Interval, rhs: Interval) -> Bool {
        return lhs.nanoseconds.magnitude < rhs.nanoseconds.magnitude
    }
}

extension Date {
    
    public var intervalSinceNow: Interval {
        return timeIntervalSinceNow.seconds
    }
    
    public func interval(since date: Date) -> Interval {
        return timeIntervalSince(date).seconds
    }
    
    public static func +(lhs: Date, rhs: Interval) -> Date {
        return lhs.addingTimeInterval(rhs.seconds)
    }
    
    @discardableResult
    public static func +=(lhs: inout Date, rhs: Interval) -> Date {
        lhs = lhs + rhs
        return lhs
    }
}

public protocol IntervalConvertible {
    
    func asNanoseconds() -> Double
}

extension Int: IntervalConvertible {
    
    public func asNanoseconds() -> Double {
        return Double(self)
    }
}

extension Double: IntervalConvertible {
    
    public func asNanoseconds() -> Double {
        return self
    }
}

extension IntervalConvertible {
    
    public var nanoseconds: Interval {
        return Interval(nanoseconds: asNanoseconds())
    }
    
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

public enum Weekday: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

public struct Time {
    
    public let hour: Int
    public let minute: Int
    public let second: Int
    public let nanosecond: Int
    
    public init?(hour: Int, minute: Int, second: Int, nanosecond: Int) {
        guard hour >= 0 && hour < 24 else { return nil }
        guard minute >= 0 && minute < 60 else { return nil }
        guard second >= 0 && second < 60 else { return nil }
        guard nanosecond >= 0 && nanosecond < Int(NSEC_PER_SEC) else { return nil }
        
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }
    
    /// "11"
    /// "11:12"
    /// "11:12:12"
    /// "11:12:13.123"
    public init?(timing: String) {
        let args = timing.split(separator: ":")
        var h = 0, m = 0, s = 0, ns = 0
        if args.count > 3 { return nil }
        
        guard let _h = Int(args[0]) else { return nil }
        h = _h
        if args.count > 1 {
            guard let _m = Int(args[1]) else { return nil }
            m = _m
        }
        if args.count > 2 {
            let components = args[2].split(separator: ".")
            if components.count > 2 { return nil }
            guard let _s = Int(components[0]) else { return nil }
            s = _s
            
            if components.count > 1 {
                guard let _ns = Int(components[1]) else { return nil }
                let digit = components[1].count
                ns = Int(Double(_ns) * pow(10, Double(9 - digit)))
            }
        }
        
        self.init(hour: h, minute: m, second: s, nanosecond: ns)
    }
    
    func asDateComponents() -> DateComponents {
        return DateComponents(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }
}

public struct Period {
    
    public let years: Int
    public let months: Int
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int
    public let nanoseconds: Int
    
    public init(years: Int = 0, months: Int = 0, days: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0, nanoseconds: Int = 0) {
        self.years = years
        self.months = months
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.nanoseconds = nanoseconds
    }
    
    public func and(_ period: Period) -> Period {
        let years = self.years + period.years
        let months = self.months + period.months
        let days = self.days + period.days
        let hours = self.hours + period.hours
        let minutes = self.minutes + period.minutes
        let seconds = self.seconds + period.seconds
        let nanoseconds = self.nanoseconds + period.nanoseconds
        return Period(years: years, months: months, days: days, hours: hours, minutes: minutes, seconds: seconds, nanoseconds: nanoseconds)
    }
    
    public static func +(lhs: Period, rhs: Period) -> Period {
        return lhs.and(rhs)
    }
    
    func asDateComponents() -> DateComponents {
        return DateComponents(year: years, month: months, day: days, hour: hours, minute: minutes, second: seconds, nanosecond: nanoseconds)
    }
}

extension Int {
    
    public var nanosecond: Period {
        return nanoseconds
    }
    
    public var nanoseconds: Period {
        return Period(nanoseconds: self)
    }
    
    public var second: Period {
        return seconds
    }
    
    public var seconds: Period {
        return Period(seconds: self)
    }
    
    public var minute: Period {
        return minutes
    }
    
    public var minutes: Period {
        return Period(minutes: self)
    }
    
    public var hour: Period {
        return hours
    }
    
    public var hours: Period {
        return Period(hours: self)
    }
    
    public var day: Period {
        return days
    }
    
    public var days: Period {
        return Period(days: self)
    }
    
    public var month: Period {
        return months
    }
    
    public var months: Period {
        return Period(months: self)
    }
    
    public var year: Period {
        return years
    }
    
    public var years: Period {
        return Period(years: self)
    }
}

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
    
    func asDateComponents() -> DateComponents {
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
