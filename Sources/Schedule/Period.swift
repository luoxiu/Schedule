//
//  Period.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation


/// `Period` represents a period of time defined in terms of fields.
///
/// It's a little different from `Interval`.
///
/// For example:
///
/// If you add a period `1.month` to the 1st January,
/// you will get the 1st February.
///
/// If you add the same period to the 1st February,
/// you will get the 1st March.
///
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
    
    /// Returns a date with a period added to it.
    public static func +(lhs: Date, rhs: Period) -> Date {
        return Calendar.autoupdatingCurrent.date(byAdding: rhs.asDateComponents(), to: lhs) ?? .distantFuture
    }
    
    /// Return a period with a interval added to it.
    public static func +(lhs: Period, rhs: Interval) -> Period {
        return Period(years: lhs.years, months: lhs.months, days: lhs.days,
                      hours: lhs.hours, minutes: lhs.minutes, seconds: lhs.seconds,
                      nanoseconds: lhs.nanoseconds.clampedAdding(rhs.ns))
    }
    
    func asDateComponents() -> DateComponents {
        return DateComponents(year: years, month: months, day: days,
                              hour: hours, minute: minutes, second: seconds,
                              nanosecond: nanoseconds)
    }
}

extension Int {
    
    public var years: Period {
        return Period(years: self)
    }
    
    public var year: Period {
        return years
    }
    
    public var months: Period {
        return Period(months: self)
    }
    
    public var month: Period {
        return months
    }
}
