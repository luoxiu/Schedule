import Foundation

extension Double {

    func clampedToInt() -> Int {
        if self >= Double(Int.max) { return Int.max }
        if self <= Double(Int.min) { return Int.min }
        return Int(self)
    }
}

extension Int {

    func clampedAdding(_ other: Int) -> Int {
        return (Double(self) + Double(other)).clampedToInt()
    }

    func clampedSubtracting(_ other: Int) -> Int {
        return clampedAdding(-other)
    }
}

extension Calendar {

    static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}

extension Date {

    func zeroToday() -> Date {
        let calendar = Calendar.gregorian
        let timeZone = TimeZone.current
        var dateComponents = calendar.dateComponents(in: timeZone, from: self)
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        dateComponents.nanosecond = 0
        return calendar.date(from: dateComponents)!
    }
}
