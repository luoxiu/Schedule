import Foundation

/// Type used to represent a time-based amount of time, such as '34.5 seconds'.
public struct Interval {

    ///  The length of this interval in nanoseconds.
    public let nanoseconds: Double

    /// Creates an interval from the given number of nanoseconds.
    public init(nanoseconds: Double) {
        self.nanoseconds = nanoseconds
    }
}

extension Interval: Hashable { }

extension Interval {

    /// A Boolean value indicating whether this interval is less than zero.
    ///
    ///
    /// An Interval represents a directed distance between two points
    /// on the time-line and can therefore be positive, zero or negative.
    public var isNegative: Bool {
        return nanoseconds < 0
    }

    /// A copy of this duration with a positive length.
    public var abs: Interval {
        return Interval(nanoseconds: Swift.abs(nanoseconds))
    }

    /// A copy of this interval with the length negated.
    public var negated: Interval {
        return Interval(nanoseconds: -nanoseconds)
    }
}

extension Interval: CustomStringConvertible {

    /// A textual representation of this interval.
    ///
    ///     "Interval: 1000 nanoseconds"
    public var description: String {
        return "Interval: \(nanoseconds.clampedToInt()) nanosecond(s)"
    }
}

extension Interval: CustomDebugStringConvertible {

    /// A textual representation of this interval for debugging.
    ///
    ///     "Interval: 1000 nanoseconds"
    public var debugDescription: String {
        return description
    }
}

// MARK: - Comparing

extension Interval: Comparable {

    /// Compares two intervals and returns a comparison result value
    /// that indicates the sort order of two intervals.
    ///
    /// A positive interval is always ordered ascending to a negative interval.
    public func compare(_ other: Interval) -> ComparisonResult {
        let d = nanoseconds - other.nanoseconds

        if d < 0 { return .orderedAscending }
        if d > 0 { return .orderedDescending }
        return .orderedSame
    }

    /// Returns a Boolean value indicating whether the first interval is
    /// less than the second interval.
    ///
    /// A negative interval is always less than a positive interval.
    public static func < (lhs: Interval, rhs: Interval) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }

    /// Returns a Boolean value indicating whether this interval is longer
    /// than the given interval.
    public func isLonger(than other: Interval) -> Bool {
        return abs > other.abs
    }

    /// Returns a Boolean value indicating whether this interval is shorter
    /// than the given interval.
    public func isShorter(than other: Interval) -> Bool {
        return abs < other.abs
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
        return lhs.adding(rhs.negated)
    }

    /// Adds two intervals and stores the result in the left interval.
    public static func += (lhs: inout Interval, rhs: Interval) {
        lhs = lhs.adding(rhs)
    }

    /// Returns the additive inverse of the specified interval.
    public prefix static func - (interval: Interval) -> Interval {
        return interval.negated
    }
}

// MARK: - Sugars

extension Interval {

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

    /// Creates an interval from this amount of nanoseconds.
    public var nanoseconds: Interval {
        return Interval(nanoseconds: Double(self))
    }
}

extension Double: IntervalConvertible {

    /// Creates an interval from this amount of nanoseconds.
    public var nanoseconds: Interval {
        return Interval(nanoseconds: self)
    }
}

extension IntervalConvertible {

    // Alias for `nanoseconds`.
    public var nanosecond: Interval {
        return nanoseconds
    }

    // Alias for `microseconds`.
    public var microsecond: Interval {
        return microseconds
    }

    /// Creates an interval from this amount of microseconds.
    public var microseconds: Interval {
        return nanoseconds * pow(10, 3)
    }

    /// Alias for `milliseconds`.
    public var millisecond: Interval {
        return milliseconds
    }

    /// Creates an interval from this amount of milliseconds.
    public var milliseconds: Interval {
        return microseconds * pow(10, 3)
    }

    /// Alias for `second`.
    public var second: Interval {
        return seconds
    }

    /// Creates an interval from this amount of seconds.
    public var seconds: Interval {
        return milliseconds * pow(10, 3)
    }

    /// Alias for `minute`.
    public var minute: Interval {
        return minutes
    }

    /// Creates an interval from this amount of minutes.
    public var minutes: Interval {
        return seconds * 60
    }

    /// Alias for `hours`.
    public var hour: Interval {
        return hours
    }

    /// Creates an interval from this amount of hours.
    public var hours: Interval {
        return minutes * 60
    }

    /// Alias for `days`.
    public var day: Interval {
        return days
    }

    /// Creates an interval from this amount of days.
    public var days: Interval {
        return hours * 24
    }

    /// Alias for `weeks`.
    public var week: Interval {
        return weeks
    }

    /// Creates an interval from this amount of weeks.
    public var weeks: Interval {
        return days * 7
    }
}

// MARK: - Date

extension Date {

    /// The interval between this date and the current date and time.
    ///
    /// If this date is earlier than now, the interval will be negative.
    public var intervalSinceNow: Interval {
        return timeIntervalSinceNow.seconds
    }

    /// Returns the interval between this date and the given date.
    ///
    /// If this date is earlier than the given date, the interval will be negative.
    public func interval(since date: Date) -> Interval {
        return timeIntervalSince(date).seconds
    }

    /// Returns a new date by adding an interval to this date.
    public func adding(_ interval: Interval) -> Date {
        return addingTimeInterval(interval.asSeconds())
    }

    /// Returns a new date by adding an interval to the date.
    public static func + (lhs: Date, rhs: Interval) -> Date {
        return lhs.adding(rhs)
    }
}

// MARK: - DispatchSourceTimer

extension DispatchSourceTimer {

    /// Schedule this timer after the given interval.
    func schedule(after timeout: Interval) {
        if timeout.isNegative { return }
        let ns = timeout.nanoseconds.clampedToInt()
        schedule(wallDeadline: .now() + DispatchTimeInterval.nanoseconds(ns))
    }
}
