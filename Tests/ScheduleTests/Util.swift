//
//  Util.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import Foundation
@testable import Schedule

extension Date {
    
    var dateComponents: DateComponents {
        return Calendar.current.dateComponents(in: TimeZone.current, from: self)
    }
    
    var localizedDescription: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }
    
    init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, nanosecond: Int) {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second, nanosecond: nanosecond)
        let date = Calendar.current.date(from: components) ?? Date.distantPast
        self.init(timeIntervalSinceNow: date.timeIntervalSinceNow)
    }
}

extension Sequence where Element == Interval {
    
    func isEqual<S>(to sequence: S, leeway: Interval) -> Bool where S: Sequence, S.Element == Element {
        var i0 = self.makeIterator()
        var i1 = sequence.makeIterator()
        while let l = i0.next(), let r = i1.next() {
            let diff = Swift.max(l, r) - Swift.min(l, r)
            if diff < leeway { continue }
            return false
        }
        return i0.next() == i1.next()
    }
}

extension Interval {
    
    func isEqual(to interval: Interval, leeway: Interval) -> Bool {
        let diff = Swift.max(self, interval) - Swift.min(self, interval)
        return diff < leeway
    }
}

struct K {
    
    static let ns_per_us = Double(NSEC_PER_USEC)
    static let ns_per_ms = Double(NSEC_PER_MSEC)
    static let ns_per_s = Double(NSEC_PER_SEC)
    static let ns_per_m = Double(NSEC_PER_SEC) * 60
    static let ns_per_h = Double(NSEC_PER_SEC) * 60 * 60
    static let ns_per_d = Double(NSEC_PER_SEC) * 60 * 60 * 24
    static let ns_per_w = Double(NSEC_PER_SEC) * 60 * 60 * 24 * 7
}
