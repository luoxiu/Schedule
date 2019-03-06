//
//  Deprecated.swift
//  Schedule
//
//  Created by Quentin Jin on 2019/3/4.
//  Copyright © 2019 Schedule. All rights reserved.
//

import Foundation

extension Monthday {

    /// A Boolean value indicating whether today is the monthday.
    @available(*, deprecated, message: "Use date.is(_:Monthday)")
    public var isToday: Bool {
        let components = toDateComponents()

        let m = Calendar.gregorian.component(.month, from: Date())
        let d = Calendar.gregorian.component(.day, from: Date())

        return m == components.month && d == components.day
    }
}

extension Weekday {

    /// A Boolean value indicating whether today is the weekday.
    @available(*, deprecated, message: "Use date.is(_:Weekday)")
    public var isToday: Bool {
        return Calendar.gregorian.component(.weekday, from: Date()) == rawValue
    }
}

extension Time {

    /// The interval between this time and zero o'clock.
    @available(*, deprecated, renamed: "intervalSinceStartOfDay")
    public var intervalSinceZeroClock: Interval {
        return hour.hours + minute.minutes + second.seconds + nanosecond.nanoseconds
    }
}

extension Plan {

    /// Creates a plan from a date sequence.
    /// The task will be executed at each date in the sequence.
    /// - Note: Returns `Plan.never` if given no parameters.
    @available(*, deprecated, message: "Use Plan.of")
    public static func from<S>(_ sequence: S) -> Plan where S: Sequence, S.Element == Date {
        return Plan.make(sequence.makeIterator)
    }
}
