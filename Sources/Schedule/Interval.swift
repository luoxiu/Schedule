import Foundation

/// `Interval` represents a length of time.
public struct Interval {

    ///  The length of this interval in nanoseconds.
    public let nanoseconds: Double

    /// Creates an interval from the given number of nanoseconds.
    public init(nanoseconds: Double) {
        self.nanoseconds = nanoseconds
    }
}

// MARK: - Describing
extension Interval {

    /// A boolean value indicating whether this interval is less than zero.
    ///
    /// An interval can be negative:
    ///
    /// - The interval from 6:00 to 7:00 is `1.hour`,
    ///   but the interval from 7:00 to 6:00 is `-1.hour`.
    ///   In this case, `-1.hour` means **one hour ago**.
    ///
    /// - The interval comparing `3.hour` to `1.hour` is `2.hour`,
    ///   but the interval comparing `1.hour` to `3.hour` is `-2.hour`.
    ///   In this case, `-2.hour` means **two hours shorter**
    public var isNegative: Bool {
        return nanoseconds < 0
    }

    /// See `isNegative`.
    public var isPositive: Bool {
        return nanoseconds > 0
    }

    /// The absolute value of the length of this interval in nanoseconds.
    public var magnitude: Double {
        return nanoseconds.magnitude
    }

    /// The additive inverse of this interval.
    public var opposite: Interval {
        return (-nanoseconds).nanoseconds
    }
}

extension Interval: Hashable {

    /// The hashValue of this interval.
    public var hashValue: Int {
        return nanoseconds.hashValue
    }

    /// Returns a boolean value indicating whether two intervals are equal.
    public static func == (lhs: Interval, rhs: Interval) -> Bool {
        return lhs.nanoseconds == rhs.nanoseconds
    }
}

extension Interval: CustomStringConvertible {

    /// A textual representation of this interval.
    public var description: String {
        return "Interval: \(nanoseconds.clampedToInt()) nanoseconds"
    }
}

extension Interval: CustomDebugStringConvertible {

    /// A textual representation of this interval for debugging.
    public var debugDescription: String {
        return description
    }
}

// MARK: - Comparing
extension Interval {

    /// Compares two intervals.
    ///
    /// A positive interval is always ordered ascending to a negative interval.
    public func compare(_ other: Interval) -> ComparisonResult {
        let now = Date()
        return now.adding(self).compare(now.adding(other))
    }

    /// Returns a boolean value indicating whether this interval is longer
    /// than the given value.
    public func isLonger(than other: Interval) -> Bool {
        return magnitude > other.magnitude
    }

    /// Returns a boolean value indicating whether this interval is shorter
    /// than the given value.
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
}

extension Interval: Comparable {

    /// Returns a Boolean value indicating whether the first interval is
    /// less than the second interval.
    ///
    /// A negative interval is always less than a positive interval.
    public static func < (lhs: Interval, rhs: Interval) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}

// MARK: - Adding & Subtracting
extension Interval {
    /// Returns a new interval by multipling this interval by the given number.
    ///
    ///     1.hour * 2 == 2.hours
    public func multiplying(by multiplier: Double) -> Interval {
        return Interval(nanoseconds: nanoseconds * multiplier)
    }

    /// Returns a new interval by adding the given interval to this interval.
    ///
    ///     1.hour + 1.hour == 2.hours
    public func adding(_ other: Interval) -> Interval {
        return Interval(nanoseconds: nanoseconds + other.nanoseconds)
    }

    /// Returns a new interval by subtracting the given interval from this interval.
    ///
    ///     2.hours - 1.hour == 1.hour
    public func subtracting(_ other: Interval) -> Interval {
        return Interval(nanoseconds: nanoseconds - other.nanoseconds)
    }
}

// MARK: - Operators
extension Interval {

    /// Returns a new interval by multipling the left interval by the right number.
    ///
    ///     1.hour * 2 == 2.hours
    public static func * (lhs: Interval, rhs: Double) -> Interval {
        return lhs.multiplying(by: rhs)
    }

    /// Returns a new interval by adding the right interval to the left interval.
    ///
    ///     1.hour + 1.hour == 2.hours
    public static func + (lhs: Interval, rhs: Interval) -> Interval {
        return lhs.adding(rhs)
    }

    /// Returns a new interval by subtracting the right interval from the left interval.
    ///
    ///     2.hours - 1.hour == 1.hour
    public static func - (lhs: Interval, rhs: Interval) -> Interval {
        return lhs.subtracting(rhs)
    }

    /// Adds two intervals and stores the result in the first interval.
    public static func += (lhs: inout Interval, rhs: Interval) {
        lhs = lhs.adding(rhs)
    }

    /// Returns the additive inverse of the specified interval.
    public prefix static func - (interval: Interval) -> Interval {
        return interval.opposite
    }
}

// MARK: - Sugars
extension Interval {

    /// Creates an interval from the given number of seconds.
    public init(seconds: Double) {
        self.init(nanoseconds: seconds * pow(10, 9))
    }

    /// The length of this interval in nanoseconds.
    public func asNanoseconds() -> Double {
        return nanoseconds
    }

    /// The length of this interval in microseconds.
    public func asMicroseconds() -> Double {
        return nanoseconds / pow(10, 3)
    }

    /// The length of this interval in milliseconds.
    public func asMilliseconds() -> Double {
        return nanoseconds / pow(10, 6)
    }

    /// The length of this interval in seconds.
    public func asSeconds() -> Double {
        return nanoseconds / pow(10, 9)
    }

    /// The length of this interval in minutes.
    public func asMinutes() -> Double {
        return asSeconds() / 60
    }

    /// The length of this interval in hours.
    public func asHours() -> Double {
        return asMinutes() / 60
    }

    /// The length of this interval in days.
    public func asDays() -> Double {
        return asHours() / 24
    }

    /// The length of this interval in weeks.
    public func asWeeks() -> Double {
        return asDays() / 7
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

// MARK: - Date
extension Date {

    /// The interval between this date and the current date and time.
    ///
    /// If this date is earlier than now, this interval will be negative.
    public var intervalSinceNow: Interval {
        return timeIntervalSinceNow.seconds
    }

    /// Returns the interval between this date and the given date.
    ///
    /// If this date is earlier than the given date, this interval will be negative.
    public func interval(since date: Date) -> Interval {
        return timeIntervalSince(date).seconds
    }

    /// Returns a new date by adding an interval to this date.
    public func adding(_ interval: Interval) -> Date {
        return addingTimeInterval(interval.asSeconds())
    }

    /// Returns a date with an interval added to it.
    public static func + (lhs: Date, rhs: Interval) -> Date {
        return lhs.adding(rhs)
    }
}

// MARK: - DispatchSourceTimer
extension DispatchSourceTimer {

    func schedule(after timeout: Interval) {
        guard !timeout.isNegative else { return }
        let ns = timeout.nanoseconds.clampedToInt()
        schedule(wallDeadline: .now() + DispatchTimeInterval.nanoseconds(ns))
    }
}
