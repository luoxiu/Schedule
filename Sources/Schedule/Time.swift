//
//  Time.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `Time` represents a time without a date.
///
/// It is a specific point in a day.
public struct Time {
    
    public let hour: Int
    
    public let minute: Int
    
    public let second: Int
    
    public let nanosecond: Int
    
    /// Create a date with `hour`, `minute`, `second` and `nanosecond` fields.
    ///
    /// If parameter is illegal, then return nil.
    ///
    ///     Time(hour: 25) == nil
    ///     Time(hour: 1, minute: 61) == nil
    public init?(hour: Int, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) {
        guard hour >= 0 && hour < 24 else { return nil }
        guard minute >= 0 && minute < 60 else { return nil }
        guard second >= 0 && second < 60 else { return nil }
        guard nanosecond >= 0 && nanosecond < Int(NSEC_PER_SEC) else { return nil }
        
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }
    
    /// Create a time with a timing string
    ///
    /// For example:
    ///
    ///     Time("11") == Time(hour: 11)
    ///     Time("11:12") == Time(hour: 11, minute: 12)
    ///     Time("11:12:13") == Time(hour: 11, minute: 12, second: 13)
    ///     Time("11:12:13.123") == Time(hour: 11, minute: 12, second: 13, nanosecond: 123000000)
    ///
    /// If timing's format is illegal, then return nil.
    public init?(timing: String) {
        let args = timing.split(separator: ":")
        if args.count > 3 { return nil }
        
        var h = 0, m = 0, s = 0, ns = 0
        
        guard let _h = Int(args[0]) else { return nil }
        h = _h
        if args.count > 1 {
            guard let _m = Int(args[1]) else { return nil }
            m = _m
        }
        if args.count > 2 {
            let values = args[2].split(separator: ".")
            if values.count > 2 { return nil }
            guard let _s = Int(values[0]) else { return nil }
            s = _s
            
            if values.count > 1 {
                guard let _ns = Int(values[1]) else { return nil }
                let digits = values[1].count
                ns = Int(Double(_ns) * pow(10, Double(9 - digits)))
            }
        }
        
        self.init(hour: h, minute: m, second: s, nanosecond: ns)
    }
    
    internal func asDateComponents() -> DateComponents {
        return DateComponents(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }
}
