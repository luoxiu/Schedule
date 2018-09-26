import Foundation

/// `Weekday` represents a day of a week without time.
public enum Weekday: Int {

    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    /// A Boolean value indicating whether today is the weekday.
    public var isToday: Bool {
        return Calendar.gregorian.dateComponents(in: .current, from: Date()).weekday == rawValue
    }

    /// Returns a dateComponenets of the weekday, using gregorian calender and
    /// current time zone.
    public func toDateComponents() -> DateComponents {
        return DateComponents(calendar: Calendar.gregorian,
                              timeZone: TimeZone.current,
                              weekday: rawValue)
    }
}

extension Weekday: CustomStringConvertible {

    /// A textual representation of this weekday.
    public var description: String {
        return "Weekday: \(Calendar.gregorian.weekdaySymbols[rawValue - 1])"
    }
}

extension Weekday: CustomDebugStringConvertible {

    /// A textual representation of this weekday for debugging.
    public var debugDescription: String {
        return description
    }
}
