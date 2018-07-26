//
//  Atomic.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/26.
//

import Foundation

class Atomic<T> {

    private var value: T
    private var lock = Lock()

    init(_ value: T) {
        self.value = value
    }

    func execute(_ body: (T) -> Void) {
        lock.withLock { body(value) }
    }

    func mutate(_ body: (inout T) -> Void) {
        lock.withLock { body(&value) }
    }

    func read() -> T {
        return lock.withLock { value }
    }

    func write(_ new: T) {
        lock.withLock { value = new }
    }
}
