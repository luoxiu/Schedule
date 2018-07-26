//
//  Extensions.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/22.
//

import Foundation

extension Int {

    func clampedAdding(_ other: Int) -> Int {
        let r = addingReportingOverflow(other)
        return r.overflow ? (other > 0 ? .max : .min) : r.partialValue
    }

    func clampedSubtracting(_ other: Int) -> Int {
        let r = subtractingReportingOverflow(other)
        return r.overflow ? (other > 0 ? .min : .max) : r.partialValue
    }
}

extension Double {

    func clampedToInt() -> Int {
        if self > Double(Int.max) { return Int.max }
        if self < Double(Int.min) { return Int.min }
        return Int(self)
    }
}
