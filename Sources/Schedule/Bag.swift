import Foundation

/// A unique key for removing an element from a bag.
struct BagKey: Equatable {

    fileprivate let i: UInt64

    fileprivate init(underlying: UInt64) {
        self.i = underlying
    }

    /// Returns a Boolean value indicating whether two BagKeys are equal.
    static func == (lhs: BagKey, rhs: BagKey) -> Bool {
        return lhs.i == rhs.i
    }
}

/// A generator that can generate a sequence of unique `BagKey`.
///
///     let k1 = gen.next()
///     let k2 = gen.next()
///     ...
struct BagKeyGenerator: Sequence, IteratorProtocol {

    typealias Element = BagKey

    private var k = BagKey(underlying: 0)

    /// Advances to the next key and returns it, or nil if no next key exists.
    mutating func next() -> BagKey? {
        if k.i == UInt64.max {
            return nil
        }
        defer { k = BagKey(underlying: k.i + 1) }
        return k
    }
}

/// An ordered sequence.
///
///     let k1 = bag.append(e1)
///     let k2 = bag.append(e2)
///
///     for e in bag {
///         // -> e1
///         // -> e2
///     }
///
///     bag.removeValue(for: k1)
struct Bag<Element> {

    private typealias Entry = (key: BagKey, val: Element)

    private var keyGen = BagKeyGenerator()
    private var entries: [Entry] = []

    /// Appends a new element at the end of this bag.
    @discardableResult
    mutating func append(_ new: Element) -> BagKey {
        let key = keyGen.next()!

        let entry = (key: key, val: new)
        entries.append(entry)

        return key
    }

    /// Returns the element associated with a given key.
    func value(for key: BagKey) -> Element? {
        if let entry = entries.first(where: { $0.key == key }) {
            return entry.val
        }
        return nil
    }

    /// Removes the given key and its associated element from this bag.
    @discardableResult
    mutating func removeValue(for key: BagKey) -> Element? {
        if let i = entries.firstIndex(where: { $0.key == key }) {
            return entries.remove(at: i).val
        }
        return nil
    }

    /// Removes all elements from this bag.
    mutating func removeAll() {
        entries.removeAll()
    }

    /// The number of elements in this bag.
    var count: Int {
        return entries.count
    }
}

extension Bag: Sequence {

    /// Returns an iterator over the elements of this bag.
    @inline(__always)
    func makeIterator() -> AnyIterator<Element> {
        var iterator = entries.makeIterator()
        return AnyIterator<Element> {
            return iterator.next()?.val
        }
    }
}
