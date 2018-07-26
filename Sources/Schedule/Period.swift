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

    public private(set) var years: Int

    public private(set) var months: Int

    public private(set) var days: Int

    public private(set) var hours: Int

    public private(set) var minutes: Int

    public private(set) var seconds: Int

    public private(set) var nanoseconds: Int

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

    private static var map: Atomic<[String: Int]> = Atomic([
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
        "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12
    ])

    public static func registerQuantifier(_ word: String, for number: Int) {
        map.mutate {
            $0[word] = number
        }
    }

    /// Creates a period from a natural expression.
    ///
    ///     Period("one second") => Period(seconds: 1)
    ///     Period("two hours and ten minutes") => Period(hours: 2, minutes: 10)
    ///     Period("1 year, 2 months and 3 days") => Period(years: 1, months: 2, days: 3)
    public init?(_ string: String) {
        var period = string
        for (word, number) in Period.map.read() {
            period = period.replacingOccurrences(of: word, with: "\(number)")
        }
        guard let regex = try? NSRegularExpression(pattern: "( and |, )") else {
            return nil
        }
        period = regex.stringByReplacingMatches(in: period, range: NSRange(location: 0, length: period.count), withTemplate: "$")

        var result = 0.year
        for pair in period.split(separator: "$").map({ $0.split(separator: " ") }) {
            guard pair.count == 2 else { return nil }
            guard let number = Int(pair[0]) else { return nil }
            var word = String(pair[1])
            if word.last == "s" { word.removeLast() }
            switch word {
            case "year":            result = result + number.years
            case "month":           result = result + number.months
            case "day":             result = result + number.days
            case "week":            result = result + (number * 7).days
            case "hour":            result = result + number.hours
            case "minute":          result = result + number.minutes
            case "second":          result = result + number.second
            case "nanosecond":      result = result + number.nanosecond
            default:                break
            }
        }
        self = result
    }

    /// Returns a new period by adding a period to this period.
    public func adding(_ other: Period) -> Period {
        return Period(years: years.clampedAdding(other.years),
                      months: months.clampedAdding(other.months),
                      days: days.clampedAdding(other.days),
                      hours: hours.clampedAdding(other.hours),
                      minutes: minutes.clampedAdding(other.minutes),
                      seconds: seconds.clampedAdding(other.seconds),
                      nanoseconds: nanoseconds.clampedAdding(other.nanoseconds))
    }

    /// Returns a new period by adding an interval to this period.
    ///
    /// You can tidy the new period by specify the unit parameter.
    ///
    ///     1.month.adding(25.hour, tiyding: .day) => Period(months: 1, days: 1, hours: 1)
    public func adding(_ interval: Interval, tidying unit: Unit = .day) -> Period {
        var period = Period(years: years, months: months, days: days,
                      hours: hours, minutes: minutes, seconds: seconds,
                      nanoseconds: nanoseconds.clampedAdding(interval.nanoseconds.clampedToInt()))
        period = period.tidied(to: unit)
        return period
    }

    /// Adds two periods and produces their sum.
    public static func + (lhs: Period, rhs: Period) -> Period {
        return lhs.adding(rhs)
    }

    /// Returns a period with an interval added to it.
    public static func + (lhs: Period, rhs: Interval) -> Period {
        return lhs.adding(rhs)
    }

    /// Type used to as tidy's parameter.
    public enum Unit {
        case day, hour, minute, second, nanosecond
    }

    /// Returns the tidied period.
    ///
    ///     Period(hours: 25).tidied(to .day) => Period(days: 1, hours: 1)
    public func tidied(to unit: Unit) -> Period {
        var period = self
        if case .nanosecond = unit { return period }
        if period.nanoseconds.magnitude >= UInt(NSEC_PER_SEC) {
            period.seconds += period.nanoseconds / Int(NSEC_PER_SEC)
            period.nanoseconds %= Int(NSEC_PER_SEC)
        }

        if case .second = unit { return period }
        if period.seconds.magnitude >= 60 {
            period.minutes += period.seconds / 60
            period.seconds %= 60
        }

        if case .minute = unit { return period }
        if period.minutes.magnitude >= 60 {
            period.hours += period.minutes / 60
            period.minutes %= 60
        }

        if case .hour = unit { return period }
        if period.hours.magnitude >= 24 {
            period.days += period.hours / 24
            period.hours %= 24
        }
        return period
    }

    func asDateComponents() -> DateComponents {
        return DateComponents(year: years, month: months, day: days,
                              hour: hours, minute: minutes, second: seconds,
                              nanosecond: nanoseconds)
    }
}

extension Date {

    /// Returns a new date by adding a period to this date.
    public func adding(_ period: Period) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: period.asDateComponents(), to: self) ?? .distantFuture
    }

    /// Returns a date with a period added to it.
    public static func + (lhs: Date, rhs: Period) -> Date {
        return lhs.adding(rhs)
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
