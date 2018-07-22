//
//  Bucket.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/22.
//

import Foundation

struct BucketKey: Hashable, RawRepresentable {
    
    let rawValue: UInt64
    
    var hashValue: Int {
        return rawValue.hashValue
    }
    
    static func ==(lhs: BucketKey, rhs: BucketKey) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

struct Bucket<Element> {
    
    private var nextKey = BucketKey(rawValue: 0)
    
    private var elements: [BucketKey: Element] = [:]
    
    @discardableResult
    mutating func put(_ element: Element) -> BucketKey {
        let key = nextKey
        nextKey = BucketKey(rawValue: nextKey.rawValue &+ 1)
        elements[key] = element
        return key
    }
    
    @discardableResult
    mutating func delete(_ key: BucketKey) -> Element? {
        return elements.removeValue(forKey: key)
    }
    
    mutating func clear() {
        elements.removeAll()
    }
    
    static var empty: Bucket {
        return Bucket()
    }
}

extension Bucket: Sequence {
    
    func makeIterator() -> AnyIterator<Element> {
        var iterator = elements.makeIterator()
        return AnyIterator {
            iterator.next()?.value
        }
    }
}
