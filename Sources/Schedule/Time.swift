//
//  Time.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

/// `Time` represents a time without a date.
public struct Time {

    /// Hour of day.
    public let hour: Int

    /// Minute of hour.
    public let minute: Int

    /// Second of minute.
    public let second: Int

    /// Nanosecond of second.
    public let nanosecond: Int

    /// Creates a time with `hour`, `minute`, `second` and `nanosecond` fields.
    ///
    /// If any parameter is illegal, return nil.
    ///
    ///     Time(hour: 11, minute: 11)  => "11:11:00.000"
    ///     Time(hour: 25)              => nil
    ///     Time(hour: 1, minute: 61)   => nil
    public init?(hour: Int, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) {
        guard (0..<24).contains(hour),
         (0..<60).contains(minute),
         (0..<60).contains(second),
         (0..<Int(NSEC_PER_SEC)).contains(nanosecond)
        else { return nil }

        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }

    /// A cache for Date formatters.
    ///
    /// According to the [Foundation](https://github.com/apple/swift-corelibs-foundation), `NSCache` is available on linux.
    private static let FormatterCache: NSCache<NSString, DateFormatter> = {
        let c = NSCache<NSString, DateFormatter>()
        c.countLimit = 10
        return c
    }()

    /// Creates a time with a string.
    ///
    /// If the parameter is illegal, return nil.
    ///
    ///     Time("11") == Time(hour: 11)
    ///     Time("11:12") == Time(hour: 11, minute: 12)
    ///     Time("11:12:13") == Time(hour: 11, minute: 12, second: 13)
    ///     Time("11:12:13.123") == Time(hour: 11, minute: 12, second: 13, nanosecond: 123000000)
    ///
    ///     Time("-1.0") == nil
    ///
    /// Any of the previous examples can have a period suffix("am", "AM", "pm", "PM"),
    /// separated by a space.
    ///
    ///     Time("11 pm") == Time(hour: 23)
    ///     Time("11:12:13 PM") == Time(hour: 23, minute: 12, second: 13)
    public init?(_ string: String) {
        var is12HourTime = false
        for word in ["am", "pm", "AM", "PM"] {
            if string.contains(word) {
                is12HourTime = true
                break
            }
        }

        let supportedFormats = [
            "HH",                       // 09
            "HH:mm",                    // 09:30
            "HH:mm:ss",                 // 09:30:26
            "HH:mm:ss.SSS"              // 09:30:26.123
        ]

        for format in supportedFormats {
            var fmt = format
            if is12HourTime {
                fmt = fmt.replacingOccurrences(of: "HH", with: "hh")
                fmt += " a"
            }
            var formatter: DateFormatter! = Time.FormatterCache.object(forKey: fmt as NSString)
            if formatter == nil {
                formatter = DateFormatter()
                formatter?.locale = Locale(identifier: "en_US_POSIX")
                formatter?.calendar = Calendar.gregorian
                formatter?.timeZone = TimeZone.autoupdatingCurrent
                formatter.dateFormat = fmt
            }
            if let date = formatter.date(from: string) {
                Time.FormatterCache.setObject(formatter, forKey: fmt as NSString)
                let components = Calendar.gregorian.dateComponents(in: TimeZone.autoupdatingCurrent, from: date)
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

    /// The interval between this time and zero o'clock.
    public var intervalSinceZeroClock: Interval {
        return Int(hour).hours + Int(minute).minutes + Int(second).seconds + Int(nanosecond).nanoseconds
    }

    func toDateComponents() -> DateComponents {
        return DateComponents(calendar: Calendar.gregorian,
                              timeZone: TimeZone.autoupdatingCurrent,
                              hour: hour, minute: minute,
                              second: second, nanosecond: nanosecond)
    }
}
