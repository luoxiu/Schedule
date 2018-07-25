//
//  WeakSet.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import Foundation

struct WeakBox<T: AnyObject>  {
    weak var underlying: T?
    init(_ value: T) {
        self.underlying = value
    }
}

extension WeakBox: Hashable {
    
    var hashValue: Int {
        guard let value = self.underlying else { return 0 }
        return ObjectIdentifier(value).hashValue
    }
    
    static func == (lhs: WeakBox<T>, rhs: WeakBox<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

struct WeakSet<T: AnyObject> {
    
    private var set = Set<WeakBox<T>>()
    
    mutating func add(_ object: T) {
        self.set.insert(WeakBox(object))
    }
    
    @discardableResult
    mutating func remove(_ object: T) -> T? {
        return self.set.remove(WeakBox(object))?.underlying
    }
    
    func contains(_ object: T) -> Bool {
        return set.contains(WeakBox(object))
    }
    
    var objects: [T] {
        return self.set.map { $0.underlying }.compactMap { $0 }
    }
    
    var count: Int {
        return self.objects.count
    }
}

extension WeakSet: Sequence {
    
    func makeIterator() -> AnyIterator<T> {
        return AnyIterator(objects.makeIterator())
    }
}
