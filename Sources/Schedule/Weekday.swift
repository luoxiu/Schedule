//
//  Weekday.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `Weekday` represents a day of a week without time.
public enum Weekday: Int {

    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var isToday: Bool {
        return Calendar.gregorian
            .dateComponents(in: .current, from: Date()).weekday == rawValue
    }

    func toDateComponents() -> DateComponents {
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
