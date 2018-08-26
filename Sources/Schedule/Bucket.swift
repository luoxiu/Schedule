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
        return lhs.rawValue == rhs.rawValue
    }

    func next() -> BucketKey {
        return BucketKey(rawValue: rawValue &+ 1)
    }
}

struct Bucket<Element> {

    private var nextKey = BucketKey(rawValue: 0)

    private typealias Entry = (key: BucketKey, element: Element)
    private var entries: [Entry] = []

    @discardableResult
    mutating func append(_ new: Element) -> BucketKey {
        defer { nextKey = nextKey.next() }

        entries.append((key: nextKey, element: new))
        return nextKey
    }

    func element(for key: BucketKey) -> Element? {
        for entry in entries where entry.key == key {
            return entry.element
        }
        return nil
    }

    @discardableResult
    mutating func removeElement(for key: BucketKey) -> Element? {
        for (idx, entry) in entries.enumerated() where entry.key == key {
            entries.remove(at: idx)
            return entry.element
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
        var it = entries.makeIterator()
        return AnyIterator {
            return it.next()?.element
        }
    }
}
