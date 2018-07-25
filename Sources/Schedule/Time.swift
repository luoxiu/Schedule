//
//  Time.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `Time` represents a time without a date.
public struct Time {
    
    /// Hour of this time.
    public let hour: Int
    
    /// Minute of this time.
    public let minute: Int
    
    /// Second of this time.
    public let second: Int
    
    /// Nanosecond of this time.
    public let nanosecond: Int
    
    /// Creates a time with `hour`, `minute`, `second` and `nanosecond` fields.
    ///
    /// If any parameter is illegal, return nil.
    ///
    ///     Time(hour: 25) == nil
    ///     Time(hour: 1, minute: 61) == nil
    public init?(hour: Int, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) {
        guard (0...23).contains(hour) else { return nil }
        guard (0...59).contains(minute) else { return nil }
        guard (0...59).contains(second) else { return nil }
        guard (0...Int(NSEC_PER_SEC)).contains(nanosecond) else { return nil }
        
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }
    
    /// Creates a time with a timing string.
    ///
    /// If parameter is illegal, return nil.
    ///
    ///     Time("11") == Time(hour: 11)
    ///     Time("11:12") == Time(hour: 11, minute: 12)
    ///     Time("11:12:13") == Time(hour: 11, minute: 12, second: 13)
    ///     Time("11:12:13.123") == Time(hour: 11, minute: 12, second: 13, nanosecond: 123000000)
    ///
    ///     Time("-1.0") == nil
    public init?(timing: String) {
        let fields = timing.split(separator: ":")
        if fields.count > 3 { return nil }
        
        var h = 0, m = 0, s = 0, ns = 0
        
        guard let _h = Int(fields[0]) else { return nil }
        h = _h
        if fields.count > 1 {
            guard let _m = Int(fields[1]) else { return nil }
            m = _m
        }
        if fields.count > 2 {
            let values = fields[2].split(separator: ".")
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
    
    func asDateComponents() -> DateComponents {
        return DateComponents(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }
}
