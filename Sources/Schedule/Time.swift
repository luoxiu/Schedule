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

    /// Initializes a time with `hour`, `minute`, `second` and `nanosecond`.
    ///
    ///     Time(hour: 11, minute: 11)  => "11:11:00.000"
    ///     Time(hour: 25)              => nil
    ///     Time(hour: 1, minute: 61)   => nil
    public init?(hour: Int, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) {
        guard
            (0..<24).contains(hour),
            (0..<60).contains(minute),
            (0..<60).contains(second),
            (0..<Int(1.second.nanoseconds)).contains(nanosecond)
        else { return nil }

        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }

    /// Initializes a time with a string.
    ///
    ///     Time("11") -> Time(hour: 11)
    ///     Time("11:12") -> Time(hour: 11, minute: 12)
    ///     Time("11:12:13") -> Time(hour: 11, minute: 12, second: 13)
    ///     Time("11:12:13.123") -> Time(hour: 11, minute: 12, second: 13, nanosecond: 123000000)
    ///
    ///     Time("-1.0") == nil
    ///
    ///     Time("11 pm") == Time(hour: 23)
    ///     Time("11:12:13 PM") == Time(hour: 23, minute: 12, second: 13)
    public init?(_ string: String) {
        let pattern = "^(\\d{1,2})(:(\\d{1,2})(:(\\d{1,2})(.(\\d{1,3}))?)?)?( (am|AM|pm|PM))?$"

        // swiftlint:disable force_try
        let regexp = try! NSRegularExpression(pattern: pattern, options: [])
        let nsString = NSString(string: string)
        guard let matches = regexp.matches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: nsString.length)).first
        else {
            return nil
        }

        var hasAM = false
        var hasPM = false
        var values: [Int] = []
        values.reserveCapacity(matches.numberOfRanges)

        for i in 0..<matches.numberOfRanges {
            let range = matches.range(at: i)
            if range.length == 0 { continue }
            let captured = nsString.substring(with: range)
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

    /// The interval between this time and start of today
    public var intervalSinceStartOfDay: Interval {
        return hour.hours + minute.minutes + second.seconds + nanosecond.nanoseconds
    }

    /// Returns a dateComponenets of the time, using gregorian calender and
    /// current time zone.
    public func asDateComponents(_ timeZone: TimeZone = .current) -> DateComponents {
        return DateComponents(calendar: Calendar.gregorian,
                              timeZone: timeZone,
                              hour: hour,
                              minute: minute,
                              second: second,
                              nanosecond: nanosecond)
    }
}

extension Time: CustomStringConvertible {

    /// A textual representation of this time.
    ///
    /// "Time: 11:11:11.111"
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
    ///
    /// "Time: 11:11:11.111"
    public var debugDescription: String {
        return description
    }
}
