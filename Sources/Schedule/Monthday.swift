//
//  Monthday.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `MonthDay` represents a day in month, without a time.
public enum MonthDay {
    
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
        switch self {
        case .january(let day):     return DateComponents(month: 1, day: day)
        case .february(let day):    return DateComponents(month: 2, day: day)
        case .march(let day):       return DateComponents(month: 3, day: day)
        case .april(let day):       return DateComponents(month: 4, day: day)
        case .may(let day):         return DateComponents(month: 5, day: day)
        case .june(let day):        return DateComponents(month: 6, day: day)
        case .july(let day):        return DateComponents(month: 7, day: day)
        case .august(let day):      return DateComponents(month: 8, day: day)
        case .september(let day):   return DateComponents(month: 9, day: day)
        case .october(let day):     return DateComponents(month: 10, day: day)
        case .november(let day):    return DateComponents(month: 11, day: day)
        case .december(let day):    return DateComponents(month: 12, day: day)
        }
    }
}
