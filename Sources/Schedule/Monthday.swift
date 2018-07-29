//
//  Monthday.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `Monthday` represents a day in month, without a time.
public enum Monthday {

    case january(Int)

    case february(Int)

    case march(Int)

    case april(Int)

    case may(Int)

    case june(Int)

    case july(Int)

    case august(Int)

    case september(Int)

    case october(Int)

    case november(Int)

    case december(Int)

    func asDateComponents() -> DateComponents {
        var dc: DateComponents
        switch self {
        case .january(let day):     dc = DateComponents(month: 1, day: day)
        case .february(let day):    dc = DateComponents(month: 2, day: day)
        case .march(let day):       dc = DateComponents(month: 3, day: day)
        case .april(let day):       dc = DateComponents(month: 4, day: day)
        case .may(let day):         dc = DateComponents(month: 5, day: day)
        case .june(let day):        dc = DateComponents(month: 6, day: day)
        case .july(let day):        dc = DateComponents(month: 7, day: day)
        case .august(let day):      dc = DateComponents(month: 8, day: day)
        case .september(let day):   dc = DateComponents(month: 9, day: day)
        case .october(let day):     dc = DateComponents(month: 10, day: day)
        case .november(let day):    dc = DateComponents(month: 11, day: day)
        case .december(let day):    dc = DateComponents(month: 12, day: day)
        }
        dc.calendar = Calendar.gregorian
        dc.timeZone = TimeZone.autoupdatingCurrent
        return dc
    }

    var isToday: Bool {
        let c0 = Calendar.gregorian.dateComponents(in: TimeZone.autoupdatingCurrent, from: Date())
        let c1 = asDateComponents()
        return c0.month == c1.month && c0.day == c1.day
    }
}
