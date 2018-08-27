//
//  Monthday.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `Monthday` represents a day of a month without years.
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

    var isToday: Bool {
        let lhs = Calendar.gregorian.dateComponents(in: TimeZone.current, from: Date())
        let rhs = toDateComponents()
        return lhs.month == rhs.month && lhs.day == rhs.day
    }

    func toDateComponents() -> DateComponents {
        var month, day: Int
        switch self {
        case .january(let n):       month = 1; day = n
        case .february(let n):      month = 2; day = n
        case .march(let n):         month = 3; day = n
        case .april(let n):         month = 4; day = n
        case .may(let n):           month = 5; day = n
        case .june(let n):          month = 6; day = n
        case .july(let n):          month = 7; day = n
        case .august(let n):        month = 8; day = n
        case .september(let n):     month = 9; day = n
        case .october(let n):       month = 10; day = n
        case .november(let n):      month = 11; day = n
        case .december(let n):      month = 12; day = n
        }
        return DateComponents(calendar: Calendar.gregorian,
                              timeZone: TimeZone.current,
                              month: month,
                              day: day)
    }
}
