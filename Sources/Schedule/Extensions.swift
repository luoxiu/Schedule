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

    /// The gregorian calendar with `en_US_POSIX` locale.
    static let gregorian: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        return cal
    }()
}

extension Date {

    /// Zero o'clock in the morning.
    var startOfToday: Date {
        return Calendar.gregorian.startOfDay(for: self)
    }
}

extension NSLocking {

    /// Executes a closure returning a value while acquiring the lock.
    @inline(__always)
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try body()
    }

    /// Executes a closure returning a value while acquiring the lock.
    @inline(__always)
    func withLock(_ body: () throws -> Void) rethrows {
        lock(); defer { unlock() }
        try body()
    }
}
