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
    ///     Time(hour: 11, minute: 11)  => "11:11:00.000"
    ///     Time(hour: 25)              => nil
    ///     Time(hour: 1, minute: 61)   => nil
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

    private static let cache: NSCache<NSString, DateFormatter> = {
       let c = NSCache<NSString, DateFormatter>()
        c.countLimit = 5
        return c
    }()

    /// Creates a time with a string.
    ///
    /// If parameter is illegal, return nil.
    ///
    ///     Time("11") == Time(hour: 11)
    ///     Time("11:12") == Time(hour: 11, minute: 12)
    ///     Time("11:12:13") == Time(hour: 11, minute: 12, second: 13)
    ///     Time("11:12:13.123") == Time(hour: 11, minute: 12, second: 13, nanosecond: 123000000)
    ///
    ///     Time("-1.0") == nil
    ///
    /// Each of previous examples can have a period suffixes("am", "AM", "pm", "PM") separated by spaces.
    public init?(_ string: String) {
        var is12HourClock = false
        for word in ["am", "pm", "AM", "PM"] {
            if string.contains(word) {
                is12HourClock = true
                break
            }
        }

        let supportedFormats = [
            "HH",                       // 09
            "HH:mm",                    // 09:30
            "HH:mm:ss",                 // 09:30:26
            "HH:mm:ss.SSS"             // 09:30:26.123
        ]
        for format in supportedFormats {
            var fmt = format
            if is12HourClock {
                fmt = fmt.replacingOccurrences(of: "HH", with: "hh")
                fmt += " a"
            }
            var formatter: DateFormatter! = Time.cache.object(forKey: fmt as NSString)
            if formatter == nil {
                formatter = DateFormatter()
                formatter?.calendar = Calendar(identifier: .gregorian)
                formatter?.locale = Locale(identifier: "en_US_POSIX")
                formatter?.timeZone = TimeZone.autoupdatingCurrent
                formatter.dateFormat = fmt
            }
            if let date = formatter.date(from: string) {
                Time.cache.setObject(formatter, forKey: fmt as NSString)
                let calendar = Calendar(identifier: .gregorian)
                let components = calendar.dateComponents(in: TimeZone.autoupdatingCurrent, from: date)
                if let hour = components.hour,
                    let minute = components.minute,
                    let second = components.second,
                    let nanosecond = components.nanosecond {
                    self.init(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
                    return
                }
            }
        }

        return nil
    }

    /// Interval since zero time.
    public var intervalSinceZeroTime: Interval {
        return Int(hour).hours + Int(minute).minutes + Int(second).seconds + Int(nanosecond).nanoseconds
    }

    func asDateComponents() -> DateComponents {
        return DateComponents(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }
}
