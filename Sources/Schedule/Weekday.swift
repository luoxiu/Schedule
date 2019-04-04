import Foundation

/// `Weekday` represents a day of a week.
public enum Weekday: Int {

    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    /// Returns dateComponenets of the weekday, using gregorian calender and
    /// current time zone.
    public func asDateComponents() -> DateComponents {
        return DateComponents(
            calendar: Calendar.gregorian,
            timeZone: TimeZone.current,
            weekday: rawValue)
    }
}

extension Date {

    /// Returns a Boolean value indicating whether this date is the weekday in current time zone.
    public func `is`(_ weekday: Weekday) -> Bool {
        return Calendar.gregorian.component(.weekday, from: self) == weekday.rawValue
    }
}

extension Weekday: CustomStringConvertible {

    /// A textual representation of this weekday.
    ///
    ///     "Weekday: Friday"
    public var description: String {
        return "Weekday: \(Calendar.gregorian.weekdaySymbols[rawValue - 1])"
    }
}

extension Weekday: CustomDebugStringConvertible {

    /// A textual representation of this weekday for debugging.
    ///
    ///     "Weekday: Friday"
    public var debugDescription: String {
        return description
    }
}
