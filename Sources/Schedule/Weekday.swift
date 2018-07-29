//
//  Weekday.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `Weekday` represents a day of week, without a time.
public enum Weekday: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var isToday: Bool {
        var c = Calendar.gregorian.dateComponents(in: TimeZone.autoupdatingCurrent, from: Date())
        return c.weekday == rawValue
    }

    func asDateComponents() -> DateComponents {
        var dc = DateComponents(weekday: rawValue)
        dc.calendar = Calendar.gregorian
        dc.timeZone = TimeZone.autoupdatingCurrent
        return dc
    }
}
