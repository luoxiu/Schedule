import Foundation

/// Represents a box that can read and write the underlying value atomically.
final class Atomic<T> {

    private var v: T
    private let lock = NSLock()

    /// Init with the underlying value.
    init(_ value: T) {
        self.v = value
    }

    /// Creates a snapshot of the value nonatomically.
    @inline(__always)
    func snapshot() -> T {
        return v
    }

    /// Reads the value atomically.
    @inline(__always)
    func read<U>(_ body: (T) -> U) -> U {
        return lock.withLock { body(v) }
    }

    /// Writes the value atomically.
    @inline(__always)
    func write<U>(_ body: (inout T) -> U) -> U {
        return lock.withLock { body(&v) }
    }
}
