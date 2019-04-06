import Foundation

/// An atomic box that can read and write the underlying value atomically.
final class Atomic<T> {

    private var val: T
    private let lock = NSLock()

    /// Create an atomic box with the given initial value.
    @inline(__always)
    init(_ value: T) {
        self.val = value
    }

    /// Reads the current value atomically.
    @inline(__always)
    func read<U>(_ body: (T) -> U) -> U {
        return lock.withLock { body(val) }
    }

    /// Reads the current value atomically.
    @inline(__always)
    func readVoid(_ body: (T) -> Void) {
        lock.withLockVoid { body(val) }
    }

    /// Writes the current value atomically.
    @inline(__always)
    func write<U>(_ body: (inout T) -> U) -> U {
        return lock.withLock { body(&val) }
    }

    /// Writes the current value atomically.
    @inline(__always)
    func writeVoid(_ body: (inout T) -> Void) {
        lock.withLockVoid { body(&val) }
    }
}
