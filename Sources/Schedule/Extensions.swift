//
//  Extensions.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/22.
//

import Foundation

extension Int {

    func clampedAdding(_ other: Int) -> Int {
        return (Double(self) + Double(other)).clampedToInt()
    }

    func clampedSubtracting(_ other: Int) -> Int {
        return (Double(self) - Double(other)).clampedToInt()
    }
}

extension Double {

    func clampedToInt() -> Int {
        if self >= Double(Int.max) { return Int.max }
        if self <= Double(Int.min) { return Int.min }
        return Int(self)
    }
}

extension DispatchQueue {

    func async(after delay: Interval, execute body: @escaping () -> Void) {
        asyncAfter(wallDeadline: .now() + delay.seconds, execute: body)
    }
}

extension Date {

    func localZero() -> Date {
        let tz = TimeZone.autoupdatingCurrent
        let calendar = Calendar.gregorian
        var dc = calendar.dateComponents(in: tz, from: self)
        dc.hour = 0
        dc.minute = 0
        dc.second = 0
        dc.nanosecond = 0
        return calendar.date(from: dc)!
    }
}

extension Calendar {

    static let gregorian = Calendar(identifier: .gregorian)
}
