//
//  Misc.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation
@testable import Schedule

extension Date {
    
    var dateComponents: DateComponents {
        return Calendar(identifier: .gregorian).dateComponents(in: TimeZone.autoupdatingCurrent, from: self)
    }
    
    var localizedDescription: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }
    
    init(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) {
        let components = DateComponents(calendar: Calendar(identifier: .gregorian),
                                        timeZone: TimeZone.autoupdatingCurrent,
                                        year: year, month: month, day: day,
                                        hour: hour, minute: minute, second: second,
                                        nanosecond: nanosecond)
        self = components.date ?? Date.distantPast
    }
}

extension Interval {

    func isAlmostEqual(to interval: Interval, leeway: Interval) -> Bool {
        return (interval - self).magnitude <= leeway.magnitude
    }
}

extension Double {
    
    func isAlmostEqual(to double: Double, leeway: Double) -> Bool {
        return (double - self).magnitude <= leeway
    }
}

extension Sequence where Element == Interval {
    
    func isAlmostEqual<S>(to sequence: S, leeway: Interval) -> Bool where S: Sequence, S.Element == Element {
        var i0 = self.makeIterator()
        var i1 = sequence.makeIterator()
        while let l = i0.next(), let r = i1.next() {
            if (l - r).magnitude > leeway.magnitude {
                return false
            }
        }
        return i0.next() == i1.next()
    }
}

extension Schedule {
    
    func isAlmostEqual(to schedule: Schedule, leeway: Interval) -> Bool {
        return makeIterator().isAlmostEqual(to: schedule.makeIterator(), leeway: leeway)
    }
}

struct Constants {
    
    static let NSEC_PER_USEC = Double(Foundation.NSEC_PER_USEC)
    static let NSEC_PER_MSEC = Double(Foundation.NSEC_PER_MSEC)
    static let NSEC_PER_SEC = Double(Foundation.NSEC_PER_SEC)
    static let NSEC_PER_M = Double(Foundation.NSEC_PER_SEC) * 60
    static let NSEC_PER_H = Double(Foundation.NSEC_PER_SEC) * 60 * 60
    static let NSEC_PER_D = Double(Foundation.NSEC_PER_SEC) * 60 * 60 * 24
    static let NSEC_PER_W = Double(Foundation.NSEC_PER_SEC) * 60 * 60 * 24 * 7
}
