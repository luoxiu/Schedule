//
//  WeakSet.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import Foundation

private struct WeakBox<T: AnyObject> {
    weak var ref: T?
    init(_ ref: T) {
        self.ref = ref
    }
}

extension WeakBox: Hashable {

    var hashValue: Int {
        guard let value = ref else { return 0 }
        return ObjectIdentifier(value).hashValue
    }

    static func == (lhs: WeakBox<T>, rhs: WeakBox<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

/// An alternative to `NSHashTable`, since `NSHashTable` is unavailable on linux.
struct WeakSet<T: AnyObject> {

    private var set = Set<WeakBox<T>>()

    mutating func insert(_ object: T) {
        set.insert(WeakBox(object))
    }

    @discardableResult
    mutating func remove(_ object: T) -> T? {
        return set.remove(WeakBox(object))?.ref
    }

    func contains(_ object: T) -> Bool {
        return set.contains(WeakBox(object))
    }

    var objects: [T] {
        return set.map { $0.ref }.compactMap { $0 }
    }

    var count: Int {
        return objects.count
    }
}

extension WeakSet: Sequence {

    func makeIterator() -> AnyIterator<T> {
        return AnyIterator(objects.makeIterator())
    }
}
