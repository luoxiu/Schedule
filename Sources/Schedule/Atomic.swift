import Foundation

final class Atomic<T> {

    private var value: T
    private let lock = Lock()

    init(_ value: T) {
        self.value = value
    }

    @inline(__always)
    func read<U>(_ body: (T) -> U) -> U {
        return lock.withLock { body(value) }
    }

    @inline(__always)
    func write<U>(_ body: (inout T) -> U) -> U {
        return lock.withLock { body(&value) }
    }
}
