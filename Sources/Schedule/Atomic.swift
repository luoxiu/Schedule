import Foundation

final class Atomic<T> {

    private var _value: T
    private let _lock = NSLock()

    init(_ value: T) {
        self._value = value
    }

    @inline(__always)
    func read<U>(_ body: (T) -> U) -> U {
        return _lock.withLock { body(_value) }
    }

    @inline(__always)
    func write<U>(_ body: (inout T) -> U) -> U {
        return _lock.withLock { body(&_value) }
    }
}
