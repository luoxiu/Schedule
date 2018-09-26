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
              (0..<Int(1.second.nanoseconds)).contains(nanosecond) else { return nil }

        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }

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
        let pattern = "^(\\d{1,2})(:(\\d{1,2})(:(\\d{1,2})(.(\\d{1,3}))?)?)?( (am|AM|pm|PM))?$"

        guard let regexp = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        guard let result = regexp.matches(in: string, options: [], range: NSRange(location: 0, length: string.count)).first else { return nil }

        var hasAM = false
        var hasPM = false
        var values: [Int] = []

        for i in 0..<result.numberOfRanges {
            let range = result.range(at: i)
            if range.length == 0 { continue }
            let captured = NSString(string: string).substring(with: range)
            hasAM = ["am", "AM"].contains(captured)
            hasPM = ["pm", "PM"].contains(captured)
            if let value = Int(captured) {
                values.append(value)
            }
        }
        guard values.count > 0 else { return nil }

        if hasAM && values[0] == 12 { values[0] = 0 }
        if hasPM && values[0] < 12 { values[0] += 12 }
        switch values.count {
        case 1:     self.init(hour: values[0])
        case 2:     self.init(hour: values[0], minute: values[1])
        case 3:     self.init(hour: values[0], minute: values[1], second: values[2])
        case 4:
            let ns = Double("0.\(values[3])")?.second.nanoseconds
            self.init(hour: values[0], minute: values[1], second: values[2], nanosecond: Int(ns ?? 0))
        default:    return nil
        }
    }

    /// The interval between this time and zero o'clock.
    public var intervalSinceZeroClock: Interval {
        return hour.hours + minute.minutes + second.seconds + nanosecond.nanoseconds
    }

    /// Returns a dateComponenets of the time, using gregorian calender and
    /// current time zone.
    public func toDateComponents() -> DateComponents {
        return DateComponents(calendar: Calendar.gregorian,
                              timeZone: TimeZone.current,
                              hour: hour,
                              minute: minute,
                              second: second,
                              nanosecond: nanosecond)
    }
}

extension Time: CustomStringConvertible {

    /// A textual representation of this time.
    public var description: String {
        let h = "\(hour)".padding(toLength: 2, withPad: "0", startingAt: 0)
        let m = "\(minute)".padding(toLength: 2, withPad: "0", startingAt: 0)
        let s = "\(second)".padding(toLength: 2, withPad: "0", startingAt: 0)
        let ns = "\(nanosecond / 1_000_000)".padding(toLength: 3, withPad: "0", startingAt: 0)
        return "Time: \(h):\(m):\(s).\(ns)"
    }
}

extension Time: CustomDebugStringConvertible {

    /// A textual representation of this time for debugging.
    public var debugDescription: String {
        return description
    }
}
