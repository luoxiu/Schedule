import Foundation

struct BucketKey {

    let underlying: UInt64

    init(_ underlying: UInt64) {
        self.underlying = underlying
    }

    func next() -> BucketKey {
        return BucketKey(underlying &+ 1)
    }
}

struct Bucket<Element> {

    private typealias Entry = (key: BucketKey, element: Element)

    private var key = BucketKey(0)
    private var entry: Entry?
    private var entries: [Entry]?

    @discardableResult
    mutating func append(_ new: Element) -> BucketKey {
        defer { key = key.next() }
        let entry = (key: key, element: new)

        if self.entry == nil {
            self.entry = entry
            return key
        }

        if entries == nil {
            entries = [entry]
        } else {
            entries!.append(entry)
        }

        return key
    }

    func element(for key: BucketKey) -> Element? {
        if entry?.key == key {
            return entry?.element
        }

        if entries == nil {
            return nil
        }

        for entry in entries! where entry.key == key {
            return entry.element
        }
        return nil
    }

    @discardableResult
    mutating func removeElement(for key: BucketKey) -> Element? {
        if entry?.key == key {
            defer { entry = nil }
            return entry?.element
        }

        if entries == nil {
            return nil
        }

        for (idx, entry) in entries!.enumerated() where entry.key == key {
            entries!.remove(at: idx)
            return entry.element
        }

        return nil
    }

    mutating func removeAll() {
        entry = nil
        entries = nil
    }

    var count: Int {
        return (entry == nil ? 0 : 1) + (entries?.count ?? 0)
    }
}

extension Bucket: Sequence {

    func makeIterator() -> AnyIterator<Element> {
        var bucket = self
        var iterator = bucket.entries?.makeIterator()
        return AnyIterator {
            if bucket.entry != nil {
                return bucket.removeElement(for: bucket.entry!.key)
            }
            return iterator?.next()?.element
        }
    }
}

extension BucketKey: Equatable {

    static func == (lhs: BucketKey, rhs: BucketKey) -> Bool {
        return lhs.underlying == rhs.underlying
    }
}
