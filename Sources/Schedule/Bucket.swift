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

    static func == (lhs: BucketKey, rhs: BucketKey) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

struct Bucket<Element> {

    private var nextKey = BucketKey(rawValue: 0)

    typealias Entry = (key: BucketKey, element: Element)
    private var entries: [Entry] = []

    @discardableResult
    mutating func add(_ new: Element) -> BucketKey {
        let key = nextKey
        nextKey = BucketKey(rawValue: nextKey.rawValue &+ 1)
        entries.append((key: key, element: new))
        return key
    }

    func element(for key: BucketKey) -> Element? {
        for entry in entries where entry.key == key {
            return entry.element
        }
        return nil
    }

    @discardableResult
    mutating func removeElement(for key: BucketKey) -> Element? {
        for i in 0..<entries.count where entries[i].key == key {
            let element = entries[i].element
            entries.remove(at: i)
            return element
        }
        return nil
    }

    mutating func removeAll() {
        entries.removeAll()
    }

    var count: Int {
        return entries.count
    }
}

extension Bucket: Sequence {

    func makeIterator() -> AnyIterator<Element> {
        return AnyIterator(entries.map({ $0.element }).makeIterator())
    }
}
