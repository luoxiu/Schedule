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

    static var standard: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}

extension Date {

    var start: Date {
        return Calendar.standard.startOfDay(for: self)
    }
}

extension NSLock {

    @inline(__always)
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
