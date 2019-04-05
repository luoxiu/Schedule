import Foundation

extension Double {

    /// Returns a value of this number clamped to `Int.min...Int.max`.
    func clampedToInt() -> Int {
        if self >= Double(Int.max) { return Int.max }
        if self <= Double(Int.min) { return Int.min }
        return Int(self)
    }
}

extension Int {

    /// Returns the sum of the two given values, in case of any overflow,
    /// the result will be clamped to int.
    func clampedAdding(_ other: Int) -> Int {
        return (Double(self) + Double(other)).clampedToInt()
    }
}

extension Locale {

    static let posix = Locale(identifier: "en_US_POSIX")
}

extension Calendar {

    /// The gregorian calendar with `en_US_POSIX` locale.
    static let gregorian: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.posix
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

    /// Executes a closure while acquiring the lock.
    @inline(__always)
    func withLockVoid(_ body: () throws -> Void) rethrows {
        lock(); defer { unlock() }
        try body()
    }
}
