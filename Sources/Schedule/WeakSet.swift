//
//  WeakSet.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import Foundation

private struct WeakBox<T: AnyObject> {
    weak var object: T?
    init(_ object: T?) {
        self.object = object
    }
}

extension WeakBox: Hashable {

    var hashValue: Int {
        guard let object = object else { return 0 }
        return ObjectIdentifier(object).hashValue
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
        return set.remove(WeakBox(object))?.object
    }

    func contains(_ object: T) -> Bool {
        return set.contains(WeakBox(object))
    }

    func containsNil() -> Bool {
        return set.contains(where: { $0.object == nil })
    }

    mutating func purify() {
        set = set.filter({ $0.object != nil })
    }

    var objects: [T] {
        return set.compactMap({ $0.object })
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
