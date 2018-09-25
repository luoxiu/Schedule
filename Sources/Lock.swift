import Foundation

final class Lock {

    private let mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)

    init() {
        let err = pthread_mutex_init(mutex, nil)
        precondition(err == 0)
    }

    deinit {
        let err = pthread_mutex_destroy(mutex)
        precondition(err == 0)
        mutex.deallocate()
    }

    func lock() {
        let err = pthread_mutex_lock(mutex)
        precondition(err == 0)
    }

    func unlock() {
        let err = pthread_mutex_unlock(mutex)
        precondition(err == 0)
    }
}

extension Lock {

    @inline(__always)
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
