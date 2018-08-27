//
//  Extensions.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/22.
//

import Foundation

extension Double {

    func clampedToInt() -> Int {
        if self >= Double(Int.max) { return Int.max }
        if self <= Double(Int.min) { return Int.min }
        return Int(self)
    }
}

extension Int {

    func clampedAdding(_ other: Int) -> Int {
        return (Double(self) + Double(other)).clampedToInt()
    }

    func clampedSubtracting(_ other: Int) -> Int {
        return clampedAdding(-other)
    }
}

extension Calendar {

    static let gregorian = Calendar(identifier: .gregorian)
}

extension Date {

    func zeroClock() -> Date {
        let calendar = Calendar.gregorian
        let timeZone = TimeZone.current
        var dateComponents = calendar.dateComponents(in: timeZone, from: self)
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        dateComponents.nanosecond = 0
        return calendar.date(from: dateComponents)!
    }
}
